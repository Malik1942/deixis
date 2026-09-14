import AppKit

/// R25: the color-picking session. A clear panel per screen catches clicks and keys; the magnifier
/// panel (PRD §6.3 "Color magnifier") follows the cursor with no smoothing and shows 15×15 native
/// pixels at 10x from a cached display image (own windows excluded, refreshed every half second).
@MainActor
final class ColorPickerSession {
    enum Tokens {
        static let pixels = 15
        static let zoom: CGFloat = 10
        static let panelSize: CGFloat = 150
        static let valueHeight: CGFloat = 24
        static let cursorOffset: CGFloat = 20
        static let refresh: Duration = .milliseconds(500)
    }

    var onPick: ((ColorValue) -> Void)?
    var onCancel: (() -> Void)?

    private let space: ColorSpaceChoice
    private let format: ColorFormat
    private var catchers: [OverlayPanel] = []
    private let magnifier: NSPanel
    private let magnifierView: MagnifierView
    private var display: (image: CGImage, frame: CGRect, scale: CGFloat)?
    private var refreshTask: Task<Void, Never>?
    private var nudge = CGPoint.zero
    private var lastCursor = CGPoint.zero
    private var primaryHeight: CGFloat = 0

    init(space: ColorSpaceChoice, format: ColorFormat) {
        self.space = space
        self.format = format
        let size = NSSize(width: Tokens.panelSize, height: Tokens.panelSize + Tokens.valueHeight)
        magnifier = NSPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        magnifier.level = .screenSaver
        magnifier.isOpaque = false
        magnifier.backgroundColor = .clear
        magnifier.hasShadow = false
        magnifier.ignoresMouseEvents = true
        magnifier.hidesOnDeactivate = false
        magnifier.isReleasedWhenClosed = false
        magnifier.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        magnifierView = MagnifierView(frame: NSRect(origin: .zero, size: size))
        magnifier.contentView = magnifierView
    }

    func start() {
        primaryHeight = SelectionOverlay.currentPrimaryHeight()
        catchers = NSScreen.screens.map { screen in
            let panel = OverlayPanel(screen: screen)
            panel.backgroundColor = .clear
            panel.contentOverlay.picker = self
            panel.orderFrontRegardless()
            return panel
        }
        catchers.first?.makeKey()
        catchers.first?.makeFirstResponder(catchers.first?.contentOverlay)
        NSCursor.crosshair.push()
        magnifier.orderFrontRegardless()
        refreshTask = Task { @MainActor in
            while !Task.isCancelled {
                await self.refreshDisplay()
                self.render()
                try? await Task.sleep(for: Tokens.refresh)
            }
        }
        cursorMoved(NSEvent.mouseLocation)
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        NSCursor.pop()
        magnifier.orderOut(nil)
        for panel in catchers { panel.orderOut(nil) }
        catchers = []
    }

    // MARK: Input (from the catcher views, AppKit screen coordinates)

    func cursorMoved(_ point: CGPoint) {
        lastCursor = point
        nudge = .zero
        positionMagnifier(near: point)
        render()
    }

    func nudgeBy(dx: Int, dy: Int) {
        nudge.x += CGFloat(dx)
        nudge.y += CGFloat(dy)
        render()
    }

    func clicked() {
        if let color = currentColor() { onPick?(color) } else { onCancel?() }
    }

    func cancelled() {
        onCancel?()
    }

    // MARK: Sampling

    private func refreshDisplay() async {
        let cg = Geometry.cgPoint(fromAppKit: lastCursor, primaryHeight: primaryHeight)
        if let fresh = try? await ScreenCapture.displayImage(containing: cg) {
            display = fresh
        }
    }

    /// The sample point in display pixels, with the arrow-key nudge applied.
    private func samplePixel() -> (x: Int, y: Int)? {
        guard let display else { return nil }
        let cg = Geometry.cgPoint(fromAppKit: lastCursor, primaryHeight: primaryHeight)
        let local = Geometry.displayLocalRect(CGRect(origin: cg, size: .zero), inDisplay: display.frame).origin
        return (Int((local.x * display.scale).rounded(.down)) + Int(nudge.x), Int((local.y * display.scale).rounded(.down)) + Int(nudge.y))
    }

    private func currentColor() -> ColorValue? {
        guard let display, let pixel = samplePixel() else { return nil }
        return ColorPicker.pixel(in: display.image, x: pixel.x, y: pixel.y, space: space)
    }

    private func render() {
        guard let display, let pixel = samplePixel() else { return }
        let half = Tokens.pixels / 2
        let rect = CGRect(x: pixel.x - half, y: pixel.y - half, width: Tokens.pixels, height: Tokens.pixels)
        let patch = display.image.cropping(to: rect.intersection(CGRect(x: 0, y: 0, width: display.image.width, height: display.image.height)))
        let value = currentColor().map { ColorPicker.format($0, as: format) } ?? ""
        magnifierView.update(patch: patch, offset: CGPoint(x: max(0, -rect.minX), y: max(0, -rect.minY)), value: value)
    }

    private func positionMagnifier(near point: CGPoint) {
        let size = magnifier.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .zero
        var origin = CGPoint(x: point.x + Tokens.cursorOffset, y: point.y - Tokens.cursorOffset - size.height)
        if origin.x + size.width > bounds.maxX { origin.x = point.x - Tokens.cursorOffset - size.width }
        if origin.y < bounds.minY { origin.y = point.y + Tokens.cursorOffset }
        magnifier.setFrameOrigin(origin)
    }
}

/// 15×15 native pixels at 10x on `label.bg`, a 1 px `separatorColor` grid, the center pixel
/// outlined with `highlight.stroke`, the value in `label.mono` beneath.
final class MagnifierView: NSView {
    private let material = NSVisualEffectView()
    private let grid = PixelGridView()
    private let value = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.labelRadius
        layer?.masksToBounds = true
        material.material = .hudWindow
        material.blendingMode = .behindWindow
        material.state = .active
        material.frame = bounds
        material.autoresizingMask = [.width, .height]
        addSubview(material)
        grid.frame = NSRect(x: 0, y: ColorPickerSession.Tokens.valueHeight, width: frameRect.width, height: frameRect.width)
        addSubview(grid)
        value.font = DesignTokens.mono
        value.textColor = .labelColor
        value.alignment = .center
        value.frame = NSRect(x: 0, y: 4, width: frameRect.width, height: ColorPickerSession.Tokens.valueHeight - 8)
        addSubview(value)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(patch: CGImage?, offset: CGPoint, value text: String) {
        grid.patch = patch
        grid.offset = offset
        grid.needsDisplay = true
        value.stringValue = text
    }
}

/// The zoomed pixels, grid, and center outline. A separate view so it paints above the material.
final class PixelGridView: NSView {
    var patch: CGImage?
    var offset = CGPoint.zero

    override func draw(_ dirtyRect: NSRect) {
        let zoom = ColorPickerSession.Tokens.zoom
        let pixels = ColorPickerSession.Tokens.pixels
        let area = bounds
        if let patch, let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.interpolationQuality = .none
            // Image rows run top-down; the view is bottom-up. Place the patch by its offset inside the grid.
            let drawn = CGRect(
                x: area.minX + offset.x * zoom,
                y: area.maxY - (offset.y + CGFloat(patch.height)) * zoom,
                width: CGFloat(patch.width) * zoom,
                height: CGFloat(patch.height) * zoom
            )
            context.draw(patch, in: drawn)
            context.restoreGState()
        }
        NSColor.separatorColor.setStroke()
        let lines = NSBezierPath()
        lines.lineWidth = 1
        for i in 0...pixels {
            let x = area.minX + CGFloat(i) * zoom + 0.5
            lines.move(to: NSPoint(x: x, y: area.minY)); lines.line(to: NSPoint(x: x, y: area.maxY))
            let y = area.minY + CGFloat(i) * zoom + 0.5
            lines.move(to: NSPoint(x: area.minX, y: y)); lines.line(to: NSPoint(x: area.maxX, y: y))
        }
        lines.stroke()
        let center = NSRect(x: area.minX + CGFloat(pixels / 2) * zoom, y: area.minY + CGFloat(pixels / 2) * zoom, width: zoom, height: zoom)
        NSColor.controlAccentColor.setStroke()
        let outline = NSBezierPath(rect: center.insetBy(dx: -1, dy: -1))
        outline.lineWidth = DesignTokens.strokeWidth
        outline.stroke()
    }
}
