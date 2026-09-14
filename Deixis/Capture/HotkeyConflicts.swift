import Carbon.HIToolbox
import Foundation

/// Why a recorded hotkey might not be Deixis's alone. A clash inside Deixis is refused by the
/// recorder; a clash with macOS is only shown, since the user may want Deixis to win. Menu
/// shortcuts of other apps are not checked in this build.
enum HotkeyConflict: Equatable, Sendable {
    /// Another Deixis action already uses it; "capture" for the capture hotkey.
    case deixis(action: String)
    /// A shortcut switched on in System Settings › Keyboard › Keyboard Shortcuts.
    case system

    var message: String {
        switch self {
        case .deixis(let action): "Already used for \(action.capitalized)."
        case .system: "Also a macOS shortcut. Deixis takes it first; change either one if you need both."
        }
    }
}

/// One enabled system shortcut, as macOS reports it.
struct SystemShortcut: Equatable, Sendable {
    let keyCode: UInt16
    let modifiers: KeyModifiers
}

enum HotkeyConflicts {
    /// Every conflict for `hotkey` if it were bound to `action`, Deixis's own first.
    @MainActor
    static func check(_ hotkey: Hotkey, for action: String, in preferences: Preferences) -> [HotkeyConflict] {
        var found: [HotkeyConflict] = []
        if let other = preferences.action(using: hotkey, excluding: action) {
            found.append(.deixis(action: other))
        }
        if case .chord(let keyCode, let modifiers, _) = hotkey,
           matchesSystem(keyCode: keyCode, modifiers: modifiers, in: systemShortcuts()) {
            found.append(.system)
        }
        return found
    }

    /// Pure: whether the chord is one of `shortcuts`.
    static func matchesSystem(keyCode: UInt16, modifiers: KeyModifiers, in shortcuts: [SystemShortcut]) -> Bool {
        shortcuts.contains(SystemShortcut(keyCode: keyCode, modifiers: modifiers))
    }

    /// The shortcuts switched on in System Settings › Keyboard, read from macOS itself so the
    /// user's own changes count. Entries without a key are skipped.
    static func systemShortcuts() -> [SystemShortcut] {
        var array: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&array) == noErr, let list = array?.takeRetainedValue() as? [[String: Any]] else { return [] }
        return list.compactMap { entry in
            guard entry["kHISymbolicHotKeyEnabled"] as? Bool == true,
                  let code = entry["kHISymbolicHotKeyCode"] as? Int, code >= 0, code < 0xFFFF,
                  let modifiers = entry["kHISymbolicHotKeyModifiers"] as? Int
            else { return nil }
            return SystemShortcut(keyCode: UInt16(code), modifiers: KeyModifiers(carbon: UInt32(modifiers)))
        }
    }
}

extension KeyModifiers {
    /// From Carbon's modifier mask (`cmdKey`, `shiftKey`, `optionKey`, `controlKey`); other bits are ignored.
    init(carbon: UInt32) {
        var set = KeyModifiers()
        if carbon & UInt32(controlKey) != 0 { set.insert(.control) }
        if carbon & UInt32(optionKey) != 0 { set.insert(.option) }
        if carbon & UInt32(shiftKey) != 0 { set.insert(.shift) }
        if carbon & UInt32(cmdKey) != 0 { set.insert(.command) }
        self = set
    }
}
