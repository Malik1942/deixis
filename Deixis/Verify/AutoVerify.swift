import Foundation

/// v0.6 R52: iterations are collected by themselves. After a Point capture in an app the user
/// builds, each launch or activation of that app within a day is a chance to capture the
/// element again. Pure: the decision, given the capture and the app that came forward.
enum AutoVerify {
    /// How long after a capture its app is watched.
    static let window: TimeInterval = 24 * 60 * 60
    /// The app has just come forward; let its window draw before the element is looked for.
    static let settle: Duration = .seconds(2)

    /// Whether `capture` is worth refinding when the app with `bundleId` came forward at `now`:
    /// it is the user's own app (mode fix), the same app, it has one element (not a drawn frame),
    /// and the capture is under a day old.
    static func wants(_ capture: Capture, activated bundleId: String, now: Date = .now) -> Bool {
        guard capture.mode == .fix, capture.source.app.bundleId == bundleId else { return false }
        guard let element = capture.element, element.role != ElementResolver.clusterRole else { return false }
        guard let created = ISO8601DateFormatter().date(from: capture.createdAt) else { return false }
        let age = now.timeIntervalSince(created)
        return age >= -60 && age <= window
    }

    /// The image the next capture is compared with: the newest iteration, else the original.
    static func previousImagePath(of capture: Capture) -> String {
        capture.iterations.last?.imagePath ?? capture.image.path
    }
}
