import CoreGraphics
import Foundation

/// v0.2 R12, R15: what is inside a drawn frame, which of it is the primary reference, and what
/// sits near a point that has no element. Pure; the reader supplies snapshots.
enum RegionResolver {
    static let minimumInside: Double = 0.5
    static let cap = 12
    static let nearbyLimit = 3

    /// Non-container elements at least half inside `region`, duplicates collapsed, reading order, capped.
    static func elements(in region: CGRect, among snapshots: [ElementSnapshot]) -> [RegionElement] {
        var seen = Set<String>()
        var kept: [RegionElement] = []
        for snapshot in snapshots {
            guard !ElementResolver.isContainer(snapshot.element), let resolved = ElementResolver.resolve(snapshot) else { continue }
            let frame = resolved.frame.cgRect
            let area = frame.width * frame.height
            guard area > 0 else { continue }
            let inside = frame.intersection(region)
            guard !inside.isEmpty, (inside.width * inside.height) / area >= minimumInside else { continue }
            let key = "\(resolved.role)|\(resolved.frame.x)|\(resolved.frame.y)|\(resolved.frame.w)|\(resolved.frame.h)"
            guard seen.insert(key).inserted else { continue }
            kept.append(regionElement(from: resolved))
        }
        kept.sort { a, b in abs(a.frame.y - b.frame.y) > 4 ? a.frame.y < b.frame.y : a.frame.x < b.frame.x }
        return Array(kept.prefix(cap))
    }

    /// The primary reference for a region: nearest the center among identified elements, else
    /// among labeled ones. Nil when the frame holds nothing nameable.
    static func primary(among snapshots: [ElementSnapshot], in region: CGRect) -> ResolvedElement? {
        let center = CGPoint(x: region.midX, y: region.midY)
        let candidates = snapshots.compactMap { snapshot -> ResolvedElement? in
            guard !ElementResolver.isContainer(snapshot.element), let resolved = ElementResolver.resolve(snapshot) else { return nil }
            let frame = resolved.frame.cgRect
            let area = frame.width * frame.height
            guard area > 0 else { return nil }
            let inside = frame.intersection(region)
            guard !inside.isEmpty, (inside.width * inside.height) / area >= minimumInside else { return nil }
            return resolved
        }
        func nearest(_ pool: [ResolvedElement]) -> ResolvedElement? {
            pool.min { distance(from: center, to: $0.frame.cgRect) < distance(from: center, to: $1.frame.cgRect) }
        }
        if let identified = nearest(candidates.filter { $0.identifier != nil }) { return identified }
        return nearest(candidates.filter { $0.label != nil })
    }

    /// The closest labeled or identified elements around `point`, with a plain offset each.
    static func nearby(point: CGPoint, among nodes: [AttributeSet], limit: Int = nearbyLimit) -> [(element: RegionElement, offset: String)] {
        let framed = nodes.compactMap { node -> (RegionElement, Double)? in
            guard let resolved = ElementResolver.resolve(ElementSnapshot(element: node, ancestors: [])),
                  resolved.label != nil || resolved.identifier != nil,
                  !ElementResolver.containerRoles.contains(resolved.role) || resolved.label != nil else { return nil }
            return (regionElement(from: resolved), distance(from: point, to: resolved.frame.cgRect))
        }
        return framed.sorted { $0.1 < $1.1 }.prefix(limit).map { ($0.0, offsetText(from: point, to: $0.0.frame.cgRect)) }
    }

    /// "96 pt above", "40 pt left", "inside".
    static func offsetText(from point: CGPoint, to frame: CGRect) -> String {
        if frame.contains(point) { return "inside" }
        let dx = point.x < frame.minX ? frame.minX - point.x : (point.x > frame.maxX ? point.x - frame.maxX : 0)
        let dy = point.y < frame.minY ? frame.minY - point.y : (point.y > frame.maxY ? point.y - frame.maxY : 0)
        if dy >= dx {
            return "\(Int(dy.rounded())) pt \(point.y < frame.minY ? "below" : "above")"
        }
        return "\(Int(dx.rounded())) pt \(point.x < frame.minX ? "right" : "left")"
    }

    static func regionElement(from resolved: ResolvedElement) -> RegionElement {
        RegionElement(
            role: resolved.role, rawRole: resolved.rawRole, label: resolved.label,
            identifier: resolved.identifier, identifierSource: resolved.identifierSource, frame: resolved.frame
        )
    }

    /// Distance from a point to the nearest edge of a rect, 0 inside.
    static func distance(from point: CGPoint, to frame: CGRect) -> Double {
        let dx = max(frame.minX - point.x, 0, point.x - frame.maxX)
        let dy = max(frame.minY - point.y, 0, point.y - frame.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }
}
