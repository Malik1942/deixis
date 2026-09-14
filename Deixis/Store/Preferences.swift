import CoreGraphics
import Foundation
import Observation

/// v0.3 R18: the user's few settings, backed by UserDefaults. Owned by `AppState`; there is no
/// second shared object. A fresh install works with every default.
enum HotkeyModifier: String, CaseIterable, Codable, Sendable {
    case control, option, shift, command, rightCommand

    var title: String {
        switch self {
        case .control: "Double-tap Control"
        case .option: "Double-tap Option"
        case .shift: "Double-tap Shift"
        case .command: "Double-tap Command"
        case .rightCommand: "Double-tap Right Command"
        }
    }

    /// For the menu bar item title.
    var symbol: String {
        switch self {
        case .control: "⌃⌃"
        case .option: "⌥⌥"
        case .shift: "⇧⇧"
        case .command: "⌘⌘"
        case .rightCommand: "right ⌘⌘"
        }
    }
}

@Observable
@MainActor
final class Preferences {
    enum Key {
        static let hotkeyModifier = "hotkeyModifier"
        static let captureFolder = "captureFolder"
        static let ballEnabled = "ballEnabled"
        static let ballPosition = "ballPosition"
        static let myApps = "myApps"
    }

    static var defaultCaptureFolder: String { ModeInference.directoryPath(FileStore.defaultDirectory) }

    @ObservationIgnored private let defaults: UserDefaults
    /// Called after the hotkey changes so the monitor can restart.
    @ObservationIgnored var onHotkeyChange: (() -> Void)?

    var hotkeyModifier: HotkeyModifier {
        didSet {
            defaults.set(hotkeyModifier.rawValue, forKey: Key.hotkeyModifier)
            if hotkeyModifier != oldValue { onHotkeyChange?() }
        }
    }

    var captureFolder: String {
        didSet { defaults.set(captureFolder, forKey: Key.captureFolder) }
    }

    var ballEnabled: Bool {
        didSet { defaults.set(ballEnabled, forKey: Key.ballEnabled) }
    }

    /// AppKit screen points; nil until the user moves the ball.
    var ballPosition: CGPoint? {
        didSet {
            if let ballPosition {
                defaults.set([ballPosition.x, ballPosition.y], forKey: Key.ballPosition)
            } else {
                defaults.removeObject(forKey: Key.ballPosition)
            }
        }
    }

    var myApps: [String] {
        didSet { defaults.set(myApps, forKey: Key.myApps) }
    }

    var captureFolderURL: URL { URL(filePath: captureFolder, directoryHint: .isDirectory) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hotkeyModifier = defaults.string(forKey: Key.hotkeyModifier).flatMap(HotkeyModifier.init(rawValue:)) ?? .control
        captureFolder = defaults.string(forKey: Key.captureFolder) ?? Self.defaultCaptureFolder
        ballEnabled = defaults.object(forKey: Key.ballEnabled) as? Bool ?? true
        if let pair = defaults.array(forKey: Key.ballPosition) as? [Double], pair.count == 2 {
            ballPosition = CGPoint(x: pair[0], y: pair[1])
        } else {
            ballPosition = nil
        }
        myApps = defaults.stringArray(forKey: Key.myApps) ?? []
    }
}
