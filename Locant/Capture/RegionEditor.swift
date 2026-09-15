import CoreGraphics

/// Settings "Adjust selection before capturing": after a rough drag the frame waits with eight
/// handles. Where a point falls on the frame, and the frame after a handle or the body moves.
/// Pure; the overlay draws and the reader never sees it. AppKit coordinates (y grows upward).
enum RegionEditor {
    enum Handle: CaseIterable, Equatable, Sendable {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

        var movesMinX: Bool { self == .topLeft || self == .left || self == .bottomLeft }
        var movesMaxX: Bool { self == .topRight || self == .right || self == .bottomRight }
        var movesMinY: Bool { self == .bottomLeft || self == .bottom || self == .bottomRight }
        var movesMaxY: Bool { self == .topLeft || self == .top || self == .topRight }
    }

    enum Hit: Equatable, Sendable {
        case handle(Handle), inside, outside
    }

    static let handleSize: CGFloat = 8
    /// Extra points around a handle that still grab it.
    static let grabSlack: CGFloat = 6
    static let minimumSide: CGFloat = 2

    static func center(of handle: Handle, in rect: CGRect) -> CGPoint {
        let x = handle.movesMinX ? rect.minX : (handle.movesMaxX ? rect.maxX : rect.midX)
        let y = handle.movesMinY ? rect.minY : (handle.movesMaxY ? rect.maxY : rect.midY)
        return CGPoint(x: x, y: y)
    }

    /// The nearest handle within reach, else inside or outside the frame.
    static func hit(_ point: CGPoint, in rect: CGRect) -> Hit {
        let reach = handleSize / 2 + grabSlack
        var best: (handle: Handle, distance: CGFloat)?
        for handle in Handle.allCases {
            let center = center(of: handle, in: rect)
            let distance = max(abs(point.x - center.x), abs(point.y - center.y))
            if distance <= reach, best.map({ distance < $0.distance }) ?? true {
                best = (handle, distance)
            }
        }
        if let best { return .handle(best.handle) }
        return rect.contains(point) ? .inside : .outside
    }

    /// `rect` with `handle` dragged by `delta` from where the drag began: opposite edges stay put,
    /// no side shrinks below the minimum.
    static func resize(_ rect: CGRect, handle: Handle, by delta: CGPoint) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        if handle.movesMinX { minX = min(minX + delta.x, maxX - minimumSide) }
        if handle.movesMaxX { maxX = max(maxX + delta.x, minX + minimumSide) }
        if handle.movesMinY { minY = min(minY + delta.y, maxY - minimumSide) }
        if handle.movesMaxY { maxY = max(maxY + delta.y, minY + minimumSide) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// `rect` moved by `delta`, kept inside `bounds`.
    static func move(_ rect: CGRect, by delta: CGPoint, within bounds: CGRect) -> CGRect {
        var moved = rect.offsetBy(dx: delta.x, dy: delta.y)
        moved.origin.x = min(max(moved.minX, bounds.minX), bounds.maxX - moved.width)
        moved.origin.y = min(max(moved.minY, bounds.minY), bounds.maxY - moved.height)
        return moved
    }
}
