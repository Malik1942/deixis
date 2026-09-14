import AppKit
import SwiftUI

/// LSUIElement app: no Dock icon, no document windows. Two scenes: the menu bar item (R10, a
/// standard menu rendered by `MenuBarExtra`) and Settings (v0.3 R19). The delegate keeps the
/// permission alerts and `AppState`.
@main
struct DeixisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            StatusMenu()
                .environment(delegate.state)
        } label: {
            Image(systemName: "hand.point.up.left")
                .accessibilityLabel("Deixis")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(delegate.state)
        }
        .windowResizability(.contentSize)
    }
}

/// R10: Capture, Open capture folder, Settings…, Quit. Nothing else.
private struct StatusMenu: View {
    @Environment(AppState.self) private var state
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(captureTitle) {
            state.beginCapture()
        }
        Button("Capture after") { state.captureAfter() }
        Button("Show before & after") { state.showBeforeAfter() }
        Divider()
        Button(title("Snap", "snap")) { state.beginAction(.snap) }
        Button(title("Text", "text")) { state.beginAction(.text) }
        Button(title("Color", "color")) { state.beginColorPick() }
        Button(title("Cut", "cut")) { state.beginAction(.cut) }
        Divider()
        Button("Pin last capture") { state.pinLastCapture() }
        Button("Open capture folder") {
            state.openCaptureFolder()
        }
        Button("Settings…") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Deixis") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    /// "Capture (⌃⌃ or ⌃⌥1)": the capture hotkey and, when Point has one, its action hotkey.
    private var captureTitle: String {
        var keys = [state.preferences.hotkey.symbol]
        if let point = state.preferences.actionHotkeys["point"]?.symbol { keys.append(point) }
        return "Capture (\(keys.joined(separator: " or ")))"
    }

    /// "Snap (⌃⌥2)"; just the name when the action has no hotkey.
    private func title(_ name: String, _ action: String) -> String {
        guard let symbol = state.preferences.actionHotkeys[action]?.symbol else { return name }
        return "\(name) (\(symbol))"
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestPermissionsIfNeeded()
        state.start()
    }

    // MARK: Permissions

    /// PRD permissions spec: one plain sentence before each system prompt.
    private func requestPermissionsIfNeeded() {
        if !AccessibilityReader.isTrusted(prompt: false) {
            explain("Deixis reads what is under your cursor through Accessibility. Nothing leaves the machine.")
            _ = AccessibilityReader.isTrusted(prompt: true)
        }
        if !ScreenCapture.hasPermission() {
            explain("Deixis captures the element through Screen Recording. Nothing leaves the machine.")
            ScreenCapture.requestPermission()
        }
    }

    private func explain(_ sentence: String) {
        let alert = NSAlert()
        alert.messageText = "Deixis"
        alert.informativeText = sentence
        alert.addButton(withTitle: "Continue")
        NSApp.activate()
        alert.runModal()
    }
}
