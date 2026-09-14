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
                Picker("Hotkey", selection: $preferences.hotkeyModifier) {
                    ForEach(HotkeyModifier.allCases, id: \.self) { modifier in
                        Text(modifier.title).tag(modifier)
                    }
                }
                .pickerStyle(.menu)
                Footnote(text: "Double-tap Command is used by Codex; double-tap Option by Claude Desktop.")
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
                Footnote(text: "Each capture writes a PNG and a JSON sidecar here.")
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
