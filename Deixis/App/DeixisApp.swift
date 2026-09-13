import AppKit

/// LSUIElement app: no Dock icon, no windows. A status item (R10) and the capture session.
@main
@MainActor
final class DeixisApp: NSObject, NSApplicationDelegate {
    private static var delegate: DeixisApp?

    private let state = AppState()
    private var statusItem: NSStatusItem?

    static func main() {
        let app = NSApplication.shared
        let delegate = DeixisApp()
        Self.delegate = delegate
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = makeStatusItem()
        requestPermissionsIfNeeded()
        state.start()
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
        let capture = NSMenuItem(title: "Capture (⌃⌃)", action: #selector(captureFromMenu), keyEquivalent: "")
        capture.target = self
        menu.addItem(capture)
        let folder = NSMenuItem(title: "Open capture folder", action: #selector(openFolder), keyEquivalent: "")
        folder.target = self
        menu.addItem(folder)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Deixis", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        return item
    }

    @objc private func captureFromMenu() {
        state.beginCapture()
    }

    @objc private func openFolder() {
        state.openCaptureFolder()
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
