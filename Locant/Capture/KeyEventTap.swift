import AppKit
import ApplicationServices

/// A session event tap for the hotkeys. Unlike a global `NSEvent` monitor, a tap sees a key before
/// the frontmost app does and can swallow it, so a chord fires Locant alone and never also reaches
/// Xcode. Needs Accessibility trust, which Locant already requires; without it `init` fails and
/// the caller observes with monitors instead.
@MainActor
final class KeyEventTap {
    enum Kind: Sendable { case keyDown, flagsChanged }

    struct KeyEvent: Sendable {
        let kind: Kind
        let keyCode: UInt16
        let flags: NSEvent.ModifierFlags
        let isRepeat: Bool
        let timestamp: TimeInterval

        init(kind: Kind, keyCode: UInt16, flags: NSEvent.ModifierFlags, isRepeat: Bool, timestamp: TimeInterval) {
            self.kind = kind
            self.keyCode = keyCode
            self.flags = flags
            self.isRepeat = isRepeat
            self.timestamp = timestamp
        }

        /// From an `NSEvent` of type `.keyDown` or `.flagsChanged`; nil for anything else.
        init?(_ event: NSEvent) {
            switch event.type {
            case .keyDown:
                self.init(kind: .keyDown, keyCode: event.keyCode, flags: event.modifierFlags, isRepeat: event.isARepeat, timestamp: event.timestamp)
            case .flagsChanged:
                self.init(kind: .flagsChanged, keyCode: event.keyCode, flags: event.modifierFlags, isRepeat: false, timestamp: event.timestamp)
            default:
                return nil
            }
        }
    }

    /// Returns true to swallow the event.
    private let handler: @MainActor (KeyEvent) -> Bool
    private var port: CFMachPort?
    private var source: CFRunLoopSource?

    init?(handler: @escaping @MainActor (KeyEvent) -> Bool) {
        self.handler = handler
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let tap = Unmanaged<KeyEventTap>.fromOpaque(refcon).takeUnretainedValue()
            switch type {
            case .tapDisabledByTimeout, .tapDisabledByUserInput:
                // macOS switches a slow tap off; ours is quick, so switch it back on.
                MainActor.assumeIsolated { tap.enable() }
                return Unmanaged.passUnretained(event)
            case .keyDown, .flagsChanged:
                // v0.8.1 R63: the ⌘V Locant posts to paste into an agent passes untouched, so a hotkey
                // recorded as ⌘V cannot swallow Locant's own paste.
                if AgentPaste.isOwnEvent(userData: event.getIntegerValueField(.eventSourceUserData)) {
                    return Unmanaged.passUnretained(event)
                }
                let keyEvent = KeyEvent(
                    kind: type == .keyDown ? .keyDown : .flagsChanged,
                    keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
                    flags: NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue)),
                    isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
                    timestamp: TimeInterval(event.timestamp) / 1_000_000_000
                )
                let swallow = MainActor.assumeIsolated { tap.handler(keyEvent) }
                return swallow ? nil : Unmanaged.passUnretained(event)
            default:
                return Unmanaged.passUnretained(event)
            }
        }
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return nil }
        self.port = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        enable()
    }

    private func enable() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: true)
    }

    func stop() {
        if let port {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        port = nil
        source = nil
    }
}
