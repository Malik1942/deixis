import Foundation

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
