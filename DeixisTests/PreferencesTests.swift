import XCTest
@testable import Deixis

@MainActor
final class PreferencesTests: XCTestCase {
    private func isolatedDefaults() -> UserDefaults {
        let name = "DeixisTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    // 1
    func testDefaultsWhenNothingStored() {
        let p = Preferences(defaults: isolatedDefaults())
        XCTAssertEqual(p.hotkey, .default)
        XCTAssertEqual(p.hotkey.title, "Double-tap ⌃")
        XCTAssertEqual(p.captureFolder, Preferences.defaultCaptureFolder)
        XCTAssertTrue(p.captureFolder.hasSuffix("/Pictures/Deixis"))
        XCTAssertTrue(p.ballEnabled)
        XCTAssertTrue(p.ballAutoHide)
        XCTAssertNil(p.ballPosition)
        XCTAssertEqual(p.myApps, [])
        XCTAssertEqual(p.organization, .none)
        XCTAssertTrue(p.adjustSelection)
    }

    // 2
    func testRoundTripThroughDefaults() {
        let defaults = isolatedDefaults()
        let p = Preferences(defaults: defaults)
        var hotkeyChanges = 0
        p.onHotkeyChange = { hotkeyChanges += 1 }
        p.hotkey = .chord(keyCode: 2, modifiers: [.command, .shift], key: "D")
        p.hotkey = .chord(keyCode: 2, modifiers: [.command, .shift], key: "D")
        p.captureFolder = "/tmp/captures"
        p.ballEnabled = false
        p.ballAutoHide = false
        p.ballPosition = CGPoint(x: 1200, y: 40)
        p.myApps = ["com.inspireocean.app"]
        p.organization = .byProject
        p.adjustSelection = false
        XCTAssertEqual(hotkeyChanges, 1, "only a real change restarts the monitor")

        let again = Preferences(defaults: defaults)
        XCTAssertEqual(again.hotkey, .chord(keyCode: 2, modifiers: [.command, .shift], key: "D"))
        XCTAssertEqual(again.hotkey.title, "⇧⌘D")
        XCTAssertEqual(again.captureFolder, "/tmp/captures")
        XCTAssertFalse(again.ballEnabled)
        XCTAssertFalse(again.ballAutoHide)
        XCTAssertEqual(again.ballPosition, CGPoint(x: 1200, y: 40))
        XCTAssertEqual(again.myApps, ["com.inspireocean.app"])
        XCTAssertEqual(again.organization, .byProject)
        XCTAssertFalse(again.adjustSelection)
        XCTAssertEqual(again.captureFolderURL.path(percentEncoded: false), "/tmp/captures/")
    }

    func testLegacyHotkeyModifierMigrates() {
        let defaults = isolatedDefaults()
        defaults.set("option", forKey: Preferences.Key.hotkeyModifier)
        XCTAssertEqual(Preferences(defaults: defaults).hotkey, .doubleTap(.option))
    }

    // 3
    func testBallPositionClears() {
        let defaults = isolatedDefaults()
        let p = Preferences(defaults: defaults)
        p.ballPosition = CGPoint(x: 5, y: 6)
        p.ballPosition = nil
        XCTAssertNil(Preferences(defaults: defaults).ballPosition)
    }
}
