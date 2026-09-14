import XCTest
@testable import Deixis

final class RingTests: XCTestCase {
    // v0.5 R39: a slower click on the ball is still a click; the ring waits AppKit's press default.
    func testHoldDelayIsAppKitPressDefault() {
        XCTAssertEqual(Ring.Tokens.holdDelay, 0.5)
    }

    func testSegmentsByDirectionAndCenterCancel() {
        XCTAssertNil(Ring.segment(for: CGPoint(x: 5, y: -5)))
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 0, y: 60)), .snap)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 60, y: 10)), .text)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: -10, y: -60)), .color)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: -60, y: 20)), .cut)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 40, y: 40)), .snap, "the diagonal belongs to the vertical segment")
    }
}
