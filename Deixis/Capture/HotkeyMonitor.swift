import AppKit

/// R1: the capture hotkey. A double-tap of one modifier within 350 ms (Control by default) or a
/// recorded chord (v0.3). Global monitors for other apps, local monitors for our own windows.
/// Global key monitors need Accessibility trust, which Deixis already requires.
@MainActor
final class HotkeyMonitor {
    static let window: TimeInterval = 0.35
    private static let rightCommandKeyCode: UInt16 = 54

    let hotkey: Hotkey
    private let onFire: @MainActor () -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var modifierWasDown = false
    private var lastModifierDown: TimeInterval?

    init(hotkey: Hotkey = .default, onFire: @escaping @MainActor () -> Void) {
        self.hotkey = hotkey
        self.onFire = onFire
    }

    func start() {
        guard globalMonitor == nil else { return }
        switch hotkey {
        case .doubleTap:
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                let flags = event.modifierFlags, keyCode = event.keyCode, timestamp = event.timestamp
                MainActor.assumeIsolated { self?.handleFlags(flags, keyCode: keyCode, timestamp: timestamp) }
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                let flags = event.modifierFlags, keyCode = event.keyCode, timestamp = event.timestamp
                MainActor.assumeIsolated { self?.handleFlags(flags, keyCode: keyCode, timestamp: timestamp) }
                return event
            }
        case .chord:
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let flags = event.modifierFlags, keyCode = event.keyCode
                _ = MainActor.assumeIsolated { self?.handleKey(flags, keyCode: keyCode) }
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let flags = event.modifierFlags, keyCode = event.keyCode
                let consumed = MainActor.assumeIsolated { self?.handleKey(flags, keyCode: keyCode) ?? false }
                return consumed ? nil : event
            }
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    // MARK: Double-tap

    /// Fires on the second rising edge of the modifier inside the window, with no other modifier held.
    func handleFlags(_ flags: NSEvent.ModifierFlags, keyCode: UInt16, timestamp: TimeInterval) {
        guard case .doubleTap(let modifier) = hotkey else { return }
        if modifier == .rightCommand, keyCode != Self.rightCommandKeyCode { return }
        let flag = Self.flag(for: modifier)
        let down = flags.contains(flag)
        let all: NSEvent.ModifierFlags = [.control, .command, .option, .shift]
        let otherModifier = !flags.intersection(all.subtracting(flag)).isEmpty
        defer { modifierWasDown = down }
        guard down, !modifierWasDown else { return }
        guard !otherModifier else { lastModifierDown = nil; return }
        if let last = lastModifierDown, timestamp - last <= Self.window {
            lastModifierDown = nil
            onFire()
        } else {
            lastModifierDown = timestamp
        }
    }

    // MARK: Chord

    /// Returns true when the event was the hotkey (and fires).
    @discardableResult
    func handleKey(_ flags: NSEvent.ModifierFlags, keyCode: UInt16) -> Bool {
        guard case .chord(let wantedCode, let wantedModifiers, _) = hotkey,
              Self.matches(keyCode: keyCode, flags: flags, wantedCode: wantedCode, wantedModifiers: wantedModifiers)
        else { return false }
        onFire()
        return true
    }

    static func matches(keyCode: UInt16, flags: NSEvent.ModifierFlags, wantedCode: UInt16, wantedModifiers: KeyModifiers) -> Bool {
        keyCode == wantedCode && KeyModifiers(flags) == wantedModifiers
    }

    static func flag(for modifier: HotkeyModifier) -> NSEvent.ModifierFlags {
        switch modifier {
        case .control: .control
        case .option: .option
        case .shift: .shift
        case .command, .rightCommand: .command
        }
    }
}

extension KeyModifiers {
    /// The four chord modifiers from an event; Caps Lock and Fn are ignored.
    init(_ flags: NSEvent.ModifierFlags) {
        var set = KeyModifiers()
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.shift) { set.insert(.shift) }
        if flags.contains(.command) { set.insert(.command) }
        self = set
    }
}
