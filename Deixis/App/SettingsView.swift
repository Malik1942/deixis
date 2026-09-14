import AppKit
import SwiftUI

/// v0.3 R19: the one place Deixis is a window. PRD §6.3 "Settings": grouped forms, system
/// controls at default sizes, footnotes under rows, nothing custom.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            MyAppsSettings()
                .tabItem { Label("My Apps", systemImage: "app.badge.checkmark") }
        }
        .frame(width: 520)
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

struct GeneralSettings: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var preferences = state.preferences
        Form {
            Section {
                LabeledContent("Hotkey") {
                    HotkeyRecorder(
                        hotkey: Binding(get: { preferences.hotkey }, set: { preferences.hotkey = $0 ?? .default }),
                        fallback: .default,
                        onBegin: { state.pauseHotkey() }, onEnd: { state.resumeHotkey() }
                    )
                }
                Footnote(text: "Press a key with modifiers, or double-tap one modifier. Double-tap Command is used by Codex; double-tap Option by Claude Desktop.")
            }
            Section {
                ForEach(Preferences.hotkeyActions, id: \.self) { action in
                    LabeledContent(action.capitalized) {
                        HotkeyRecorder(
                            hotkey: Binding(get: { preferences.actionHotkeys[action] }, set: { preferences.actionHotkeys[action] = $0 }),
                            onBegin: { state.pauseHotkey() }, onEnd: { state.resumeHotkey() }
                        )
                    }
                }
                Footnote(text: "Snap, Text, Color, and Cut are also on the ball: press and hold it. Hotkeys are optional.")
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
                Toggle("Floating ball", isOn: $preferences.ballEnabled)
                    .toggleStyle(.switch)
                Footnote(text: "A quiet disc that wakes when you approach. Click it to point. The hotkey works either way.")
            }
        }
        .formStyle(.grouped)
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
    /// What "Default" restores; nil means the action can be left unassigned ("Clear").
    var fallback: Hotkey? = nil
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
        HStack(spacing: 8) {
            Button(recording ? (hint ?? "Press keys…") : (hotkey?.title ?? "None")) {
                recording ? stop() : begin()
            }
            .frame(minWidth: 180)
            if !recording {
                if let fallback, hotkey != fallback {
                    Button("Default") { hotkey = fallback }
                } else if fallback == nil, hotkey != nil {
                    Button("Clear") { hotkey = nil }
                }
            }
        }
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
            hotkey = .chord(keyCode: keyCode, modifiers: modifiers, key: name)
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
                hotkey = .doubleTap(single)
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
        Form {
            Section {
                List(preferences.myApps, id: \.self, selection: $selection) { bundleId in
                    Text(bundleId)
                }
                .frame(minHeight: 160)
                HStack(spacing: 8) {
                    Button { addFromPanel(preferences) } label: { Image(systemName: "plus") }
                    Button { remove(preferences) } label: { Image(systemName: "minus") }
                        .disabled(selection == nil)
                    Spacer()
                    TextField("Bundle id", text: $typed)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .onSubmit { addTyped(preferences) }
                    Button("Add") { addTyped(preferences) }
                        .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Footnote(text: "Deixis already treats apps you build (Simulator, Xcode builds, your signing identity) as yours. Add anything it misses.")
            }
        }
        .formStyle(.grouped)
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
