import XCTest
@testable import Locant

final class AgentPasteTests: XCTestCase {
    // 1: exact bundle ids; a shared word is not enough.
    func testOnlyTheThreeAgentAppsCount() {
        XCTAssertTrue(AgentPaste.isAgent(bundleId: "com.anthropic.claudefordesktop"))
        XCTAssertTrue(AgentPaste.isAgent(bundleId: "com.todesktop.230313mzl4w4u92"))
        XCTAssertTrue(AgentPaste.isAgent(bundleId: "com.openai.codex"))
        for other in [
            "com.openai.chat", "com.steipete.codexbar", "com.anthropic.claude-code",
            "com.anthropic.claude-code-url-handler", "com.anthropic.claudefordesktop.helper",
            "com.openai.codex.helper", "com.apple.Terminal",
        ] {
            XCTAssertFalse(AgentPaste.isAgent(bundleId: other), other)
        }
        XCTAssertFalse(AgentPaste.isAgent(bundleId: nil))
    }

    // 2: Return goes to the agent only for a note with words in it, and only with the switch on.
    func testSendsOnlyANoteWithTheSwitchOn() {
        XCTAssertTrue(AgentPaste.sends(note: "make it rounded", enabled: true))
        XCTAssertFalse(AgentPaste.sends(note: "make it rounded", enabled: false))
        XCTAssertFalse(AgentPaste.sends(note: "", enabled: true))
        XCTAssertFalse(AgentPaste.sends(note: "  \n\t ", enabled: true))
    }

    // 3: the label names the app at once and the window when it is known.
    func testLabelNamesTheAppThenTheWindow() {
        XCTAssertEqual(AgentPaste.label(appName: nil, windowTitle: "x"), .init(lead: "→ no agent yet", title: nil))
        XCTAssertEqual(AgentPaste.label(appName: "Cursor", windowTitle: nil), .init(lead: "→ Cursor", title: nil))
        XCTAssertEqual(AgentPaste.label(appName: "Cursor", windowTitle: "   "), .init(lead: "→ Cursor", title: nil))
        XCTAssertEqual(AgentPaste.label(appName: "ChatGPT", windowTitle: " Deixis — v0.9 "), .init(lead: "→ ChatGPT", title: "Deixis — v0.9"))
    }

    // 4: the toast speaks only when nothing was pasted.
    func testToastExplainsOnlyAMissedPaste() {
        XCTAssertNil(AgentPaste.toastText(.pasted, appName: "Cursor"))
        XCTAssertNil(AgentPaste.toastText(.sent, appName: "Cursor"))
        XCTAssertEqual(AgentPaste.toastText(.noAgent, appName: nil), "Copied · no agent yet")
        XCTAssertEqual(AgentPaste.toastText(.didNotComeForward, appName: "Cursor"), "Copied · Cursor didn't come forward")
        XCTAssertEqual(AgentPaste.toastText(.didNotComeForward, appName: nil), "Copied · the agent didn't come forward")
        XCTAssertEqual(AgentPaste.toastText(.noPermission, appName: "Cursor"), "Copied · pasting needs Accessibility")
    }

    // 5: Locant's own posted keys are known by their marker, and nothing else is.
    func testOwnEventsAreKnownByTheirMarker() {
        XCTAssertTrue(AgentPaste.isOwnEvent(userData: AgentPaste.eventMarker))
        XCTAssertFalse(AgentPaste.isOwnEvent(userData: 0))
        XCTAssertFalse(AgentPaste.isOwnEvent(userData: AgentPaste.eventMarker + 1))
    }
}
