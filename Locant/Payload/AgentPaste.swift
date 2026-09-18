import AppKit
import Carbon.HIToolbox

/// v0.9 R59: after Return, the capture is pasted into the agent app the user used last. The
/// decisions are pure and tested here; `AgentPaster` activates the app and posts the keys.
enum AgentPaste {
    /// Agent apps by exact bundle id, verified on this Mac on Sep 17, 2026. Never matched by name:
    /// ChatGPT Classic (`com.openai.chat`), CodexBar, and the Claude app's background-only Claude
    /// Code copies share words with these and are not agents.
    static let bundleIds: Set<String> = [
        "com.anthropic.claudefordesktop", // Claude
        "com.todesktop.230313mzl4w4u92", // Cursor
        "com.openai.codex", // Codex, installed as ChatGPT.app
    ]

    static func isAgent(bundleId: String?) -> Bool {
        bundleId.map { bundleIds.contains($0) } ?? false
    }

    /// Return is pressed in the agent only for a note with words in it, and only with the switch on.
    static func sends(note: String, enabled: Bool) -> Bool {
        enabled && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Beside the note field: the arrow and the app, then the window's title once it is known.
    struct TargetLabel: Equatable, Sendable {
        var lead: String
        var title: String?
    }

    static func label(appName: String?, windowTitle: String?) -> TargetLabel {
        guard let appName else { return TargetLabel(lead: "→ no agent yet", title: nil) }
        let title = windowTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        return TargetLabel(lead: "→ \(appName)", title: (title?.isEmpty ?? true) ? nil : title)
    }

    /// How a paste ended.
    enum Outcome: Equatable, Sendable {
        case pasted, sent, noAgent, noPermission, didNotComeForward
    }

    /// What the toast says when nothing was pasted; nil when the paste itself is the feedback.
    static func toastText(_ outcome: Outcome, appName: String?) -> String? {
        switch outcome {
        case .pasted, .sent: nil
        case .noAgent: "Copied · no agent yet"
        case .noPermission: "Copied · pasting needs Accessibility"
        case .didNotComeForward: "Copied · \(appName ?? "the agent") didn't come forward"
        }
    }

    /// Marks the keys Locant posts, in `eventSourceUserData`, so its own tap lets them through.
    /// "LOCANT" in ASCII; nothing else sets it.
    static let eventMarker: Int64 = 0x4C_4F_43_41_4E_54

    static func isOwnEvent(userData: Int64) -> Bool {
        userData == eventMarker
    }
}

/// v0.9 R59: brings the agent app forward and posts ⌘V, then Return when asked. Not pure; not unit
/// tested. Every step checks the agent is still in front, so a key never lands in the app the user
/// pointed at.
@MainActor
enum AgentPaster {
    /// After the agent is frontmost, before ⌘V: Electron puts focus back in its composer.
    static let settle: Duration = .milliseconds(150)
    /// Between ⌘V and Return: Electron paste handlers, and an image attachment most of all, finish
    /// after the key. Tuned in dogfood.
    static let sendGap: Duration = .milliseconds(400)

    static func paste(into app: NSRunningApplication?, send: Bool, reader: AccessibilityReader) async -> AgentPaste.Outcome {
        guard let app, !app.isTerminated else { return .noAgent }
        guard CGPreflightPostEventAccess() else { return .noPermission }
        await waitForKeysUp()
        guard await bringForward(app, reader: reader) else { return .didNotComeForward }
        try? await Task.sleep(for: settle)
        guard isFrontmost(app) else { return .didNotComeForward }
        post(keyCode: pasteKeyCode(), flags: .maskCommand)
        guard send else { return .pasted }
        try? await Task.sleep(for: sendGap)
        guard isFrontmost(app) else { return .pasted }
        post(keyCode: CGKeyCode(kVK_Return), flags: [])
        return .sent
    }

    /// The Return that committed the note, and any modifier still held, must be up first, or they
    /// leak into the posted keys. Half a second at most.
    private static func waitForKeysUp() async {
        let modifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
        for _ in 0..<20 {
            let returnDown = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(kVK_Return))
            let held = !CGEventSource.flagsState(.hidSystemState).intersection(modifiers).isEmpty
            if !returnDown, !held { return }
            try? await Task.sleep(for: .milliseconds(25))
        }
    }

    /// Activates, then polls every 25 ms for a second: a notification never comes when the app is
    /// already in front. After 300 ms, accessibility raises it, which reaches a window on another Space.
    private static func bringForward(_ app: NSRunningApplication, reader: AccessibilityReader) async -> Bool {
        if isFrontmost(app) { return true }
        _ = app.activate(options: [])
        for tick in 1...40 {
            try? await Task.sleep(for: .milliseconds(25))
            if isFrontmost(app) { return true }
            if app.isTerminated { return false }
            if tick == 12 { await reader.raise(pid: app.processIdentifier) }
        }
        return false
    }

    private static func isFrontmost(_ app: NSRunningApplication) -> Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    }

    /// Key down and up with the flags on the events themselves: separate Command events would feed
    /// the double-tap detector. Marked, so Locant's own tap lets them through.
    private static func post(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .privateState)
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { continue }
            event.flags = flags
            event.setIntegerValueField(.eventSourceUserData, value: AgentPaste.eventMarker)
            event.post(tap: .cgSessionEventTap)
        }
    }

    /// The key that makes ⌘V on the current layout: the ASCII-capable one, so an active Chinese or
    /// Japanese input method still finds it, read with Command held, so "Dvorak – QWERTY ⌘" pastes
    /// too. ANSI V when the layout cannot be read.
    private static func pasteKeyCode() -> CGKeyCode {
        let fallback = CGKeyCode(kVK_ANSI_V)
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return fallback }
        let data = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue() as Data
        let command = UInt32((cmdKey >> 8) & 0xFF)
        let found = data.withUnsafeBytes { raw -> CGKeyCode? in
            guard let layout = raw.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }
            for code in CGKeyCode(0)..<CGKeyCode(128) {
                var deadKeys: UInt32 = 0
                var length = 0
                var characters = [UniChar](repeating: 0, count: 4)
                let status = UCKeyTranslate(
                    layout, code, UInt16(kUCKeyActionDown), command, UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysMask), &deadKeys, characters.count, &length, &characters
                )
                if status == noErr, length == 1, characters[0] == UniChar(0x76) { return code } // "v"
            }
            return nil
        }
        return found ?? fallback
    }
}
