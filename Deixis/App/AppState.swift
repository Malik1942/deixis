import AppKit
import Observation

/// The only shared object. Owns the system-resource objects (overlay, hotkey, toast, reader) and
/// runs one capture session at a time: hover → click → note → write.
@Observable
@MainActor
final class AppState {
    enum Phase: Equatable {
        case idle, hovering, resolving, noting, writing
    }

    private(set) var phase: Phase = .idle

    @ObservationIgnored private let reader = AccessibilityReader()
    @ObservationIgnored private let store = FileStore()
    @ObservationIgnored private let overlay = SelectionOverlay()
    @ObservationIgnored private let toast = Toast()
    @ObservationIgnored private var hotkey: HotkeyMonitor?
    @ObservationIgnored private var context: CaptureContext?
    @ObservationIgnored private var windows: [Geometry.WindowRecord] = []
    @ObservationIgnored private var hoverTask: Task<Void, Never>?
    @ObservationIgnored private var pendingHover: CGPoint?
    @ObservationIgnored private var lockedElement: ResolvedElement?
    @ObservationIgnored private var clickPoint: CGPoint = .zero
    @ObservationIgnored private var cropTask: Task<CroppedImage, any Error>?
    @ObservationIgnored private var openedSettingsPanes: Set<String> = []
    @ObservationIgnored private let ownPID = ProcessInfo.processInfo.processIdentifier

    var captureDirectory: URL { store.directory }

    func start() {
        overlay.onHover = { [weak self] point in self?.hover(point) }
        overlay.onClick = { [weak self] point in self?.click(point) }
        overlay.onCancel = { [weak self] in self?.cancel() }
        overlay.onCommit = { [weak self] note in self?.commit(note: note) }
        let monitor = HotkeyMonitor { [weak self] in self?.beginCapture() }
        monitor.start()
        hotkey = monitor
    }

    // MARK: Session

    /// R1/R5: collect context for the app the user was looking at, then show the overlay.
    func beginCapture() {
        guard phase == .idle else { return }
        guard AccessibilityReader.isTrusted(prompt: false) else {
            fail(.noAccessibilityPermission, nearRect: nil)
            return
        }
        phase = .hovering
        Task {
            guard let collected = await ContextCollector.collect(reader: reader) else {
                reset()
                return
            }
            guard phase == .hovering else { return }
            context = collected
            windows = WindowList.onScreen()
            overlay.show()
        }
    }

    private func hover(_ point: CGPoint) {
        guard phase == .hovering else { return }
        pendingHover = point
        guard hoverTask == nil else { return }
        hoverTask = Task { await drainHover() }
    }

    /// One in-flight lookup at a time, latest point wins, at most ~30 Hz.
    private func drainHover() async {
        defer { hoverTask = nil }
        while phase == .hovering, let point = pendingHover {
            pendingHover = nil
            let snapshot = await reader.snapshot(at: point, pid: targetPID(at: point))
            guard phase == .hovering else { return }
            let element = snapshot.flatMap(ElementResolver.resolve)
            overlay.setHighlight(element?.frame.cgRect, readout: .describing(element), around: point)
            try? await Task.sleep(for: .milliseconds(33))
        }
    }

    /// R3: the app owning the window under the point, else the app that was frontmost at hotkey time.
    private func targetPID(at point: CGPoint) -> pid_t {
        Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID)?.ownerPID ?? context?.frontPID ?? 0
    }

    private func click(_ point: CGPoint) {
        guard phase == .hovering, let context else { return }
        phase = .resolving
        pendingHover = nil
        clickPoint = point
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: SelectionOverlay.fallbackRect(around: point))
            return
        }
        Task {
            let window = Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID)
            let pid = window?.ownerPID ?? context.frontPID
            let element = await ElementResolver.resolve(at: point, using: AppElementProvider(reader: reader, pid: pid))
            guard phase == .resolving else { return }
            lockedElement = element

            let display = SelectionOverlay.displayFrameCG(containing: point)
            let rect = Geometry.cropRect(element: element?.frame.cgRect, clickPoint: point, window: window?.bounds, display: display)
            cropTask = Task { try await ScreenCapture.crop(rect) }

            overlay.setHighlight(element?.frame.cgRect, readout: .describing(element), around: point)
            overlay.showNoteField(anchoredTo: element?.frame.cgRect, around: point)
            phase = .noting
        }
    }

    /// R6/R7/R8: only Enter writes. Files first, clipboard last.
    private func commit(note: String) {
        guard phase == .noting, let context, let cropTask else { return }
        phase = .writing
        let element = lockedElement
        let anchor = element?.frame.cgRect ?? SelectionOverlay.fallbackRect(around: clickPoint)
        Task {
            do {
                let image = try await cropTask.value
                let now = Date()
                let capture = Capture(
                    id: FileStore.makeID(date: now),
                    createdAt: FileStore.isoTimestamp(date: now),
                    mode: ModeClassifier.classify(context.source),
                    image: ImageInfo(path: "", widthPt: image.widthPt, heightPt: image.heightPt, scale: image.scale, crop: Frame(image.crop)),
                    source: context.source,
                    element: element,
                    note: note
                )
                let written = try store.write(png: image.png, capture: capture)
                PasteboardWriter.write(markdown: MarkdownBuilder.build(written), png: image.png)
                reset()
                toast.show(HudText.copied(identifier: element?.identifier), near: anchor)
            } catch {
                fail(.captureFailed(error), nearRect: anchor)
            }
        }
    }

    /// Esc at any point: nothing on disk, clipboard untouched.
    func cancel() {
        guard phase != .idle else { return }
        cropTask?.cancel()
        reset()
    }

    private func reset() {
        phase = .idle
        hoverTask?.cancel()
        hoverTask = nil
        pendingHover = nil
        cropTask = nil
        lockedElement = nil
        context = nil
        windows = []
        overlay.dismiss()
    }

    // MARK: Failure (R9)

    private func fail(_ error: CaptureError, nearRect anchor: CGRect?) {
        reset()
        let rect = anchor ?? Self.mainScreenCenterCG()
        toast.show(HudText.plain(error.message), near: rect)
        switch error {
        case .noAccessibilityPermission: openSettingsOnce(pane: "Privacy_Accessibility")
        case .noScreenRecordingPermission: openSettingsOnce(pane: "Privacy_ScreenCapture")
        case .noElementUnderCursor, .captureFailed: break
        }
    }

    private func openSettingsOnce(pane: String) {
        guard !openedSettingsPanes.contains(pane) else { return }
        openedSettingsPanes.insert(pane)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func mainScreenCenterCG() -> CGRect {
        let frame = NSScreen.main?.frame ?? .zero
        let center = Geometry.cgPoint(fromAppKit: CGPoint(x: frame.midX, y: frame.midY), primaryHeight: SelectionOverlay.currentPrimaryHeight())
        return CGRect(x: center.x, y: center.y, width: 0, height: 0)
    }

    // MARK: Menu actions

    func openCaptureFolder() {
        try? FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        NSWorkspace.shared.open(store.directory)
    }
}
