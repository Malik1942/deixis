import AppKit

/// PRD §6.2 tokens mapped to system constants. Nothing here is a value of our own.
@MainActor
enum DesignTokens {
    static var dim: NSColor { NSColor.black.withAlphaComponent(0.20) }
    static var highlightStroke: NSColor { .controlAccentColor }
    static var highlightFallback: NSColor { .secondaryLabelColor }
    static let strokeWidth: CGFloat = 2
    static let highlightRadius: CGFloat = 6
    static let labelRadius: CGFloat = 6
    static let spaceS: CGFloat = 4
    static let spaceM: CGFloat = 8
    static let spaceL: CGFloat = 12
    static let fieldMinWidth: CGFloat = 320
    static let reveal: TimeInterval = 0.200
    static let dismiss: TimeInterval = 0.120
    static let hover: TimeInterval = 0.080
    static let toastLife: TimeInterval = 1.000
    static var mono: NSFont { .monospacedSystemFont(ofSize: 11, weight: .regular) }
    static var sans: NSFont { .systemFont(ofSize: 12) }
    /// Labels flip above the element when its bottom is within this distance of the screen bottom.
    static let flipMargin: CGFloat = 40
}

/// What the hover label says about the element under the cursor: `role · identifier`, with the
/// identifier in mono and any caveat in the secondary color. Tells identifier quality before the click.
struct Readout: Equatable, Sendable {
    var role: String
    var identifier: String?
    var suffix: String?
    var isFallback: Bool

    static func describing(_ element: ResolvedElement?) -> Readout {
        guard let element else {
            return Readout(role: "no element info", identifier: nil, suffix: "image only", isFallback: true)
        }
        if element.role == ElementResolver.clusterRole {
            return Readout(role: "cluster", identifier: nil, suffix: "\(element.members?.count ?? 0) elements", isFallback: false)
        }
        var role = element.role
        if element.identifier == nil, let label = element.label {
            role += " \"\(label)\""
        }
        let suffix: String? = switch (element.identifier, element.identifierSource) {
        case (nil, _): "no identifier"
        case (_, .possiblySymbolName): "may be a symbol name"
        default: nil
        }
        return Readout(role: role, identifier: element.identifier, suffix: suffix, isFallback: false)
    }
}

/// Attributed strings for hud surfaces, built from the tokens.
@MainActor
enum HudText {
    static func readout(_ r: Readout) -> NSAttributedString {
        let s = NSMutableAttributedString(string: r.role, attributes: sansAttributes)
        if let identifier = r.identifier {
            s.append(NSAttributedString(string: " · ", attributes: sansAttributes))
            s.append(NSAttributedString(string: identifier, attributes: monoAttributes))
        }
        if let suffix = r.suffix {
            s.append(NSAttributedString(string: " · ", attributes: sansAttributes))
            s.append(NSAttributedString(string: suffix, attributes: secondaryAttributes))
        }
        return s
    }

    static func copied(identifier: String?) -> NSAttributedString {
        let s = NSMutableAttributedString(string: "Copied", attributes: sansAttributes)
        if let identifier {
            s.append(NSAttributedString(string: " · ", attributes: sansAttributes))
            s.append(NSAttributedString(string: identifier, attributes: monoAttributes))
        }
        return s
    }

    static func plain(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: sansAttributes)
    }

    static var sansAttributes: [NSAttributedString.Key: Any] {
        [.font: DesignTokens.sans, .foregroundColor: NSColor.labelColor]
    }
    static var monoAttributes: [NSAttributedString.Key: Any] {
        [.font: DesignTokens.mono, .foregroundColor: NSColor.labelColor]
    }
    static var secondaryAttributes: [NSAttributedString.Key: Any] {
        [.font: DesignTokens.sans, .foregroundColor: NSColor.secondaryLabelColor]
    }
}

/// R2: one transparent, non-activating panel per screen over the live desktop. Reports hover and
/// click points in CG (accessibility) coordinates; draws highlight, label, and the note field.
/// R22: what the overlay is open for. Point is the default; the one-shot actions reuse the gesture.
enum OverlayMode: Equatable {
    case point, snap, text, cut

    var cursor: NSCursor {
        switch self {
        case .point, .text: .pointingHand
        case .snap, .cut: .crosshair
        }
    }
}

@MainActor
final class SelectionOverlay {
    var mode: OverlayMode = .point
    var onHover: ((CGPoint) -> Void)?
    var onClick: ((CGPoint) -> Void)?
    var onCancel: (() -> Void)?
    var onCommit: ((String) -> Void)?
    /// Option pressed while hovering: step the selection to the parent.
    var onOptionPressed: (() -> Void)?
    /// A drawn frame (CG points) and the drag's start point, for the window hit-test.
    var onRegion: ((CGRect, CGPoint) -> Void)?

    private var panels: [OverlayPanel] = []
    private var dismissing: [OverlayPanel] = []
    private(set) var primaryHeight: CGFloat = 0
    private var cursorPushed = false

    var isShowing: Bool { !panels.isEmpty }

    func show() {
        guard panels.isEmpty else { return }
        primaryHeight = Self.currentPrimaryHeight()
        panels = NSScreen.screens.map { screen in
            let panel = OverlayPanel(screen: screen)
            panel.contentOverlay.owner = self
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            return panel
        }
        panels.first?.makeKey()
        panels.first?.makeFirstResponder(panels.first?.contentOverlay)
        mode.cursor.push()
        cursorPushed = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for panel in panels { panel.animator().alphaValue = 1 }
        }
    }

    func dismiss() {
        guard !panels.isEmpty else { return }
        dismissing = panels
        panels = []
        if cursorPushed { NSCursor.pop(); cursorPushed = false }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.dismiss
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for panel in dismissing { panel.animator().alphaValue = 0 }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(DesignTokens.dismiss * 1000) + 20))
            for panel in self.dismissing { panel.orderOut(nil) }
            self.dismissing = []
        }
    }

    /// Highlights `frame` (CG points). A nil frame shows the fallback square around `point`.
    func setHighlight(_ frame: CGRect?, readout: Readout, around point: CGPoint) {
        let rect = Geometry.appKitRect(fromCG: frame ?? Self.fallbackRect(around: point), primaryHeight: primaryHeight)
        let target = panel(containing: rect)
        for panel in panels {
            if panel === target {
                panel.contentOverlay.showHighlight(screenRect: rect, readout: readout)
            } else {
                panel.contentOverlay.hideHighlight()
            }
        }
    }

    /// R6: the note field anchored to the element's bottom edge. The highlight stays.
    func showNoteField(anchoredTo frame: CGRect?, around point: CGPoint) {
        let rect = Geometry.appKitRect(fromCG: frame ?? Self.fallbackRect(around: point), primaryHeight: primaryHeight)
        guard let target = panel(containing: rect) else { return }
        for panel in panels { panel.contentOverlay.lock() }
        target.makeKey()
        target.contentOverlay.showNoteField(screenRect: rect)
    }

    // MARK: Called by the content views (AppKit screen coordinates)

    func hover(atAppKit point: CGPoint) {
        onHover?(Geometry.cgPoint(fromAppKit: point, primaryHeight: primaryHeight))
    }

    func click(atAppKit point: CGPoint) {
        onClick?(Geometry.cgPoint(fromAppKit: point, primaryHeight: primaryHeight))
    }

    func region(atAppKit rect: CGRect, start: CGPoint) {
        onRegion?(Geometry.cgRect(fromAppKit: rect, primaryHeight: primaryHeight),
                  Geometry.cgPoint(fromAppKit: start, primaryHeight: primaryHeight))
    }

    /// R12: 1 pt marks on every element kept inside the drawn frame (CG rects).
    func showMarks(_ frames: [CGRect]) {
        let rects = frames.map { Geometry.appKitRect(fromCG: $0, primaryHeight: primaryHeight) }
        for panel in panels { panel.contentOverlay.showMarks(rects) }
    }

    // MARK: Screen helpers

    static func currentPrimaryHeight() -> CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    /// CG-space frame of the display containing `point`.
    static func displayFrameCG(containing point: CGPoint) -> CGRect {
        let primaryHeight = currentPrimaryHeight()
        let frames = NSScreen.screens.map { Geometry.cgRect(fromAppKit: $0.frame, primaryHeight: primaryHeight) }
        return frames.first { $0.contains(point) } ?? frames.first ?? .zero
    }

    static func fallbackRect(around point: CGPoint) -> CGRect {
        let side = Geometry.fallbackCropSide
        return CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
    }

    private func panel(containing rect: CGRect) -> OverlayPanel? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return panels.first { $0.frame.contains(center) } ?? panels.first
    }
}

// MARK: - Panel

final class OverlayPanel: NSPanel {
    let contentOverlay: OverlayContentView

    init(screen: NSScreen) {
        contentOverlay = OverlayContentView(frame: NSRect(origin: .zero, size: screen.frame.size))
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .screenSaver
        isOpaque = false
        backgroundColor = DesignTokens.dim
        hasShadow = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        acceptsMouseMovedEvents = true
        contentView = contentOverlay
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Content view

final class OverlayContentView: NSView, NSTextFieldDelegate {
    weak var owner: SelectionOverlay?

    private let highlight = HighlightView()
    private let label = HudLabel()
    private var noteField: NoteFieldView?
    private var trackingArea: NSTrackingArea?
    private var locked = false

    // R11 region gesture
    private static let dragThreshold: CGFloat = 6
    private var dragStart: CGPoint?
    private var isDragging = false
    private let marquee = HighlightView()
    private let sizeLabel = HudLabel()
    private var marks: [HighlightView] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        highlight.isHidden = true
        label.isHidden = true
        addSubview(highlight)
        addSubview(label)
        marquee.cornerRadius = 0
        marquee.isHidden = true
        sizeLabel.isHidden = true
        addSubview(marquee)
        addSubview(sizeLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: owner?.mode.cursor ?? .pointingHand)
    }

    override func mouseMoved(with event: NSEvent) {
        guard !locked, let window else { return }
        owner?.hover(atAppKit: window.convertPoint(toScreen: event.locationInWindow))
    }

    override func mouseDown(with event: NSEvent) {
        guard !locked else { return }
        dragStart = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !locked, let start = dragStart else { return }
        let point = event.locationInWindow
        if !isDragging {
            guard hypot(point.x - start.x, point.y - start.y) > Self.dragThreshold else { return }
            isDragging = true
            highlight.isHidden = true
            label.isHidden = true
            marquee.isHidden = false
            sizeLabel.isHidden = false
        }
        let rect = Self.normalized(start, point)
        marquee.frame = rect
        marquee.needsDisplay = true
        sizeLabel.set(HudText.plain("\(Int(rect.width.rounded())) × \(Int(rect.height.rounded())) pt"))
        sizeLabel.frame = anchoredFrame(size: sizeLabel.hudSize, below: rect)
    }

    override func mouseUp(with event: NSEvent) {
        guard !locked, let window, let start = dragStart else { return }
        dragStart = nil
        if isDragging {
            isDragging = false
            sizeLabel.isHidden = true
            let rect = Self.normalized(start, event.locationInWindow)
            guard rect.width >= 2, rect.height >= 2 else { marquee.isHidden = true; return }
            let screenRect = window.convertToScreen(convert(rect, to: nil))
            owner?.region(atAppKit: screenRect, start: window.convertPoint(toScreen: start))
        } else {
            owner?.click(atAppKit: window.convertPoint(toScreen: event.locationInWindow))
        }
    }

    private static func normalized(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    func showMarks(_ screenRects: [CGRect]) {
        guard let window else { return }
        marks.forEach { $0.removeFromSuperview() }
        marks = screenRects.map { rect in
            let mark = HighlightView()
            mark.isFallback = true
            mark.strokeWidth = 1
            mark.cornerRadius = 3
            mark.frame = convert(window.convertFromScreen(rect), from: nil)
            addSubview(mark)
            return mark
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            owner?.onCancel?()
        }
    }

    private var optionWasDown = false

    override func flagsChanged(with event: NSEvent) {
        let optionDown = event.modifierFlags.contains(.option)
        defer { optionWasDown = optionDown }
        if optionDown, !optionWasDown, !locked {
            owner?.onOptionPressed?()
        }
    }

    func lock() { locked = true }

    func showHighlight(screenRect: CGRect, readout: Readout) {
        guard let window else { return }
        let local = convert(window.convertFromScreen(screenRect), from: nil)
        highlight.isFallback = readout.isFallback
        label.set(HudText.readout(readout))
        let labelFrame = anchoredFrame(size: label.hudSize, below: local)

        let wasHidden = highlight.isHidden
        highlight.isHidden = false
        label.isHidden = noteField != nil
        if wasHidden {
            highlight.frame = local
            label.frame = labelFrame
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = DesignTokens.hover
                highlight.animator().frame = local
                label.animator().frame = labelFrame
            }
        }
        highlight.needsDisplay = true
    }

    func hideHighlight() {
        highlight.isHidden = true
        label.isHidden = true
    }

    func showNoteField(screenRect: CGRect) {
        guard let window, noteField == nil else { return }
        locked = true
        label.isHidden = true
        sizeLabel.isHidden = true
        let local = convert(window.convertFromScreen(screenRect), from: nil)
        let size = CGSize(width: max(local.width, DesignTokens.fieldMinWidth), height: NoteFieldView.height)
        let field = NoteFieldView(frame: anchoredFrame(size: size, below: local))
        field.textField.delegate = self
        field.alphaValue = 0
        addSubview(field)
        noteField = field
        window.makeFirstResponder(field.textField)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            field.animator().alphaValue = 1
        }
    }

    /// 8 pt below the element, or above it when within 40 pt of the screen bottom; kept on screen.
    private func anchoredFrame(size: CGSize, below rect: CGRect) -> CGRect {
        var origin = CGPoint(x: rect.minX, y: rect.minY - DesignTokens.spaceM - size.height)
        if rect.minY < DesignTokens.flipMargin {
            origin.y = rect.maxY + DesignTokens.spaceM
        }
        origin.x = min(max(origin.x, DesignTokens.spaceM), bounds.width - size.width - DesignTokens.spaceM)
        origin.y = min(max(origin.y, DesignTokens.spaceM), bounds.height - size.height - DesignTokens.spaceM)
        return CGRect(origin: origin, size: size)
    }

    // MARK: NSTextFieldDelegate

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            owner?.onCommit?(noteField?.textField.stringValue ?? "")
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            owner?.onCancel?()
            return true
        }
        return false
    }
}

// MARK: - Highlight

/// `highlight.stroke` at `highlight.radius`, no fill; dashed `highlight.fallback` for the no-element state.
final class HighlightView: NSView {
    var isFallback = false { didSet { needsDisplay = true } }
    var cornerRadius: CGFloat = DesignTokens.highlightRadius
    var strokeWidth: CGFloat = DesignTokens.strokeWidth

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .duringViewResize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draw(_ dirtyRect: NSRect) {
        let inset = bounds.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)
        let path = NSBezierPath(roundedRect: inset, xRadius: cornerRadius, yRadius: cornerRadius)
        path.lineWidth = strokeWidth
        if isFallback {
            path.setLineDash([6, 4], count: 2, phase: 0)
            DesignTokens.highlightFallback.setStroke()
        } else {
            DesignTokens.highlightStroke.setStroke()
        }
        path.stroke()
    }
}

// MARK: - Hud label

/// `label.bg`: hud material with a 6 pt radius, `space.m` / `space.s` padding.
final class HudLabel: NSVisualEffectView {
    private let text = NSTextField(labelWithString: "")
    private let maxTextWidth: CGFloat = 480

    init() {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.labelRadius
        layer?.masksToBounds = true
        text.maximumNumberOfLines = 1
        text.lineBreakMode = .byTruncatingMiddle
        addSubview(text)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func set(_ string: NSAttributedString) {
        text.attributedStringValue = string
        text.sizeToFit()
        if text.frame.width > maxTextWidth {
            text.frame.size.width = maxTextWidth
        }
        text.frame.origin = CGPoint(x: DesignTokens.spaceM, y: DesignTokens.spaceS)
    }

    var hudSize: CGSize {
        CGSize(width: text.frame.width + 2 * DesignTokens.spaceM, height: text.frame.height + 2 * DesignTokens.spaceS)
    }

    /// Pill shape for toasts.
    func makePill() {
        layer?.cornerRadius = hudSize.height / 2
    }
}

// MARK: - Note field

/// PRD note-field spec: `field.width`, `label.bg`, `label.sans`, placeholder "What should change?",
/// right-aligned hint in the secondary color.
final class NoteFieldView: NSVisualEffectView {
    static let height: CGFloat = 28
    let textField = NSTextField()
    private let hint = NSTextField(labelWithString: "↩ copy · esc cancel")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.labelRadius
        layer?.masksToBounds = true

        hint.font = DesignTokens.sans
        hint.textColor = .secondaryLabelColor
        hint.sizeToFit()
        hint.frame.origin = CGPoint(
            x: frameRect.width - hint.frame.width - DesignTokens.spaceM,
            y: (frameRect.height - hint.frame.height) / 2
        )
        addSubview(hint)

        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = DesignTokens.sans
        textField.textColor = .labelColor
        textField.placeholderString = "What should change?"
        textField.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        let fieldHeight: CGFloat = 17
        textField.frame = CGRect(
            x: DesignTokens.spaceM,
            y: (frameRect.height - fieldHeight) / 2,
            width: hint.frame.minX - DesignTokens.spaceM * 2,
            height: fieldHeight
        )
        addSubview(textField)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

// MARK: - Toast

/// PRD toast spec: a pill on `label.bg` near where the element was, `toast.life`, then `motion.dismiss`.
@MainActor
final class Toast {
    private var panel: NSPanel?
    private var generation = 0

    /// `anchor` is in CG points; the pill sits just below it (above when near the screen bottom).
    func show(_ text: NSAttributedString, near anchor: CGRect) {
        panel?.orderOut(nil)
        generation += 1
        let current = generation

        let label = HudLabel()
        label.set(text)
        let size = label.hudSize
        label.frame = CGRect(origin: .zero, size: size)
        label.makePill()

        let primaryHeight = SelectionOverlay.currentPrimaryHeight()
        let rect = Geometry.appKitRect(fromCG: anchor, primaryHeight: primaryHeight)
        let screen = NSScreen.screens.first { $0.frame.contains(CGPoint(x: rect.midX, y: rect.midY)) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? rect
        var origin = CGPoint(x: rect.midX - size.width / 2, y: rect.minY - DesignTokens.spaceM - size.height)
        if origin.y < bounds.minY + DesignTokens.flipMargin {
            origin.y = rect.maxY + DesignTokens.spaceM
        }
        origin.x = min(max(origin.x, bounds.minX + DesignTokens.spaceM), bounds.maxX - size.width - DesignTokens.spaceM)
        origin.y = min(max(origin.y, bounds.minY + DesignTokens.spaceM), bounds.maxY - size.height - DesignTokens.spaceM)

        let toastPanel = NSPanel(contentRect: CGRect(origin: origin, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        toastPanel.level = .screenSaver
        toastPanel.isOpaque = false
        toastPanel.backgroundColor = .clear
        toastPanel.hasShadow = false
        toastPanel.ignoresMouseEvents = true
        toastPanel.hidesOnDeactivate = false
        toastPanel.isReleasedWhenClosed = false
        toastPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        toastPanel.contentView = label
        toastPanel.alphaValue = 0
        toastPanel.orderFrontRegardless()
        panel = toastPanel

        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.reveal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            toastPanel.animator().alphaValue = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(DesignTokens.toastLife))
            guard self.generation == current, let panel = self.panel else { return }
            await NSAnimationContext.runAnimationGroup { context in
                context.duration = DesignTokens.dismiss
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().alphaValue = 0
            }
            guard self.generation == current else { return }
            self.panel?.orderOut(nil)
            self.panel = nil
        }
    }
}
