import CoreGraphics
import Foundation

/// Pure coordinate functions. Three spaces meet here:
/// - AppKit: bottom-left origin at the primary display, points. `NSEvent.mouseLocation`, `NSScreen.frame`.
/// - CG / AX: top-left origin at the primary display, points. Accessibility frames, `CGWindowList`
///   bounds, `SCDisplay.frame` all share this space.
/// - Display-local pixels: origin at one display's top-left, scaled by its backing factor.
enum Geometry {
    static let cropPadding: Double = 40
    static let fallbackCropSide: Double = 120

    // MARK: AppKit ↔ CG

    static func cgPoint(fromAppKit p: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    static func appKitPoint(fromCG p: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    static func cgRect(fromAppKit r: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    static func appKitRect(fromCG r: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    // MARK: Crop (R4)

    /// Element frame plus padding, clamped to the target window and then to the display.
    /// Without an element: a square around the click point plus the same padding.
    static func cropRect(
        element: CGRect?,
        clickPoint: CGPoint,
        window: CGRect?,
        display: CGRect,
        padding: Double = cropPadding
    ) -> CGRect {
        let base = element ?? CGRect(
            x: clickPoint.x - fallbackCropSide / 2,
            y: clickPoint.y - fallbackCropSide / 2,
            width: fallbackCropSide,
            height: fallbackCropSide
        )
        var rect = base.insetBy(dx: -padding, dy: -padding)
        if let window {
            let clamped = rect.intersection(window)
            if !clamped.isEmpty { rect = clamped }
        }
        let onDisplay = rect.intersection(display)
        return onDisplay.isEmpty ? display : onDisplay.integral
    }

    /// CG-space rect → the same rect relative to one display's top-left, in points.
    static func displayLocalRect(_ r: CGRect, inDisplay display: CGRect) -> CGRect {
        r.offsetBy(dx: -display.minX, dy: -display.minY)
    }

    /// CG-space rect → display-local pixels.
    static func pixelRect(_ r: CGRect, inDisplay display: CGRect, scale: CGFloat) -> CGRect {
        let local = displayLocalRect(r, inDisplay: display)
        return CGRect(x: local.minX * scale, y: local.minY * scale, width: local.width * scale, height: local.height * scale)
    }

    // MARK: Window hit-test (R3)

    struct WindowRecord: Sendable, Equatable {
        var ownerPID: pid_t
        var layer: Int
        var bounds: CGRect
    }

    /// Topmost normal-layer window under `point`, skipping Deixis's own. `windows` is front to back.
    static func windowOwner(at point: CGPoint, windows: [WindowRecord], excludingPID: pid_t) -> WindowRecord? {
        windows.first { $0.layer == 0 && $0.ownerPID != excludingPID && $0.bounds.contains(point) }
    }
}
