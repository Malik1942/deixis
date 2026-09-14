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

    struct WindowRecord: Sendable, Equatable, Codable {
        var ownerPID: pid_t
        var layer: Int
        var bounds: CGRect
    }

    /// Topmost normal-layer window under `point`, skipping Deixis's own. `windows` is front to back.
    /// This is what Snap and Cut take on a click, and the crop clamp when no element answered.
    static func windowOwner(at point: CGPoint, windows: [WindowRecord], excludingPID: pid_t) -> WindowRecord? {
        windows.first { $0.layer == 0 && $0.ownerPID != excludingPID && $0.bounds.contains(point) }
    }

    /// Every on-screen window under `point` in any layer, front to back, skipping Deixis's own. The
    /// first is what the user sees there; the ones behind it matter only when its owner reports
    /// nothing at the point. The Dock, the menu bar, and the Finder desktop each own a screen-wide
    /// window that is mostly empty, so a desktop icon, a widget, or a status item is reached by
    /// asking each owner in turn (see `AccessibilityReader.snapshot(at:candidates:fallbackPID:)`).
    static func windowCandidates(at point: CGPoint, windows: [WindowRecord], excludingPID: pid_t) -> [WindowRecord] {
        windows.filter { $0.ownerPID != excludingPID && $0.bounds.contains(point) }
    }
}
