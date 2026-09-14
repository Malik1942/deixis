import XCTest
@testable import Deixis

final class RingTests: XCTestCase {
    func testSegmentsByDirectionAndCenterCancel() {
        XCTAssertNil(Ring.segment(for: CGPoint(x: 5, y: -5)))
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 0, y: 60)), .snap)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 60, y: 10)), .text)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: -10, y: -60)), .color)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: -60, y: 20)), .cut)
        XCTAssertEqual(Ring.segment(for: CGPoint(x: 40, y: 40)), .snap, "the diagonal belongs to the vertical segment")
    }
}
