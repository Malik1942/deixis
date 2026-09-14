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
        XCTAssertEqual(p.hotkeyModifier, .control)
        XCTAssertEqual(p.captureFolder, Preferences.defaultCaptureFolder)
        XCTAssertTrue(p.captureFolder.hasSuffix("/Pictures/Deixis"))
        XCTAssertTrue(p.ballEnabled)
        XCTAssertNil(p.ballPosition)
        XCTAssertEqual(p.myApps, [])
    }

    // 2
    func testRoundTripThroughDefaults() {
        let defaults = isolatedDefaults()
        let p = Preferences(defaults: defaults)
        var hotkeyChanges = 0
        p.onHotkeyChange = { hotkeyChanges += 1 }
        p.hotkeyModifier = .option
        p.hotkeyModifier = .option
        p.captureFolder = "/tmp/captures"
        p.ballEnabled = false
        p.ballPosition = CGPoint(x: 1200, y: 40)
        p.myApps = ["com.inspireocean.app"]
        XCTAssertEqual(hotkeyChanges, 1, "only a real change restarts the monitor")

        let again = Preferences(defaults: defaults)
        XCTAssertEqual(again.hotkeyModifier, .option)
        XCTAssertEqual(again.captureFolder, "/tmp/captures")
        XCTAssertFalse(again.ballEnabled)
        XCTAssertEqual(again.ballPosition, CGPoint(x: 1200, y: 40))
        XCTAssertEqual(again.myApps, ["com.inspireocean.app"])
        XCTAssertEqual(again.captureFolderURL.path(percentEncoded: false), "/tmp/captures/")
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
