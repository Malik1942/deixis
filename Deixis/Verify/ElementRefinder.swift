import CoreGraphics
import Foundation

/// R31: the same element again, in the rebuilt app. Identifier first, then role and label, then the
/// nearest same-role frame. Pure over snapshots; the driver in `AppState` supplies retries.
enum ElementRefinder {
    static let nearestLimit: Double = 200
    static let retryInterval: Duration = .milliseconds(500)
    static let retries = 10

    static func match(_ target: ResolvedElement, among snapshots: [ElementSnapshot]) -> ResolvedElement? {
        let candidates = snapshots.compactMap(ElementResolver.resolve)
        let center = CGPoint(x: target.frame.x + target.frame.w / 2, y: target.frame.y + target.frame.h / 2)
        func distance(_ e: ResolvedElement) -> Double {
            hypot(e.frame.x + e.frame.w / 2 - center.x, e.frame.y + e.frame.h / 2 - center.y)
        }
        if let identifier = target.identifier {
            let byIdentifier = candidates.filter { $0.identifier == identifier }
            if let hit = byIdentifier.first(where: { $0.role == target.role }) ?? byIdentifier.first { return hit }
        }
        if let label = target.label {
            let byLabel = candidates.filter { $0.role == target.role && $0.label == label }
            if let hit = byLabel.min(by: { distance($0) < distance($1) }) { return hit }
        }
        let sameRole = candidates.filter { $0.role == target.role }
        if let nearest = sameRole.min(by: { distance($0) < distance($1) }), distance(nearest) <= nearestLimit {
            return nearest
        }
        return nil
    }
}
