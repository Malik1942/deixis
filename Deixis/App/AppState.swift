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

    /// R22: which action the overlay is open for.
    enum Action: Equatable {
        case point, snap, text, cut

        var overlayMode: OverlayMode {
            switch self {
            case .point: .point
            case .snap: .snap
            case .text: .text
            case .cut: .cut
            }
        }
    }

    private(set) var phase: Phase = .idle
    let preferences = Preferences()

    @ObservationIgnored private let reader = AccessibilityReader()
    @ObservationIgnored private var userTeamIDs: Set<String> = []
    @ObservationIgnored private let overlay = SelectionOverlay()
    @ObservationIgnored private let toast = Toast()
    @ObservationIgnored private var hotkeys: HotkeyMonitor?
    @ObservationIgnored private var ball: FloatingBall?
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
    @ObservationIgnored private var action: Action = .point
    @ObservationIgnored private var colorSession: ColorPickerSession?
    @ObservationIgnored private var clipboardOnlyPreset = false
    @ObservationIgnored private var sweepTask: Task<Void, Never>?
    @ObservationIgnored private let beforeAfter = BeforeAfterWindow()
    /// R25: the last ten picked colors, in memory only.
    @ObservationIgnored private(set) var recentColors: [ColorValue] = []
    @ObservationIgnored private var clickPoint: CGPoint = .zero
    @ObservationIgnored private var cropTask: Task<CroppedImage, any Error>?
    @ObservationIgnored private var openedSettingsPanes: Set<String> = []
    @ObservationIgnored private let ownPID = ProcessInfo.processInfo.processIdentifier

    var captureDirectory: URL { preferences.captureFolderURL }

    func start() {
        Task.detached { [weak self] in
            let teams = CodeSigning.userTeamIDs()
            await MainActor.run { self?.userTeamIDs = teams }
        }
        preferences.onHotkeyChange = { [weak self] in self?.restartHotkey() }
        preferences.onActionHotkeysChange = { [weak self] in self?.restartHotkey() }
        preferences.onBallEnabledChange = { [weak self] in self?.updateBall() }
        preferences.onBallAutoHideChange = { [weak self] in
            guard let self else { return }
            self.ball?.autoHide = self.preferences.ballAutoHide
        }
        updateBall()
        showLaunchHintIfNeeded()
        scheduleSweeps()
        overlay.onHover = { [weak self] point in self?.hover(point) }
        overlay.onClick = { [weak self] point in self?.click(point) }
        overlay.onCancel = { [weak self] in self?.cancel() }
        overlay.onCommit = { [weak self] note in self?.commit(note: note) }
        overlay.onOptionPressed = { [weak self] in self?.optionPressed() }
        overlay.onRegion = { [weak self] rect, start in self?.region(rect, start: start) }
        restartHotkey()
    }

    /// One monitor for the capture hotkey and every action hotkey (R29).
    private func restartHotkey() {
        hotkeys?.stop()
        var bindings = [HotkeyMonitor.Binding(preferences.hotkey) { [weak self] in self?.beginCapture() }]
        for (name, key) in preferences.actionHotkeys {
            guard let fire = fire(forAction: name) else { continue }
            bindings.append(HotkeyMonitor.Binding(key, fire: fire))
        }
        let monitor = HotkeyMonitor(bindings: bindings)
        monitor.start()
        hotkeys = monitor
        ball?.ringHints = ringHints()
    }

    /// What an action hotkey starts, by the action's name in `Preferences.hotkeyActions`.
    private func fire(forAction name: String) -> (@MainActor () -> Void)? {
        switch name {
        case "point": return { [weak self] in self?.beginCapture() }
        case "snap": return { [weak self] in self?.beginAction(.snap) }
        case "text": return { [weak self] in self?.beginAction(.text) }
        case "color": return { [weak self] in self?.beginColorPick() }
        case "cut": return { [weak self] in self?.beginAction(.cut) }
        default: return nil
        }
    }

    /// The action hotkeys, shown on the ring beside each segment's name.
    private func ringHints() -> [Ring.Segment: String] {
        var hints: [Ring.Segment: String] = [:]
        for segment in Ring.Segment.allCases {
            if let hotkey = preferences.actionHotkeys[segment.actionName] { hints[segment] = hotkey.symbol }
        }
        return hints
    }

    /// v0.3 R20: the ball follows the Settings toggle; first launch places it at the lower right.
    private func updateBall() {
        if preferences.ballEnabled {
            guard ball == nil else { return }
            let firstLaunch = preferences.ballPosition == nil
            let newBall = FloatingBall(origin: preferences.ballPosition)
            newBall.autoHide = preferences.ballAutoHide
            newBall.onPoint = { [weak self] in self?.beginCapture() }
            newBall.onMoved = { [weak self] origin in self?.preferences.ballPosition = origin }
            newBall.onAction = { [weak self] segment, clipboardOnly in self?.beginRingAction(segment, clipboardOnly: clipboardOnly) }
            newBall.ringHints = ringHints()
            newBall.show(firstLaunch: firstLaunch)
            ball = newBall
        } else {
            ball?.hide()
            ball = nil
        }
    }

    /// While the Settings recorder listens, the real hotkeys must not fire.
    func pauseHotkey() {
        hotkeys?.stop()
    }
    func resumeHotkey() { restartHotkey() }

    // MARK: Session

    /// R1/R5: collect context for the app the user was looking at, then show the overlay.
    func beginCapture() {
        beginAction(.point)
    }

    /// R27: a ring segment chosen on the ball.
    func beginRingAction(_ segment: Ring.Segment, clipboardOnly: Bool) {
        switch segment {
        case .snap: clipboardOnlyPreset = clipboardOnly; beginAction(.snap)
        case .text: beginAction(.text)
        case .color: beginColorPick()
        case .cut: clipboardOnlyPreset = clipboardOnly; beginAction(.cut)
        }
    }

    // MARK: Lifecycle (R28)

    /// Sweep on launch and every 24 hours; the folder is read recursively.
    private func scheduleSweeps() {
        sweepTask?.cancel()
        sweepTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let folder = self.preferences.captureFolderURL
                let days = self.preferences.retentionDays
                _ = await Task.detached { Lifecycle.sweep(folder: folder, retentionDays: days) }.value
                try? await Task.sleep(for: Lifecycle.sweepInterval)
            }
        }
    }

    // MARK: Verify (v0.4)

    /// The newest Point capture: an image with a sidecar.
    private func newestSidecar() -> URL? {
        Lifecycle.entries(in: preferences.captureFolderURL)
            .filter { $0.urls.count == 2 }
            .max { $0.modified < $1.modified }?
            .urls.first(where: { $0.pathExtension == "json" })
    }

    /// R31–R34: find the newest capture's element again in the running app, capture it, record the
    /// git facts, append the iteration, and show the panel.
    func captureAfter() {
        guard phase == .idle else { return }
        guard let sidecar = newestSidecar(), let capture = try? IterationStore.load(sidecar) else {
            toast.show(HudText.plain("No capture to verify"), near: Self.mainScreenCenterCG())
            return
        }
        guard let element = capture.element, element.role != ElementResolver.clusterRole else {
            toast.show(HudText.plain("Nothing to re-find in the last capture"), near: Self.mainScreenCenterCG())
            return
        }
        let bundleId = capture.source.app.bundleId
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first else {
            toast.show(HudText.plain("\(capture.source.app.name) is not running"), near: Self.mainScreenCenterCG())
            return
        }
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: nil)
            return
        }
        phase = .writing
        let pid = app.processIdentifier
        let name = element.identifier ?? element.label ?? element.role
        Task {
            var found: ResolvedElement?
            var windowBounds: CGRect?
            for attempt in 0..<ElementRefinder.retries {
                let windows = WindowList.onScreen().filter { $0.ownerPID == pid && $0.layer == 0 }
                let largest = windows.max { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }
                windowBounds = largest?.bounds
                let region = largest?.bounds ?? SelectionOverlay.displayFrameCG(containing: element.frame.cgRect.origin)
                let snapshots = await reader.elements(in: region, pid: pid)
                found = ElementRefinder.match(element, among: snapshots)
                if found != nil { break }
                if attempt < ElementRefinder.retries - 1 { try? await Task.sleep(for: ElementRefinder.retryInterval) }
            }
            guard let found else {
                phase = .idle
                toast.show(HudText.plain("Element not found · \(name)"), near: element.frame.cgRect)
                return
            }
            do {
                let center = CGPoint(x: found.frame.x + found.frame.w / 2, y: found.frame.y + found.frame.h / 2)
                let display = SelectionOverlay.displayFrameCG(containing: center)
                let crop = Geometry.cropRect(element: found.frame.cgRect, clickPoint: center, window: windowBounds, display: display)
                let image = try await ScreenCapture.crop(crop)
                let index = capture.iterations.count + 1
                let afterURL = IterationStore.afterImageURL(for: sidecar, index: index)
                try image.png.write(to: afterURL, options: .atomic)
                FileStore.setFinderTags(FileStore.tags(for: capture) + ["after"], on: afterURL)
                let root = capture.source.projectRoot
                let before = capture.source.gitCommit
                let change: GitChange = await Task.detached {
                    root.map { GitFacts.changes(at: $0, since: before) } ?? GitChange(before: before, after: nil, diffStat: nil, files: [])
                }.value
                let iteration = Iteration(
                    capturedAt: FileStore.isoTimestamp(date: Date()),
                    imagePath: afterURL.path(percentEncoded: false),
                    gitBefore: change.before, gitAfter: change.after, diffStat: change.diffStat, files: change.files,
                    frame: found.frame
                )
                let updated = try IterationStore.append(iteration, to: sidecar)
                phase = .idle
                let summary = GitFacts.summaryLine(of: change.diffStat) ?? (root == nil ? "no project folder" : "no changes")
                toast.show(HudText.plain("After #\(index) · \(summary)"), near: found.frame.cgRect)
                beforeAfter.show(updated)
            } catch {
                phase = .idle
                fail(.captureFailed(error), nearRect: found.frame.cgRect)
            }
        }
    }

    /// R35: the newest capture that has iterations.
    func showBeforeAfter() {
        let candidates = Lifecycle.entries(in: preferences.captureFolderURL)
            .filter { $0.urls.count == 2 }
            .sorted { $0.modified > $1.modified }
        for entry in candidates {
            guard let sidecar = entry.urls.first(where: { $0.pathExtension == "json" }),
                  let capture = try? IterationStore.load(sidecar), !capture.iterations.isEmpty else { continue }
            beforeAfter.show(capture)
            return
        }
        toast.show(HudText.plain("No verified capture yet · use Capture after"), near: Self.mainScreenCenterCG())
    }

    /// Menu bar: keep the newest capture out of the sweep.
    func pinLastCapture() {
        let folder = preferences.captureFolderURL
        guard let newest = Lifecycle.newest(in: folder) else {
            toast.show(HudText.plain("No capture to pin"), near: Self.mainScreenCenterCG())
            return
        }
        Lifecycle.pin(newest.urls)
        toast.show(HudText.copied(identifier: nil).string == "Copied" ? HudText.plain("Pinned · \(newest.urls[0].lastPathComponent)") : HudText.plain("Pinned"), near: Self.mainScreenCenterCG())
    }

    /// R25: the magnifier session. Click copies the pixel in the chosen format; Esc cancels.
    func beginColorPick() {
        guard phase == .idle, colorSession == nil else { return }
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: nil)
            return
        }
        phase = .writing
        let session = ColorPickerSession(space: preferences.colorSpace, format: preferences.colorFormat)
        session.onPick = { [weak self] color in
            guard let self else { return }
            let text = ColorPicker.format(color, as: self.preferences.colorFormat)
            PasteboardWriter.write(string: text)
            recentColors = Array(([color] + recentColors).prefix(10))
            endColorPick()
            let cursor = Geometry.cgPoint(fromAppKit: NSEvent.mouseLocation, primaryHeight: SelectionOverlay.currentPrimaryHeight())
            toast.show(HudText.copied(identifier: text), near: CGRect(origin: cursor, size: .zero))
        }
        session.onCancel = { [weak self] in self?.endColorPick() }
        colorSession = session
        session.start()
        showHintIfNeeded(key: "color", text: "Click or ↩ copies · arrows nudge a pixel · esc cancels")
    }

    private func endColorPick() {
        toast.hide()
        colorSession?.stop()
        colorSession = nil
        phase = .idle
    }

    /// R22: Snap, Text, and Cut open the same overlay in their mode.
    func beginAction(_ requested: Action) {
        guard phase == .idle else { return }
        action = requested
        overlay.mode = requested.overlayMode
        overlay.adjustsRegion = preferences.adjustSelection
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
            showHintIfNeeded(key: Self.hintKey(for: requested), text: Self.hintText(for: requested))
        }
    }

    // MARK: Hints (v0.5 R40)

    private static let hintShowings = 3

    /// Once, after the permission alerts: what to press. Waits for the ball's first-launch fade-in.
    private func showLaunchHintIfNeeded() {
        guard preferences.hintCount("launch") == 0 else { return }
        preferences.markHintShown("launch")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            let symbol = self.preferences.hotkey.symbol
            if let ball = self.ball {
                let anchor = Geometry.cgRect(fromAppKit: ball.frame, primaryHeight: SelectionOverlay.currentPrimaryHeight())
                self.toast.show(HudText.plain("Point at anything: \(symbol), or click the ball"), near: anchor, life: DesignTokens.hintLife)
            } else {
                self.toast.show(HudText.plain("Point at anything: \(symbol), also in the menu bar"), near: Self.mainScreenCenterCG(), life: DesignTokens.hintLife)
            }
        }
    }

    /// The first three opens of a mode: the gestures, at the bottom of the display under the cursor.
    private func showHintIfNeeded(key: String, text: String) {
        guard preferences.hintCount(key) < Self.hintShowings else { return }
        preferences.markHintShown(key)
        toast.show(HudText.plain(text), atBottomOf: NSEvent.mouseLocation, life: DesignTokens.hintLife)
    }

    private static func hintKey(for action: Action) -> String {
        switch action {
        case .point: "overlay.point"
        case .snap: "overlay.snap"
        case .text: "overlay.text"
        case .cut: "overlay.cut"
        }
    }

    private static func hintText(for action: Action) -> String {
        switch action {
        case .point: "Click or ↩ picks the element · drag draws a frame · ⌥ steps to the parent · esc cancels"
        case .snap, .cut: "Click or ↩ takes the window · drag draws a frame · ⌥ at release keeps it off disk · esc cancels"
        case .text: "Click or ↩ takes the element · drag draws a frame · esc cancels"
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
            if action == .snap || action == .cut {
                // Window under the cursor, no accessibility needed.
                lastHoverPoint = point
                if let window = Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID) {
                    let name = NSRunningApplication(processIdentifier: window.ownerPID)?.localizedName ?? "window"
                    overlay.setHighlight(window.bounds, readout: Readout(role: "window", identifier: nil, suffix: name, isFallback: false), around: point)
                } else {
                    overlay.setHighlight(nil, readout: .describing(nil), around: point)
                }
                try? await Task.sleep(for: .milliseconds(33))
                continue
            }
            let fresh = await reader.snapshot(at: point, candidates: windowCandidates(at: point), fallbackPID: context?.frontPID ?? 0)
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

    /// R3: the on-screen windows under the point, front to back, in every layer. The reader asks
    /// their owners in turn; the app frontmost at hotkey time is the fallback when none contains it.
    private func windowCandidates(at point: CGPoint) -> [Geometry.WindowRecord] {
        Geometry.windowCandidates(at: point, windows: windows, excludingPID: ownPID)
    }

    private func provider(at point: CGPoint) -> AppElementProvider {
        AppElementProvider(reader: reader, candidates: windowCandidates(at: point), fallbackPID: context?.frontPID ?? 0)
    }

    /// R5: the source is the app that owns what was clicked. A normal window keeps the hotkey-time
    /// context when it is the same app, and otherwise names the app's focused window. Anything else
    /// (a desktop icon, a widget, a status item, a Dock item) is described afresh, with the window the
    /// element itself sits in, if any: a widget says "Month", a desktop icon says none, rather than
    /// whichever Finder window happens to be focused.
    private func recollectContextIfNeeded(window: Geometry.WindowRecord?, snapshot: ElementSnapshot?) async {
        guard let context else { return }
        let pid = window?.ownerPID ?? context.frontPID
        let isNormalWindow = (window?.layer ?? 0) == 0
        guard !isNormalWindow || pid != context.frontPID else { return }
        let title: ContextCollector.WindowTitle = isNormalWindow ? .focused : .known(snapshot.flatMap(Self.windowTitle(in:)))
        if let clicked = await ContextCollector.collect(reader: reader, pid: pid, windowTitle: title), phase == .resolving {
            self.context = clicked
        }
    }

    private static func windowTitle(in snapshot: ElementSnapshot) -> String? {
        ([snapshot.element] + snapshot.ancestors)
            .first { ElementResolver.mapRole($0.role ?? "", subrole: $0.subrole) == "window" }
            .flatMap { ElementResolver.nonEmpty($0.title) }
    }

    private func click(_ point: CGPoint) {
        guard phase == .hovering, context != nil else { return }
        toast.hide()
        switch action {
        case .point:
            break
        case .snap, .cut:
            let rect = Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID)?.bounds
                ?? SelectionOverlay.displayFrameCG(containing: point)
            runOneShot(on: rect, at: point, fromRegion: false)
            return
        case .text:
            let rect = selectedElement()?.frame.cgRect.insetBy(dx: -HitRefiner.tolerance, dy: -HitRefiner.tolerance)
                ?? SelectionOverlay.fallbackRect(around: point)
            runOneShot(on: rect, at: point, fromRegion: false)
            return
        }
        phase = .resolving
        pendingHover = nil
        clickPoint = point
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: SelectionOverlay.fallbackRect(around: point))
            return
        }
        Task {
            // What the user saw is what they clicked: keep the hovered selection (and its Option
            // depth) when the click is on or near it; otherwise resolve fresh with the lazy-tree retry.
            let element: ResolvedElement?
            let snapshot: ElementSnapshot?
            let slack = HitRefiner.stickiness
            let hoverIsCurrent = !levels.isEmpty
                && (lastHoverElement.map { $0.frame.cgRect.insetBy(dx: -slack, dy: -slack).contains(point) } ?? false)
            if hoverIsCurrent, let shown = selectedElement() {
                element = shown
                snapshot = lastHoverSnapshot
            } else if levelIndex > 0, let shown = selectedElement() {
                element = shown // an Option level chosen on purpose
                snapshot = lastHoverSnapshot
            } else {
                // Nothing (or nothing specific) was hovered: read fresh, with the lazy-tree retry.
                snapshot = await ElementResolver.snapshotWithRetry(at: point, using: provider(at: point))
                element = snapshot.map { HitRefiner.selectionLevels(for: $0, at: point).first ?? nil } ?? nil
            }
            guard phase == .resolving else { return }
            // The window that answered the hit test, else the normal window under the point.
            let window = snapshot?.window ?? Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID)
            lockedElement = element
            if element == nil, let snapshot = lastHoverSnapshot {
                // v0.2 R15: what sits around a point that has no element.
                let neighborhood = snapshot.children ?? snapshot.siblings ?? []
                lockedNearby = RegionResolver.nearby(point: point, among: neighborhood).map(\.element)
            }

            await recollectContextIfNeeded(window: window, snapshot: snapshot)
            guard phase == .resolving else { return }

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
        toast.hide()
        if action != .point {
            runOneShot(on: rect, at: start, fromRegion: true)
            return
        }
        phase = .resolving
        pendingHover = nil
        clickPoint = CGPoint(x: rect.midX, y: rect.midY)
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: rect)
            return
        }
        Task {
            // The frame belongs to whoever answers at its first corner: a normal window, or the
            // desktop, a widget, or the menu bar behind an empty stretch of Dock or menu bar backdrop.
            let hit = await reader.snapshot(at: start, candidates: windowCandidates(at: start), fallbackPID: context.frontPID)
            guard phase == .resolving else { return }
            let window = hit?.window ?? Geometry.windowOwner(at: start, windows: windows, excludingPID: ownPID)
            let pid = window?.ownerPID ?? context.frontPID
            var snapshots = await reader.elements(in: rect, pid: pid)
            var retry = 0
            while snapshots.isEmpty, retry < 2 { // lazy tree
                retry += 1
                try? await Task.sleep(for: .milliseconds(100))
                snapshots = await reader.elements(in: rect, pid: pid)
            }
            guard phase == .resolving else { return }
            await recollectContextIfNeeded(window: window, snapshot: hit)
            guard phase == .resolving else { return }
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

    // MARK: One-shot actions (R23, R24, R26)

    /// Snap, Text, Cut: the overlay closes at once, the pixels are read, and the result goes to the
    /// clipboard (and to disk for images unless ⌥ was held). Failures leave the clipboard untouched.
    private func runOneShot(on rect: CGRect, at point: CGPoint, fromRegion: Bool) {
        guard let context else { return }
        let which = action
        let optionHeld = NSEvent.modifierFlags.contains(.option) || clipboardOnlyPreset
        clipboardOnlyPreset = false
        let appName = Geometry.windowOwner(at: point, windows: windows, excludingPID: ownPID)
            .flatMap { NSRunningApplication(processIdentifier: $0.ownerPID)?.localizedName } ?? context.source.app.name
        let display = SelectionOverlay.displayFrameCG(containing: point)
        let crop = Geometry.cropRect(element: rect, clickPoint: point, window: nil, display: display, padding: 0)
        let store = FileStore(directory: preferences.captureFolderURL, organization: preferences.organization)
        guard ScreenCapture.hasPermission() else {
            fail(.noScreenRecordingPermission, nearRect: rect)
            return
        }
        phase = .writing
        overlay.dismiss()
        Task {
            do {
                let image = try await ScreenCapture.crop(crop)
                let id = FileStore.makeID(date: Date())
                switch which {
                case .snap:
                    if !optionHeld {
                        try store.writeImage(png: image.png, fileName: Screenshot.fileName(appName: appName, id: id), appName: appName, tag: "snap")
                    }
                    PasteboardWriter.write(png: image.png)
                    let size = "\(MarkdownBuilder.number(image.widthPt))×\(MarkdownBuilder.number(image.heightPt))"
                    finishOneShot(HudText.plain(optionHeld ? "Snapped · \(size) · clipboard only" : "Snapped · \(size)"), near: crop)
                case .text:
                    let lines = try await OCR.text(inPNG: image.png)
                    guard !lines.isEmpty else {
                        finishOneShot(HudText.plain("No text found"), near: crop)
                        return
                    }
                    PasteboardWriter.write(string: lines.joined(separator: "\n"))
                    finishOneShot(HudText.plain("Copied · \(lines.count) \(lines.count == 1 ? "line" : "lines")"), near: crop)
                case .cut:
                    let normalized = CGPoint(x: (point.x - crop.minX) / crop.width, y: (point.y - crop.minY) / crop.height)
                    let subject = try await Cutout.subject(inPNG: image.png, at: normalized, wholeRegion: fromRegion)
                    guard let subject else {
                        finishOneShot(HudText.plain("No subject found"), near: crop)
                        return
                    }
                    if !optionHeld {
                        try store.writeImage(png: subject, fileName: Cutout.fileName(appName: appName, id: id), appName: appName, tag: "cut")
                    }
                    PasteboardWriter.write(png: subject)
                    finishOneShot(HudText.plain(optionHeld ? "Cut · clipboard only" : "Cut"), near: crop)
                case .point:
                    reset()
                }
            } catch {
                fail(.captureFailed(error), nearRect: crop)
            }
        }
    }

    private func finishOneShot(_ text: NSAttributedString, near rect: CGRect) {
        reset()
        toast.show(text, near: rect)
    }

    /// R6/R7/R8: only Enter writes. Files first, clipboard last.
    private func commit(note: String) {
        guard phase == .noting, let context, let cropTask else { return }
        phase = .writing
        let element = lockedElement
        let elements = lockedElements
        let nearby = lockedNearby
        let anchor = element?.frame.cgRect ?? SelectionOverlay.fallbackRect(around: clickPoint)
        let signals = ModeClassifier.signals(for: context, myApps: preferences.myApps, userTeamIDs: userTeamIDs)
        let store = FileStore(directory: preferences.captureFolderURL, organization: preferences.organization)
        Task {
            do {
                let image = try await cropTask.value
                // v0.3 R17: fix or reference, and the project root, from signals; touches the disk.
                // v0.4 R33: remember HEAD so Verify can diff against it later.
                let (decision, head) = await Task.detached { () -> (ModeDecision, String?) in
                    let decision = ModeInference.infer(signals)
                    return (decision, decision.projectRoot.flatMap(GitFacts.head(at:)))
                }.value
                var source = context.source
                source.projectRoot = decision.projectRoot
                source.gitCommit = head
                let now = Date()
                var capture = Capture(
                    id: FileStore.makeID(date: now),
                    createdAt: FileStore.isoTimestamp(date: now),
                    mode: decision.mode,
                    image: ImageInfo(path: "", widthPt: image.widthPt, heightPt: image.heightPt, scale: image.scale, crop: Frame(image.crop)),
                    source: source,
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
        toast.hide()
        cropTask?.cancel()
        reset()
    }

    private func reset() {
        phase = .idle
        action = .point
        clipboardOnlyPreset = false
        overlay.mode = .point
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
        let folder = preferences.captureFolderURL
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }
}
