import AppKit

/// v0.3 R20, PRD P1.11: the quiet second entry point. A 28 pt disc that rests nearly invisible,
/// docks to the nearest edge when ignored, wakes as the cursor approaches, and starts Point on
/// click. No ring in v0.3. Excluded from captures through the own-windows filter.
@MainActor
final class FloatingBall {
    enum State: Equatable { case rest, docked, awake, ready }

    enum Tokens {
        static let diameter: CGFloat = 28
        static let approach: CGFloat = 80
        static let dockDelay: TimeInterval = 5
        static let firstLaunchInset: CGFloat = 24
        static let restAlpha: CGFloat = 0.6
        static let dockedAlpha: CGFloat = 0.45
        static let restFill: Float = 0.10
        static let dockedFill: Float = 0.06
        static let glowLow: Float = 0.08
        static let glowHigh: Float = 0.14
        static let glowPeriod: TimeInterval = 6
        static let firstLaunchReveal: TimeInterval = 0.8
    }

    /// Click: start Point.
    var onPoint: (() -> Void)?
    /// The user dragged the ball; persist the new origin (AppKit screen points).
    var onMoved: ((CGPoint) -> Void)?
    /// A ring segment was chosen; `clipboardOnly` when ⌥ was held.
    var onAction: ((Ring.Segment, Bool) -> Void)?

    private let ring = Ring()
    private var holdTask: Task<Void, Never>?
    private(set) var ringOpen = false

    private let panel: NSPanel
    private let view: BallView
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private(set) var state: State = .rest
    private var freeOrigin: CGPoint
    private var dockTask: Task<Void, Never>?

    init(origin: CGPoint?) {
        let size = NSSize(width: Tokens.diameter, height: Tokens.diameter)
        let start = origin ?? Self.firstLaunchOrigin()
        freeOrigin = start
        panel = NSPanel(contentRect: NSRect(origin: start, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        view = BallView(frame: NSRect(origin: .zero, size: size))
        panel.contentView = view
        view.ball = self
    }

    static func firstLaunchOrigin() -> CGPoint {
        let frame = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
        return CGPoint(
            x: frame.maxX - Tokens.diameter - Tokens.firstLaunchInset,
            y: frame.minY + Tokens.firstLaunchInset
        )
    }

    func show(firstLaunch: Bool) {
        panel.alphaValue = 0
        view.apply(.rest, animated: false)
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = firstLaunch ? Tokens.firstLaunchReveal : DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = Tokens.restAlpha
        }
        startMonitors()
        scheduleDock()
    }

    func hide() {
        stopMonitors()
        dockTask?.cancel()
        dockTask = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.dismiss
            panel.animator().alphaValue = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(DesignTokens.dismiss * 1000) + 20))
            self.panel.orderOut(nil)
        }
    }

    // MARK: Proximity

    private func startMonitors() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            let point = NSEvent.mouseLocation
            MainActor.assumeIsolated { self?.cursorMoved(to: point) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            let point = NSEvent.mouseLocation
            MainActor.assumeIsolated { self?.cursorMoved(to: point) }
            return event
        }
    }

    private func stopMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func cursorMoved(to point: CGPoint) {
        guard !view.isDragging, !ringOpen else { return }
        let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
        let distance = hypot(point.x - center.x, point.y - center.y)
        if distance <= Tokens.diameter / 2 + 4 {
            set(.ready)
        } else if distance <= Tokens.approach {
            set(.awake)
        } else if state == .awake || state == .ready {
            set(.rest)
        }
    }

    private func set(_ newState: State) {
        guard newState != state else { return }
        let wasDocked = state == .docked
        state = newState
        switch newState {
        case .awake, .ready:
            dockTask?.cancel()
            if wasDocked { move(to: freeOrigin) }
            fade(to: 1)
            view.apply(newState, animated: true)
        case .rest:
            fade(to: Tokens.restAlpha)
            view.apply(.rest, animated: true)
            scheduleDock()
        case .docked:
            fade(to: Tokens.dockedAlpha)
            view.apply(.docked, animated: true)
        }
    }

    private func fade(to alpha: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = alpha
        }
    }

    // MARK: Docking

    private func scheduleDock() {
        dockTask?.cancel()
        dockTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Tokens.dockDelay))
            guard !Task.isCancelled, self.state == .rest, !self.view.isDragging else { return }
            self.dock()
        }
    }

    /// Slide half off the nearest screen edge (left, right, or bottom).
    private func dock() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let frame = screen.frame
        let half = Tokens.diameter / 2
        let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
        let candidates: [(distance: CGFloat, origin: CGPoint)] = [
            (center.x - frame.minX, CGPoint(x: frame.minX - half, y: freeOrigin.y)),
            (frame.maxX - center.x, CGPoint(x: frame.maxX - half, y: freeOrigin.y)),
            (center.y - frame.minY, CGPoint(x: freeOrigin.x, y: frame.minY - half)),
        ]
        guard let nearest = candidates.min(by: { $0.distance < $1.distance }) else { return }
        set(.docked)
        move(to: nearest.origin)
    }

    private func move(to origin: CGPoint) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(origin)
        }
    }

    // MARK: From the view

    func clicked() {
        onPoint?()
    }

    /// R27: mouse down starts the hold; 300 ms without a drag opens the ring.
    func pressBegan() {
        holdTask?.cancel()
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Ring.Tokens.holdDelay))
            guard !Task.isCancelled, !self.view.isDragging else { return }
            self.ringOpen = true
            self.dockTask?.cancel()
            self.ring.open(at: CGPoint(x: self.panel.frame.midX, y: self.panel.frame.midY))
        }
    }

    func pressMoved(to point: CGPoint) {
        guard ringOpen else { return }
        ring.hover(at: point, optionHeld: NSEvent.modifierFlags.contains(.option))
    }

    /// Returns true when the release was handled by the ring (chosen or cancelled).
    func pressEnded(at point: CGPoint) -> Bool {
        holdTask?.cancel()
        holdTask = nil
        guard ringOpen else { return false }
        ringOpen = false
        let chosen = ring.hover(at: point, optionHeld: false)
        let optionHeld = NSEvent.modifierFlags.contains(.option)
        ring.close()
        if let chosen { onAction?(chosen, optionHeld && chosen.acceptsClipboardOnly) }
        scheduleDock()
        return true
    }

    func dragged(by delta: CGPoint) {
        let origin = CGPoint(x: panel.frame.origin.x + delta.x, y: panel.frame.origin.y + delta.y)
        panel.setFrameOrigin(origin)
        freeOrigin = origin
        if state == .docked { state = .rest }
    }

    func dragEnded() {
        onMoved?(freeOrigin)
        set(.rest)
        scheduleDock()
    }
}

/// The disc: hud material, `labelColor` fill with the slow glow, 1 px `separatorColor` edge that
/// turns accent when ready, the pointing hand fading in when awake.
final class BallView: NSView {
    weak var ball: FloatingBall?
    private(set) var isDragging = false
    private var dragStart: CGPoint?
    private var dragMoved = false
    private var current: FloatingBall.State = .rest

    private let material = NSVisualEffectView()
    private let fill = CALayer()
    private let icon = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = frameRect.width / 2
        layer?.masksToBounds = true

        material.material = .hudWindow
        material.blendingMode = .behindWindow
        material.state = .active
        material.frame = bounds
        material.autoresizingMask = [.width, .height]
        addSubview(material)

        fill.frame = bounds
        fill.opacity = FloatingBall.Tokens.restFill
        layer?.addSublayer(fill)

        layer?.borderWidth = 1
        icon.frame = bounds.insetBy(dx: 6, dy: 6)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.alphaValue = 0
        if let image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "Point") {
            image.isTemplate = true
            icon.image = image
        }
        addSubview(icon)
        applyColors()
        startGlow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyColors()
    }

    private func applyColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            fill.backgroundColor = NSColor.labelColor.cgColor
            layer?.borderColor = current == .ready ? NSColor.controlAccentColor.cgColor : NSColor.separatorColor.cgColor
        }
    }

    /// `ball.glow`: fill drifts 8 → 14 → 8 percent over 6 s; off under Reduce Motion.
    private func startGlow() {
        fill.removeAnimation(forKey: "glow")
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        let glow = CAKeyframeAnimation(keyPath: "opacity")
        glow.values = [FloatingBall.Tokens.glowLow, FloatingBall.Tokens.glowHigh, FloatingBall.Tokens.glowLow]
        glow.keyTimes = [0, 0.5, 1]
        glow.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut), CAMediaTimingFunction(name: .easeInEaseOut)]
        glow.duration = FloatingBall.Tokens.glowPeriod
        glow.repeatCount = .infinity
        fill.add(glow, forKey: "glow")
    }

    func apply(_ state: FloatingBall.State, animated: Bool) {
        current = state
        let baseFill: Float = state == .docked ? FloatingBall.Tokens.dockedFill : FloatingBall.Tokens.restFill
        fill.opacity = baseFill
        if state == .docked || state == .rest { startGlow() } else { fill.removeAnimation(forKey: "glow") }
        applyColors()
        let showIcon: CGFloat = (state == .awake || state == .ready) ? 1 : 0
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = DesignTokens.reveal
                icon.animator().alphaValue = showIcon
            }
        } else {
            icon.alphaValue = showIcon
        }
        window?.invalidateCursorRects(for: self)
    }

    override func resetCursorRects() {
        if current == .ready { addCursorRect(bounds, cursor: .pointingHand) }
    }

    // MARK: Click and drag

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        dragMoved = false
        ball?.pressBegan()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let now = NSEvent.mouseLocation
        if ball?.ringOpen == true {
            ball?.pressMoved(to: now)
            return
        }
        if !dragMoved, hypot(now.x - start.x, now.y - start.y) <= 6 { return }
        dragMoved = true
        isDragging = true
        ball?.dragged(by: CGPoint(x: now.x - start.x, y: now.y - start.y))
        dragStart = now
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragStart = nil; isDragging = false }
        if ball?.pressEnded(at: NSEvent.mouseLocation) == true { return }
        if dragMoved {
            ball?.dragEnded()
        } else {
            ball?.clicked()
        }
    }
}
