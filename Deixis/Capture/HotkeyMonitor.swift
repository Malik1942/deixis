import AppKit

/// R1: double-tap Control within 350 ms. Global monitor for other apps, local monitor for our own
/// windows. Global key monitors need Accessibility trust, which Deixis already requires.
@MainActor
final class HotkeyMonitor {
    static let window: TimeInterval = 0.35

    private let onDoubleTap: @MainActor () -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var controlWasDown = false
    private var lastControlDown: TimeInterval?

    init(onDoubleTap: @escaping @MainActor () -> Void) {
        self.onDoubleTap = onDoubleTap
    }

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags
            let timestamp = event.timestamp
            MainActor.assumeIsolated { self?.handle(flags: flags, timestamp: timestamp) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags
            let timestamp = event.timestamp
            MainActor.assumeIsolated { self?.handle(flags: flags, timestamp: timestamp) }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    /// Fires on the second rising edge of Control inside the window, with no other modifier held.
    func handle(flags: NSEvent.ModifierFlags, timestamp: TimeInterval) {
        let controlDown = flags.contains(.control)
        let otherModifier = !flags.intersection([.command, .option, .shift]).isEmpty
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
