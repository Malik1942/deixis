import AppKit
import SwiftUI

/// R35: the one window besides Settings. Note above, before and after side by side with a shared
/// zoom, an iteration picker when there are several, the diff stat and files in mono beneath.
/// No judgment: the human decides.
struct BeforeAfterView: View {
    let capture: Capture
    @State private var zoom: Double = 1
    @State private var index: Int

    init(capture: Capture) {
        self.capture = capture
        _index = State(initialValue: max(capture.iterations.count - 1, 0))
    }

    private var iteration: Iteration? {
        capture.iterations.indices.contains(index) ? capture.iterations[index] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !capture.note.isEmpty {
                Text(capture.note).font(.body)
            }
            HStack(alignment: .top, spacing: 16) {
                pane(title: "Before", path: capture.image.path)
                pane(title: iteration.map { "After · \(MarkdownBuilder.capturedText($0.capturedAt))" } ?? "After", path: iteration?.imagePath)
            }
            HStack(spacing: 16) {
                Slider(value: $zoom, in: 0.5...3) { Text("Zoom") }
                    .frame(maxWidth: 240)
                if capture.iterations.count > 1 {
                    Picker("Iteration", selection: $index) {
                        ForEach(capture.iterations.indices, id: \.self) { i in
                            Text("#\(i + 1)").tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)
                }
                Spacer()
            }
            if let iteration {
                VStack(alignment: .leading, spacing: 4) {
                    Text(GitFacts.summaryLine(of: iteration.diffStat) ?? (capture.source.projectRoot == nil ? "No project folder known for this capture." : "No changes in the repository."))
                        .font(.system(.body, design: .monospaced))
                    ForEach(iteration.files, id: \.self) { file in
                        Text(file).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 420, alignment: .topLeading)
    }

    @ViewBuilder
    private func pane(title: String, path: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            ScrollView([.horizontal, .vertical]) {
                if let path, let image = NSImage(contentsOfFile: path) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: image.size.width * zoom, height: image.size.height * zoom)
                } else {
                    Text("Image missing").font(.callout).foregroundStyle(.secondary).padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

/// A standard window hosting `BeforeAfterView`. Owned by `AppState`.
@MainActor
final class BeforeAfterWindow {
    private var window: NSWindow?

    func show(_ capture: Capture) {
        let hosting = NSHostingView(rootView: BeforeAfterView(capture: capture))
        if let window {
            window.contentView = hosting
        } else {
            let created = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 560), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            created.title = "Before & After"
            created.isReleasedWhenClosed = false
            created.contentView = hosting
            created.center()
            window = created
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
