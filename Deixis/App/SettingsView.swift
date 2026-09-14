import AppKit
import SwiftUI

/// v0.3 R19: the one place Deixis is a window. PRD §6.3 "Settings": grouped forms, system
/// controls at default sizes, footnotes under rows, nothing custom. Resizable from 480×360;
/// the forms reflow with the width and the My Apps list takes the height.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            MyAppsSettings()
                .tabItem { Label("My Apps", systemImage: "app.badge.checkmark") }
        }
        .frame(minWidth: 480, idealWidth: 520, maxWidth: .infinity, minHeight: 360, idealHeight: 560, maxHeight: .infinity)
        .background(SettingsWindowConfigurator())
    }
}

/// The `Settings` scene builds its window without a minimize button. This reaches the window
/// once the view is in it and adds one; the scene itself remembers the frame.
private struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguratorView { ConfiguratorView() }
    func updateNSView(_ view: ConfiguratorView, context: Context) {}

    final class ConfiguratorView: NSView {
        private var configured: NSWindow?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, window !== configured else { return }
            configured = window
            window.styleMask.insert([.miniaturizable, .resizable])
        }
    }
}

private struct Footnote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

/// A permission as System Settings would show it: the state at a glance, and a way to grant it when missing.
private struct PermissionRow: View {
    let title: String
    let detail: String
    let granted: Bool
    let grant: () -> Void

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(granted ? .green : .orange)
                Text(granted ? "Granted" : "Not granted")
                    .foregroundStyle(.secondary)
                if !granted {
                    Button("Grant…", action: grant)
                }
            }
        } label: {
            Text(title)
            Text(detail)
        }
    }
}

/// Under a hotkey row: the system's warning triangle and what clashes. Never blocks.
private struct ConflictNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

struct GeneralSettings: View {
    @Environment(AppState.self) private var state
    /// R29: a warning under each hotkey row, by action name ("capture" for the capture hotkey).
    @State private var conflicts: [String: String] = [:]
    /// The two grants Deixis needs, re-read while the window is open so a change in System Settings shows at once.
    @State private var accessibilityGranted = AccessibilityReader.isTrusted(prompt: false)
    @State private var screenRecordingGranted = ScreenCapture.hasPermission()

    var body: some View {
        @Bindable var preferences = state.preferences
        Form {
            Section {
                PermissionRow(
                    title: "Accessibility",
                    detail: "Reads what is under your cursor and listens for the hotkey.",
                    granted: accessibilityGranted
                ) {
                    _ = AccessibilityReader.isTrusted(prompt: true)
                    openPrivacyPane("Privacy_Accessibility")
                }
                PermissionRow(
                    title: "Screen Recording",
                    detail: "Captures the pixels of the element.",
                    granted: screenRecordingGranted
                ) {
                    _ = ScreenCapture.requestPermission()
                    openPrivacyPane("Privacy_ScreenCapture")
                }
                if !accessibilityGranted || !screenRecordingGranted {
                    Footnote(text: "macOS ties each grant to the app's signature. After an update, or if a switch is on but Deixis still cannot capture, remove Deixis from the list and add /Applications/Deixis.app again.")
                }
            }
            Section {
                // System Settings row: title and description in the label, the control trailing.
                LabeledContent {
                    HotkeyRecorder(
                        hotkey: Binding(get: { preferences.hotkey }, set: { preferences.hotkey = $0 ?? .default }),
                        fallback: .default,
                        rejects: { rejection(for: $0, action: "capture") },
                        onBegin: { state.pauseHotkey() }, onEnd: { state.resumeHotkey() }
                    )
                } label: {
                    Text("Capture hotkey")
                    Text("Press a key with modifiers, or double-tap one modifier. Double-tap Command is used by Codex; double-tap Option by Claude Desktop.")
                    if let warning = conflicts["capture"] { ConflictNote(text: warning) }
                }
                Toggle(isOn: $preferences.adjustSelection) {
                    Text("Adjust selection before capturing")
                    Text("After you drag a region for Snap, Text, or Cut, handles let you fine-tune it. Press Return to capture, Esc to cancel.")
                }
                .toggleStyle(.switch)
            }
            Section {
                ForEach(Preferences.hotkeyActions, id: \.self) { action in
                    LabeledContent {
                        HotkeyRecorder(
                            hotkey: Binding(get: { preferences.actionHotkeys[action] }, set: { preferences.setActionHotkey($0, for: action) }),
                            fallback: Preferences.defaultActionHotkey(action),
                            clearable: true,
                            rejects: { rejection(for: $0, action: action) },
                            onBegin: { state.pauseHotkey() }, onEnd: { state.resumeHotkey() }
                        )
                    } label: {
                        Text(action.capitalized)
                        if let warning = conflicts[action] { ConflictNote(text: warning) }
                    }
                }
                Footnote(text: "Control-Option and the action's number, in menu order; the ring shows each number. Point also answers to the capture hotkey above. Snap, Text, Color, and Cut are on the ball too: press and hold it.")
            }
            Section {
                LabeledContent("Capture folder") {
                    HStack {
                        TextField("", text: .constant(preferences.captureFolder))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        Button("Choose…") { chooseFolder(preferences) }
                    }
                }
                Picker("Organize captures", selection: $preferences.organization) {
                    ForEach(CaptureOrganization.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
                Picker("Keep images", selection: $preferences.retentionDays) {
                    ForEach(Preferences.retentionChoices, id: \.self) { days in
                        Text(days == 0 ? "Forever" : "\(days) days").tag(days)
                    }
                }
                .pickerStyle(.menu)
                Footnote(text: "Each capture writes a PNG and a JSON sidecar here. Finder tags are always added: Deixis, the app, fix or reference, and the project when known. Older images go to the Trash; pinned and resolved captures stay.")
            }
            Section {
                Picker("Color format", selection: $preferences.colorFormat) {
                    ForEach(ColorFormat.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("Color space", selection: $preferences.colorSpace) {
                    ForEach(ColorSpaceChoice.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                Footnote(text: "The Color action copies the pixel under the cursor in this format.")
            }
            Section {
                Toggle(isOn: $preferences.ballEnabled) {
                    Text("Floating ball")
                    Text("A quiet disc that wakes when you approach. Click it to point, hold for the ring. The hotkey works either way.")
                }
                .toggleStyle(.switch)
                Toggle(isOn: $preferences.ballAutoHide) {
                    Text("Auto-hide")
                    Text("After 2 seconds without use, the ball tucks into the nearest screen edge with part of it showing. Move toward it to bring it back.")
                }
                .toggleStyle(.switch)
                .disabled(!preferences.ballEnabled)
            }
        }
        .formStyle(.grouped)
        .task { refreshConflicts() }
        .task {
            while !Task.isCancelled {
                refreshPermissions()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onChange(of: preferences.hotkey) { refreshConflicts() }
        .onChange(of: preferences.actionHotkeys) { refreshConflicts() }
    }

    private func refreshPermissions() {
        accessibilityGranted = AccessibilityReader.isTrusted(prompt: false)
        screenRecordingGranted = ScreenCapture.hasPermission()
    }

    private func openPrivacyPane(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }

    /// The clash inside Deixis that the recorder refuses; a clash with macOS is only shown afterwards.
    private func rejection(for hotkey: Hotkey, action: String) -> String? {
        state.preferences.action(using: hotkey, excluding: action).map { HotkeyConflict.deixis(action: $0).message }
    }

    private func refreshConflicts() {
        let preferences = state.preferences
        var found: [String: String] = [:]
        found["capture"] = HotkeyConflicts.check(preferences.hotkey, for: "capture", in: preferences).first?.message
        for action in Preferences.hotkeyActions {
            guard let hotkey = preferences.actionHotkeys[action] else { continue }
            found[action] = HotkeyConflicts.check(hotkey, for: action, in: preferences).first?.message
        }
        conflicts = found
    }

    private func chooseFolder(_ preferences: Preferences) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = preferences.captureFolderURL
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            preferences.captureFolder = url.path(percentEncoded: false)
        }
    }
}

/// Records the next key press or modifier double-tap as the hotkey. Esc cancels.
struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey?
    /// What "Reset" restores.
    var fallback: Hotkey? = nil
    /// Whether the action may be left without a hotkey ("Clear"); implied when there is no fallback.
    var clearable = false
    /// A reason to refuse what was just pressed (shown in the button, recording goes on), or nil to take it.
    var rejects: (Hotkey) -> String? = { _ in nil }
    let onBegin: () -> Void
    let onEnd: () -> Void

    @State private var recording = false
    @State private var hint: String?
    @State private var monitor: Any?
    @State private var lastTap: (modifier: HotkeyModifier, time: TimeInterval)?
    @State private var modifiersWereDown = false

    private static let functionKeys: [UInt16: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
    ]
    private static let specialKeys: [UInt16: String] = [
        49: "Space", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦", 123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
    ]

    var body: some View {
        // The width sits on the label so the bordered button itself is the fixed-width control;
        // a frame on the button would leave invisible space around a short title.
        HStack(spacing: 8) {
            if !recording {
                if let fallback, hotkey != fallback {
                    Button("Reset") { hotkey = fallback }
                }
                if hotkey != nil, clearable || fallback == nil {
                    Button("Clear") { hotkey = nil }
                }
            }
            Button {
                recording ? stop() : begin()
            } label: {
                Text(recording ? (hint ?? "Press keys…") : (hotkey?.title ?? "None"))
                    .lineLimit(1)
                    .frame(minWidth: 150)
            }
        }
        .fixedSize()
    }

    private func begin() {
        onBegin()
        recording = true
        hint = nil
        lastTap = nil
        modifiersWereDown = false
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            let type = event.type, keyCode = event.keyCode, flags = event.modifierFlags
            let chars = event.type == .keyDown ? event.charactersIgnoringModifiers : nil
            let timestamp = event.timestamp
            MainActor.assumeIsolated { handle(type: type, keyCode: keyCode, flags: flags, characters: chars, timestamp: timestamp) }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = false
        hint = nil
        onEnd()
    }

    private func handle(type: NSEvent.EventType, keyCode: UInt16, flags: NSEvent.ModifierFlags, characters: String?, timestamp: TimeInterval) {
        switch type {
        case .keyDown:
            if keyCode == 53 { stop(); return } // Esc
            let modifiers = KeyModifiers(flags)
            let name: String
            if let fn = Self.functionKeys[keyCode] {
                name = fn
            } else if let special = Self.specialKeys[keyCode] {
                name = special
            } else {
                name = (characters ?? "").uppercased()
            }
            guard !name.isEmpty else { return }
            if modifiers.isEmpty, Self.functionKeys[keyCode] == nil {
                hint = "Add ⌘, ⌥, ⌃ or ⇧"
                return
            }
            let chord = Hotkey.chord(keyCode: keyCode, modifiers: modifiers, key: name)
            if let reason = rejects(chord) {
                hint = reason
                return
            }
            hotkey = chord
            stop()
        case .flagsChanged:
            let modifiers = KeyModifiers(flags)
            let down = !modifiers.isEmpty
            defer { modifiersWereDown = down }
            guard down, !modifiersWereDown else { return }
            let single: HotkeyModifier? = switch modifiers {
            case [.control]: .control
            case [.option]: .option
            case [.shift]: .shift
            case [.command]: keyCode == 54 ? .rightCommand : .command
            default: nil
            }
            guard let single else { lastTap = nil; return }
            if let last = lastTap, last.modifier == single, timestamp - last.time <= HotkeyMonitor.window {
                let tap = Hotkey.doubleTap(single)
                if let reason = rejects(tap) {
                    hint = reason
                    lastTap = nil
                    return
                }
                hotkey = tap
                stop()
            } else {
                lastTap = (single, timestamp)
                hint = "Again to double-tap \(single.glyph), or add a key"
            }
        default:
            break
        }
    }
}

struct MyAppsSettings: View {
    @Environment(AppState.self) private var state
    @State private var selection: String?
    @State private var typed = ""

    var body: some View {
        @Bindable var preferences = state.preferences
        // Not a Form: the list should take whatever height the window has.
        VStack(alignment: .leading, spacing: 8) {
            List(preferences.myApps, id: \.self, selection: $selection) { bundleId in
                Text(bundleId)
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                Button { addFromPanel(preferences) } label: { Image(systemName: "plus") }
                Button { remove(preferences) } label: { Image(systemName: "minus") }
                    .disabled(selection == nil)
                Spacer()
                TextField("Bundle id", text: $typed)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160, idealWidth: 220, maxWidth: 320)
                    .onSubmit { addTyped(preferences) }
                Button("Add") { addTyped(preferences) }
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Footnote(text: "Deixis already treats apps you build (Simulator, Xcode builds, your signing identity) as yours. Add anything it misses.")
        }
        .padding(20)
    }

    private func addFromPanel(_ preferences: Preferences) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(filePath: "/Applications")
        panel.prompt = "Add"
        if panel.runModal() == .OK, let url = panel.url, let id = Bundle(url: url)?.bundleIdentifier {
            append(id, to: preferences)
        }
    }

    private func addTyped(_ preferences: Preferences) {
        let id = typed.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        append(id, to: preferences)
        typed = ""
    }

    private func append(_ id: String, to preferences: Preferences) {
        guard !preferences.myApps.contains(id) else { return }
        preferences.myApps.append(id)
        selection = id
    }

    private func remove(_ preferences: Preferences) {
        guard let selection else { return }
        preferences.myApps.removeAll { $0 == selection }
        self.selection = nil
    }
}
