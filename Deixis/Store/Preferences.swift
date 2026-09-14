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

    var glyph: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        case .rightCommand: "right ⌘"
        }
    }
}

/// v0.3 R21: how captures are organized on disk. Finder tags are always written; this only adds
/// subfolders for people who think in folders.
enum CaptureOrganization: String, CaseIterable, Codable, Sendable {
    case none, byApp, byProject, byMonth

    var title: String {
        switch self {
        case .none: "One folder"
        case .byApp: "By app"
        case .byProject: "By project"
        case .byMonth: "By month"
        }
    }
}

/// Modifier keys of a chord, AppKit-free so the store stays pure.
struct KeyModifiers: OptionSet, Codable, Sendable, Hashable {
    let rawValue: UInt8
    static let control = KeyModifiers(rawValue: 1)
    static let option = KeyModifiers(rawValue: 2)
    static let shift = KeyModifiers(rawValue: 4)
    static let command = KeyModifiers(rawValue: 8)

    /// In the order macOS prints them: ⌃ ⌥ ⇧ ⌘.
    var symbols: String {
        var s = ""
        if contains(.control) { s += "⌃" }
        if contains(.option) { s += "⌥" }
        if contains(.shift) { s += "⇧" }
        if contains(.command) { s += "⌘" }
        return s
    }
}

/// v0.3: the capture hotkey, recorded by the user. Either a double-tap of one modifier (the v0.1
/// convention) or a key pressed with modifiers.
enum Hotkey: Codable, Equatable, Sendable {
    case doubleTap(HotkeyModifier)
    case chord(keyCode: UInt16, modifiers: KeyModifiers, key: String)

    static let `default` = Hotkey.doubleTap(.control)

    /// "Double-tap ⌃", "⌘⇧D", "F5".
    var title: String {
        switch self {
        case .doubleTap(let modifier): "Double-tap \(modifier.glyph)"
        case .chord(_, let modifiers, let key): modifiers.symbols + key
        }
    }

    /// Short form for the menu bar item: "⌃⌃", "⌘⇧D".
    var symbol: String {
        switch self {
        case .doubleTap(let modifier): modifier.symbol
        case .chord(_, let modifiers, let key): modifiers.symbols + key
        }
    }
}

@Observable
@MainActor
final class Preferences {
    enum Key {
        static let hotkey = "hotkey"
        static let hotkeyModifier = "hotkeyModifier" // v0.3 early builds; migrated on read
        static let captureFolder = "captureFolder"
        static let ballEnabled = "ballEnabled"
        static let ballPosition = "ballPosition"
        static let myApps = "myApps"
        static let organization = "organization"
    }

    static var defaultCaptureFolder: String { ModeInference.directoryPath(FileStore.defaultDirectory) }

    @ObservationIgnored private let defaults: UserDefaults
    /// Called after the hotkey changes so the monitor can restart.
    @ObservationIgnored var onHotkeyChange: (() -> Void)?
    /// Called after the ball toggle changes so it can show or hide at once.
    @ObservationIgnored var onBallEnabledChange: (() -> Void)?

    var hotkey: Hotkey {
        didSet {
            if let data = try? JSONEncoder().encode(hotkey) { defaults.set(data, forKey: Key.hotkey) }
            if hotkey != oldValue { onHotkeyChange?() }
        }
    }

    var captureFolder: String {
        didSet { defaults.set(captureFolder, forKey: Key.captureFolder) }
    }

    var ballEnabled: Bool {
        didSet {
            defaults.set(ballEnabled, forKey: Key.ballEnabled)
            if ballEnabled != oldValue { onBallEnabledChange?() }
        }
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

    var organization: CaptureOrganization {
        didSet { defaults.set(organization.rawValue, forKey: Key.organization) }
    }

    var captureFolderURL: URL { URL(filePath: captureFolder, directoryHint: .isDirectory) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Key.hotkey), let stored = try? JSONDecoder().decode(Hotkey.self, from: data) {
            hotkey = stored
        } else if let legacy = defaults.string(forKey: Key.hotkeyModifier).flatMap(HotkeyModifier.init(rawValue:)) {
            hotkey = .doubleTap(legacy)
        } else {
            hotkey = .default
        }
        captureFolder = defaults.string(forKey: Key.captureFolder) ?? Self.defaultCaptureFolder
        ballEnabled = defaults.object(forKey: Key.ballEnabled) as? Bool ?? true
        if let pair = defaults.array(forKey: Key.ballPosition) as? [Double], pair.count == 2 {
            ballPosition = CGPoint(x: pair[0], y: pair[1])
        } else {
            ballPosition = nil
        }
        myApps = defaults.stringArray(forKey: Key.myApps) ?? []
        organization = defaults.string(forKey: Key.organization).flatMap(CaptureOrganization.init(rawValue:)) ?? .none
    }
}
