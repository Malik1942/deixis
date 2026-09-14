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
    @ObservationIgnored private var lastHoverPoint: CGPoint = .zero
    @ObservationIgnored private var lastHoverSnapshot: ElementSnapshot?
    @ObservationIgnored private var lastHoverElement: ResolvedElement?
    /// What Option cycles through for the hovered spot (see `HitRefiner.selectionLevels`).
    @ObservationIgnored private var levels: [ResolvedElement?] = []
    @ObservationIgnored private var levelIndex = 0
    @ObservationIgnored private var lockedElement: ResolvedElement?
    @ObservationIgnored private var lockedElements: [RegionElement]?
    @ObservationIgnored private var lockedNearby: [RegionElement]?
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
        overlay.onOptionPressed = { [weak self] in self?.optionPressed() }
        overlay.onRegion = { [weak self] rect, start in self?.region(rect, start: start) }
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
    /// R2 hover precision: the reader already refines container hits toward a real control; here the
    /// last small element sticks while the cursor stays near it, so gaps do not flip to the big group.
    private func drainHover() async {
        defer { hoverTask = nil }
        while phase == .hovering, let point = pendingHover {
            pendingHover = nil
            let fresh = await reader.snapshot(at: point, pid: targetPID(at: point))
            guard phase == .hovering else { return }
            let freshLevels = fresh.map { HitRefiner.selectionLevels(for: $0, at: point) } ?? []
            let freshElement = freshLevels.first ?? nil
            let freshIsVague = freshElement.map { ElementResolver.containerRoles.contains($0.role) } ?? true
            if freshIsVague, HitRefiner.sticks(lastHoverElement, to: point) {
                // Crossing padding: keep the small element and its Option level.
            } else {
                if freshElement?.frame != lastHoverElement?.frame { levelIndex = 0 }
                lastHoverSnapshot = fresh
                levels = freshLevels
                lastHoverElement = freshElement
            }
            lastHoverPoint = point
            renderHover()
            try? await Task.sleep(for: .milliseconds(33))
        }
    }

    /// The hovered selection at the current Option level.
    private func selectedElement() -> ResolvedElement? {
        levels.indices.contains(levelIndex) ? levels[levelIndex] : lastHoverElement
    }

    private func renderHover() {
        let element = selectedElement()
        var readout = Readout.describing(element)
        if levelIndex > 0 {
            readout.suffix = [readout.suffix, "↑\(levelIndex)"].compactMap { $0 }.joined(separator: " · ")
        }
        overlay.setHighlight(element?.frame.cgRect, readout: readout, around: lastHoverPoint)
    }

    /// Option while hovering: cluster, parent, grandparent, … then back to the element.
    private func optionPressed() {
        guard phase == .hovering, levels.count > 1 else { return }
        levelIndex = (levelIndex + 1) % levels.count
        renderHover()
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
            // What the user saw is what they clicked: keep the hovered selection (and its Option
            // depth) when the click is on or near it; otherwise resolve fresh with the lazy-tree retry.
            let element: ResolvedElement?
            let slack = HitRefiner.stickiness
            let hoverIsCurrent = !levels.isEmpty
                && (lastHoverElement.map { $0.frame.cgRect.insetBy(dx: -slack, dy: -slack).contains(point) } ?? true)
            if hoverIsCurrent {
                element = selectedElement()
            } else {
                let snapshot = await ElementResolver.snapshotWithRetry(at: point, using: AppElementProvider(reader: reader, pid: pid))
                element = snapshot.map { HitRefiner.selectionLevels(for: $0, at: point).first ?? nil } ?? nil
            }
            guard phase == .resolving else { return }
            lockedElement = element
            if element == nil, let snapshot = lastHoverSnapshot {
                // v0.2 R15: what sits around a point that has no element.
                let neighborhood = snapshot.children ?? snapshot.siblings ?? []
                lockedNearby = RegionResolver.nearby(point: point, among: neighborhood).map(\.element)
            }

            // R5: the source is the app that owns the clicked window. The hotkey-time context is
            // the fallback when the click lands on the frontmost app or outside any window.
            if pid != context.frontPID, let clicked = await ContextCollector.collect(reader: reader, pid: pid) {
                guard phase == .resolving else { return }
                self.context = clicked
            }

            let display = SelectionOverlay.displayFrameCG(containing: point)
            let rect = Geometry.cropRect(element: element?.frame.cgRect, clickPoint: point, window: window?.bounds, display: display)
            cropTask = Task { try await ScreenCapture.crop(rect) }

            overlay.setHighlight(element?.frame.cgRect, readout: .describing(element), around: point)
            overlay.showNoteField(anchoredTo: element?.frame.cgRect, around: point)
            phase = .noting
        }
    }

    /// v0.2 R11–R13: a drawn frame. Everything at least half inside becomes `elements`, the best of
    /// it the primary `element`, and the frame itself is the crop.
    private func region(_ rect: CGRect, start: CGPoint) {
        guard phase == .hovering, let context else { return }
        phase = .resolving
        pendingHover = nil
        clickPoint = CGPoint(x: rect.midX, y: rect.midY)
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: rect)
            return
        }
        Task {
            let window = Geometry.windowOwner(at: start, windows: windows, excludingPID: ownPID)
            let pid = window?.ownerPID ?? context.frontPID
            var snapshots = await reader.elements(in: rect, pid: pid)
            var retry = 0
            while snapshots.isEmpty, retry < 2 { // lazy tree
                retry += 1
                try? await Task.sleep(for: .milliseconds(100))
                snapshots = await reader.elements(in: rect, pid: pid)
            }
            guard phase == .resolving else { return }
            if pid != context.frontPID, let clicked = await ContextCollector.collect(reader: reader, pid: pid) {
                guard phase == .resolving else { return }
                self.context = clicked
            }
            let elements = RegionResolver.elements(in: rect, among: snapshots)
            lockedElement = RegionResolver.primary(among: snapshots, in: rect)
            lockedElements = elements

            let display = SelectionOverlay.displayFrameCG(containing: clickPoint)
            let crop = Geometry.cropRect(element: rect, clickPoint: clickPoint, window: nil, display: display, padding: 0)
            cropTask = Task { try await ScreenCapture.crop(crop) }

            overlay.showMarks(elements.map { $0.frame.cgRect })
            overlay.showNoteField(anchoredTo: rect, around: clickPoint)
            phase = .noting
        }
    }

    /// R6/R7/R8: only Enter writes. Files first, clipboard last.
    private func commit(note: String) {
        guard phase == .noting, let context, let cropTask else { return }
        phase = .writing
        let element = lockedElement
        let elements = lockedElements
        let nearby = lockedNearby
        let anchor = element?.frame.cgRect ?? SelectionOverlay.fallbackRect(around: clickPoint)
        Task {
            do {
                let image = try await cropTask.value
                let now = Date()
                var capture = Capture(
                    id: FileStore.makeID(date: now),
                    createdAt: FileStore.isoTimestamp(date: now),
                    mode: ModeClassifier.classify(context.source),
                    image: ImageInfo(path: "", widthPt: image.widthPt, heightPt: image.heightPt, scale: image.scale, crop: Frame(image.crop)),
                    source: context.source,
                    element: element,
                    note: note,
                    elements: elements,
                    nearby: nearby
                )
                // v0.2 R14: text in the image when nothing has an identifier.
                let hasIdentifier = element?.identifier != nil || (elements?.contains { $0.identifier != nil } ?? false)
                if !hasIdentifier, let lines = try? await TextRecognizer.lines(inPNG: image.png), !lines.isEmpty {
                    capture.ocr = lines.joined(separator: "\n")
                }
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
        lockedElements = nil
        lockedNearby = nil
        lastHoverSnapshot = nil
        lastHoverElement = nil
        levels = []
        levelIndex = 0
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
