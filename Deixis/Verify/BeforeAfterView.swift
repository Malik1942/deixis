import AppKit
import SwiftUI

/// R35 (revised Sep 13): one comparison canvas, three ways to look at it. Slide wipes between
/// before and after under a draggable divider; Side by side puts them next to each other; Flip
/// swaps on click. An iterations strip picks which after is compared. No judgment: the human decides.
struct BeforeAfterView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case slide = "Slide", sideBySide = "Side by side", flip = "Flip"
        var id: String { rawValue }
    }

    let capture: Capture
    private let before: NSImage?
    private let afters: [NSImage?]

    @State private var mode: Mode = .slide
    @State private var zoom: Double = 1
    @State private var index: Int
    @State private var split: CGFloat = 0.5
    @State private var flipped = false
    @State private var showAll = false

    init(capture: Capture) {
        self.capture = capture
        before = NSImage(contentsOfFile: capture.image.path)
        afters = capture.iterations.map { NSImage(contentsOfFile: $0.imagePath) }
        _index = State(initialValue: max(capture.iterations.count - 1, 0))
    }

    private var iteration: Iteration? {
        capture.iterations.indices.contains(index) ? capture.iterations[index] : nil
    }

    private var after: NSImage? {
        afters.indices.contains(index) ? afters[index] : nil
    }

    /// Both images drawn at one size: the larger of the two, so nothing is cropped.
    private var canvas: CGSize {
        let w = max(before?.size.width ?? 0, after?.size.width ?? 0, 120) * zoom
        let h = max(before?.size.height ?? 0, after?.size.height ?? 0, 80) * zoom
        return CGSize(width: w, height: h)
    }

    private var elementLine: String {
        let source = capture.source.simulator?.appBundleId ?? capture.source.app.name
        guard let element = capture.element else { return source }
        let name = element.identifier.map { "id=\($0)" } ?? element.label.map { "\"\($0)\"" } ?? ""
        return "\(source) · \(element.role) \(name)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if !capture.note.isEmpty {
                    Text(capture.note).font(.title3)
                }
                Text(elementLine).font(.callout).foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 280)
                Slider(value: $zoom, in: 0.5...3) { Text("Zoom") }
                    .labelsHidden()
                    .frame(width: 140)
                Spacer()
                Button(showAll ? "Hide iterations" : "All iterations (\(capture.iterations.count))") {
                    showAll.toggle()
                }
                .disabled(capture.iterations.isEmpty)
            }

            comparison
                .frame(maxWidth: .infinity, alignment: .leading)

            if showAll {
                iterationStrip
            }

            if let iteration {
                VStack(alignment: .leading, spacing: 3) {
                    Text(GitFacts.summaryLine(of: iteration.diffStat) ?? (capture.source.projectRoot == nil ? "No project folder known for this capture." : "No changes in the repository."))
                        .font(.system(.callout, design: .monospaced))
                    ForEach(iteration.files, id: \.self) { file in
                        Text(file).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 520, alignment: .topLeading)
    }

    // MARK: Comparison

    @ViewBuilder
    private var comparison: some View {
        let size = canvas
        switch mode {
        case .slide:
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    picture(before)
                    picture(after)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: size.width * split)
                        }
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 2, height: size.height)
                        .offset(x: size.width * split - 1)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 2))
                        .offset(x: size.width * split - 7, y: size.height / 2 - 7)
                    caption("Before", at: .topLeading)
                    caption(afterTitle, at: .bottomTrailing)
                }
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    split = min(max(value.location.x / size.width, 0), 1)
                })
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, maxHeight: 520)
        case .sideBySide:
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 8) {
                    ZStack(alignment: .topLeading) { picture(before); caption("Before", at: .topLeading) }
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    ZStack(alignment: .topLeading) { picture(after); caption(afterTitle, at: .topLeading) }
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 520)
        case .flip:
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    picture(flipped ? after : before)
                    caption(flipped ? afterTitle : "Before · click to flip", at: .topLeading)
                }
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .onTapGesture { flipped.toggle() }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, maxHeight: 520)
        }
    }

    private var afterTitle: String {
        guard let iteration else { return "After" }
        return "After #\(index + 1) · \(String(MarkdownBuilder.capturedText(iteration.capturedAt).suffix(5)))"
    }

    @ViewBuilder
    private func picture(_ image: NSImage?) -> some View {
        let size = canvas
        ZStack {
            Color(nsColor: .controlBackgroundColor)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: image.size.width * zoom, height: image.size.height * zoom)
            } else {
                Text("Image missing").font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }

    private func caption(_ text: String, at alignment: Alignment) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .allowsHitTesting(false)
    }

    // MARK: Iterations strip

    private var iterationStrip: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
                thumbnail(before, title: "Before", subtitle: MarkdownBuilder.capturedText(capture.createdAt), selected: false)
                ForEach(capture.iterations.indices, id: \.self) { i in
                    let iteration = capture.iterations[i]
                    Button {
                        index = i
                    } label: {
                        thumbnail(afters[i], title: "After #\(i + 1)", subtitle: MarkdownBuilder.capturedText(iteration.capturedAt), selected: i == index)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func thumbnail(_ image: NSImage?, title: String, subtitle: String, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ZStack {
                Color(nsColor: .controlBackgroundColor)
                if let image {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 112, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: selected ? 2 : 1))
            Text(title).font(.caption)
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
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
            window.setContentSize(hosting.fittingSize)
        } else {
            let created = NSWindow(contentRect: NSRect(origin: .zero, size: hosting.fittingSize), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            created.title = "Before & After"
            created.isReleasedWhenClosed = false
            created.contentView = hosting
            created.contentMinSize = NSSize(width: 520, height: 320)
            created.center()
            window = created
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
