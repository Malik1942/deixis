import AppKit
import SwiftUI

/// LSUIElement app: no Dock icon, no document windows. The only scene is Settings (v0.3 R19);
/// the delegate keeps the status item (R10), the permission alerts, and `AppState`.
@main
struct DeixisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(delegate.state)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var statusItem: NSStatusItem?
    private var captureItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = makeStatusItem()
        requestPermissionsIfNeeded()
        state.start()
        state.preferences.onHotkeyChange = { [weak self] in self?.refreshCaptureTitle() }
        refreshCaptureTitle()
    }

    // MARK: Menu bar

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "Deixis") {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            item.button?.image = image
        }

        let menu = NSMenu()
        let capture = NSMenuItem(title: "Capture", action: #selector(captureFromMenu), keyEquivalent: "")
        capture.target = self
        menu.addItem(capture)
        captureItem = capture
        let folder = NSMenuItem(title: "Open capture folder", action: #selector(openFolder), keyEquivalent: "")
        folder.target = self
        menu.addItem(folder)
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Deixis", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        return item
    }

    private func refreshCaptureTitle() {
        captureItem?.title = "Capture (\(state.preferences.hotkeyModifier.symbol))"
    }

    @objc private func captureFromMenu() {
        state.beginCapture()
    }

    @objc private func openFolder() {
        state.openCaptureFolder()
    }

    @objc private func openSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
