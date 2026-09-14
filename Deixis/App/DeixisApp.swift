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
        .windowResizability(.contentMinSize)
        .commands {
            // ⌘H in a UIElement app would hide every window, ball included, with no Dock icon to
            // bring them back. In Settings it puts the window away instead; Settings… reopens it.
            CommandGroup(replacing: .appVisibility) {
                Button("Hide Settings") { NSApp.keyWindow?.orderOut(nil) }
                    .keyboardShortcut("h")
            }
            // The generated Window menu's Minimize did nothing for the Settings window; these act
            // on the key window directly. The menu is invisible in a UIElement app; only the keys matter.
            CommandGroup(replacing: .windowSize) {
                Button("Minimize") { NSApp.keyWindow?.miniaturize(nil) }
                    .keyboardShortcut("m")
                Button("Zoom") { NSApp.keyWindow?.zoom(nil) }
            }
        }
    }
}

/// R10: Capture, Open capture folder, Settings…, Quit. Nothing else.
private struct StatusMenu: View {
    @Environment(AppState.self) private var state
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Capture (\(state.preferences.hotkey.symbol))") {
            state.beginCapture()
        }
        Button("Capture after") { state.captureAfter() }
        Button("Show before & after") { state.showBeforeAfter() }
        Divider()
        Button("Snap") { state.beginAction(.snap) }
        Button("Text") { state.beginAction(.text) }
        Button("Color") { state.beginColorPick() }
        Button("Cut") { state.beginAction(.cut) }
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
