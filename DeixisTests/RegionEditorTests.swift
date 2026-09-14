import CoreGraphics
import XCTest
@testable import Deixis

final class RegionEditorTests: XCTestCase {
    let rect = CGRect(x: 100, y: 100, width: 200, height: 100)

    // 1
    func testHitFindsHandlesInsideAndOutside() {
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 100, y: 200), in: rect), .handle(.topLeft))
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 305, y: 150), in: rect), .handle(.right), "within grab slack")
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 200, y: 96), in: rect), .handle(.bottom))
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 200, y: 150), in: rect), .inside)
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 50, y: 50), in: rect), .outside)
        XCTAssertEqual(RegionEditor.hit(CGPoint(x: 120, y: 150), in: rect), .inside, "past the slack, the body wins")
    }

    // 2
    func testResizeKeepsOppositeEdges() {
        let grown = RegionEditor.resize(rect, handle: .bottomRight, by: CGPoint(x: 20, y: -30))
        XCTAssertEqual(grown, CGRect(x: 100, y: 70, width: 220, height: 130))
        let fromTop = RegionEditor.resize(rect, handle: .top, by: CGPoint(x: 999, y: 10))
        XCTAssertEqual(fromTop, CGRect(x: 100, y: 100, width: 200, height: 110), "an edge handle ignores the other axis")
    }

    // 3
    func testResizeNeverCollapses() {
        let crushed = RegionEditor.resize(rect, handle: .left, by: CGPoint(x: 500, y: 0))
        XCTAssertEqual(crushed.maxX, 300)
        XCTAssertEqual(crushed.width, RegionEditor.minimumSide)
    }

    // 4
    func testMoveStaysInsideBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        XCTAssertEqual(RegionEditor.move(rect, by: CGPoint(x: 10, y: -20), within: bounds), CGRect(x: 110, y: 80, width: 200, height: 100))
        XCTAssertEqual(RegionEditor.move(rect, by: CGPoint(x: 500, y: 500), within: bounds), CGRect(x: 200, y: 200, width: 200, height: 100))
        XCTAssertEqual(RegionEditor.move(rect, by: CGPoint(x: -500, y: -500), within: bounds).origin, .zero)
    }
}
