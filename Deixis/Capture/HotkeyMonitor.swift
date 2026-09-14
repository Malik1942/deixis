import AppKit

/// R1: double-tap a modifier within 350 ms (Control by default, configurable in v0.3). Global
/// monitor for other apps, local monitor for our own windows. Global key monitors need
/// Accessibility trust, which Deixis already requires.
@MainActor
final class HotkeyMonitor {
    static let window: TimeInterval = 0.35
    private static let rightCommandKeyCode: UInt16 = 54

    let modifier: HotkeyModifier
    private let onDoubleTap: @MainActor () -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var controlWasDown = false
    private var lastControlDown: TimeInterval?

    init(modifier: HotkeyModifier = .control, onDoubleTap: @escaping @MainActor () -> Void) {
        self.modifier = modifier
        self.onDoubleTap = onDoubleTap
    }

    private var flag: NSEvent.ModifierFlags {
        switch modifier {
        case .control: .control
        case .option: .option
        case .shift: .shift
        case .command, .rightCommand: .command
        }
    }

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags
            let keyCode = event.keyCode
            let timestamp = event.timestamp
            MainActor.assumeIsolated { self?.handle(flags: flags, keyCode: keyCode, timestamp: timestamp) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags
            let keyCode = event.keyCode
            let timestamp = event.timestamp
            MainActor.assumeIsolated { self?.handle(flags: flags, keyCode: keyCode, timestamp: timestamp) }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    /// Fires on the second rising edge of the modifier inside the window, with no other modifier held.
    func handle(flags: NSEvent.ModifierFlags, keyCode: UInt16, timestamp: TimeInterval) {
        if modifier == .rightCommand, keyCode != Self.rightCommandKeyCode { return }
        let controlDown = flags.contains(flag)
        let all: NSEvent.ModifierFlags = [.control, .command, .option, .shift]
        let others = all.subtracting(flag)
        let otherModifier = !flags.intersection(others).isEmpty
        defer { controlWasDown = controlDown }
        guard controlDown, !controlWasDown else { return }
        guard !otherModifier else { lastControlDown = nil; return }
        if let last = lastControlDown, timestamp - last <= Self.window {
            lastControlDown = nil
            onDoubleTap()
        } else {
            lastControlDown = timestamp
        }
    }
}
