import Foundation

/// Section 4: `fix` when the user's own code is on screen, else `reference`.
enum ModeClassifier {
    /// Hard-coded in v0.1; moves to Settings later.
    static let myApps: [String] = [
        "com.malikzhang.oryne",
        "com.malikzhang.moti",
    ]

    static let simulatorBundleId = "com.apple.iphonesimulator"

    static func classify(_ source: SourceInfo, myApps: [String] = myApps) -> CaptureMode {
        if myApps.contains(source.app.bundleId) { return .fix }
        if source.app.bundleId == simulatorBundleId {
            // Someone else's app in the Simulator is a reference. An unreadable bundle id is
            // still most likely the user's own build.
            guard let simulated = source.simulator?.appBundleId else { return .fix }
            return myApps.contains(simulated) ? .fix : .reference
        }
        if let url = source.url, let host = URL(string: url)?.host?.lowercased(),
           host == "localhost" || host == "127.0.0.1" {
            return .fix
        }
        return .reference
    }
}
