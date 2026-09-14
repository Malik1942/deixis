import AppKit
import SwiftUI

/// v0.5 R43: the one page that shows the whole product at once. Opens once after the permission
/// alerts, and any time from Settings › General. A standard window in the
/// Settings idiom (grouped rows, system type, no art): read it, close it, nothing to click through.
struct HelpView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openSettings) private var openSettings
    var close: () -> Void = {}
    /// Tall enough for the whole page on a normal display; the Form scrolls on a small one.
    static func preferredHeight(for screen: NSScreen?) -> CGFloat {
        min(900, (screen?.visibleFrame.height ?? 900) - 60)
    }

    var body: some View {
        let preferences = state.preferences
        VStack(spacing: 0) {
            Form {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 28))
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Point at anything.")
                                .font(.title3.weight(.semibold))
                            Text("Deixis hands your coding agent the element under your cursor: role, identifier, frame, a cropped image, and your note. Paste it and the agent finds the right file.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Point") {
                    Row(symbol: "keyboard", title: "Open the overlay", detail: "Press the hotkey, or click the ball. The pointing hand in the menu bar works too.", key: preferences.hotkey.symbol)
                    Row(symbol: "cursorarrow.rays", title: "Pick the element", detail: "Hover, then click or press Return. Drag for a frame with everything inside it; Option steps to the parent.", key: "↩")
                    Row(symbol: "text.cursor", title: "Say what should change", detail: "Type a note, press Return. The payload is on the clipboard; paste it into your agent. Esc at any point cancels, nothing written.", key: "↩")
                }
                Section("The other actions") {
                    Row(symbol: "camera.viewfinder", title: "Snap", detail: "A window or a dragged region as a PNG. Hold ⌥ at release to keep it off disk.", key: preferences.actionHotkeys["snap"]?.symbol)
                    Row(symbol: "text.viewfinder", title: "Text", detail: "The text in an element or a region, recognized, to the clipboard.", key: preferences.actionHotkeys["text"]?.symbol)
                    Row(symbol: "eyedropper", title: "Color", detail: "A magnifier follows the cursor. Arrows nudge by a pixel, click copies the value.", key: preferences.actionHotkeys["color"]?.symbol)
                    Row(symbol: "person.and.background.dotted", title: "Cut", detail: "The subject cut onto a transparent background.", key: preferences.actionHotkeys["cut"]?.symbol)
                    Row(symbol: "circle.circle", title: "The ring", detail: "All four are on the ball: hold it for half a second and release on one. A shorter press is Point.", key: nil)
                }
                Section("Afterwards") {
                    Row(symbol: "arrow.triangle.2.circlepath", title: "See what changed", detail: "In the menu bar, once your agent has edited: Deixis finds the same element again and shows before and after with the git diff.", key: nil)
                    Row(symbol: "clock.arrow.circlepath", title: "Old images are cleaned up", detail: "Older images go to the Trash. Change the period, or keep everything, in Settings.", key: preferences.retentionDays == 0 ? "Forever" : "\(preferences.retentionDays) days")
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Text("Open this again from Settings › General.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Settings…") {
                    close()
                    openSettings()
                }
                Button("Close", action: close)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 560, height: Self.preferredHeight(for: NSScreen.main))
    }

    /// Symbol, title, one line beneath, and the key on the trailing edge, the way Settings lays out a row.
    private struct Row: View {
        let symbol: String
        let title: String
        let detail: String
        let key: String?

        var body: some View {
            LabeledContent {
                if let key {
                    Text(key)
                        .foregroundStyle(.secondary)
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: symbol)
                        .frame(width: 20)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// The window that hosts `HelpView`: one instance, reopened in place.
@MainActor
final class HelpWindow {
    private var window: NSWindow?

    func show(state: AppState) {
        if window == nil {
            let created = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            // Not resizable: the page is one size, and a smaller display gets a scrolling Form instead.
            created.title = "Deixis Help"
            created.isReleasedWhenClosed = false
            let hosting = NSHostingView(rootView: HelpView(close: { [weak created] in created?.close() }).environment(state))
            created.contentView = hosting
            created.setContentSize(hosting.fittingSize)
            created.center()
            window = created
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
