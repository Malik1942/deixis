import XCTest
@testable import Locant

final class AutoVerifyTests: XCTestCase {
    private func capture(mode: CaptureMode = .fix, bundleId: String = "com.inspireocean.app", createdAt: String = "2026-09-14T18:00:00+08:00",
                         element: ResolvedElement? = ResolvedElement(role: "button", rawRole: "AXButton", label: "Save", identifier: "save", identifierSource: .declared, value: nil, frame: Frame(x: 1, y: 2, w: 3, h: 4), path: []),
                         iterations: [Iteration] = []) -> Capture {
        var c = Capture(
            id: "20260914-180000-ab12", createdAt: createdAt, mode: mode,
            image: ImageInfo(path: "/tmp/locant-oryne-20260914-180000-ab12.png", widthPt: 10, heightPt: 10, scale: 2, crop: nil),
            source: SourceInfo(app: AppInfo(bundleId: bundleId, name: "Oryne"), window: nil, url: nil, simulator: nil, projectRoot: "/tmp/x", gitCommit: "abc123"),
            element: element, note: "round it"
        )
        c.iterations = iterations
        return c
    }

    private let now = ISO8601DateFormatter().date(from: "2026-09-14T20:00:00+08:00")!

    // 1
    func testOwnAppWithinADay() {
        XCTAssertTrue(AutoVerify.wants(capture(), activated: "com.inspireocean.app", now: now))
    }

    // 2
    func testOtherAppsAreIgnored() {
        XCTAssertFalse(AutoVerify.wants(capture(), activated: "com.apple.Safari", now: now))
        XCTAssertFalse(AutoVerify.wants(capture(mode: .reference), activated: "com.inspireocean.app", now: now))
    }

    // 3
    func testDrawnFrameAndNoElementAreIgnored() {
        XCTAssertFalse(AutoVerify.wants(capture(element: nil), activated: "com.inspireocean.app", now: now))
        let cluster = ResolvedElement(role: ElementResolver.clusterRole, rawRole: "", label: nil, identifier: nil, identifierSource: .unknown, value: nil, frame: Frame(x: 0, y: 0, w: 9, h: 9), path: [])
        XCTAssertFalse(AutoVerify.wants(capture(element: cluster), activated: "com.inspireocean.app", now: now))
    }

    // 4
    func testWatchEndsAfterADay() {
        XCTAssertTrue(AutoVerify.wants(capture(createdAt: "2026-09-13T20:00:01+08:00"), activated: "com.inspireocean.app", now: now))
        XCTAssertFalse(AutoVerify.wants(capture(createdAt: "2026-09-13T19:59:59+08:00"), activated: "com.inspireocean.app", now: now))
        XCTAssertFalse(AutoVerify.wants(capture(createdAt: "not a date"), activated: "com.inspireocean.app", now: now))
    }

    // 5
    func testComparesWithTheNewestImage() {
        XCTAssertEqual(AutoVerify.previousImagePath(of: capture()), "/tmp/locant-oryne-20260914-180000-ab12.png")
        let iteration = Iteration(capturedAt: "2026-09-14T18:05:00+08:00", imagePath: "/tmp/after-1.png", gitBefore: "abc123", gitAfter: nil, diffStat: nil, files: [])
        XCTAssertEqual(AutoVerify.previousImagePath(of: capture(iterations: [iteration])), "/tmp/after-1.png")
    }
}
