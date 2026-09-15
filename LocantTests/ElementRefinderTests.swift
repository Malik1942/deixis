import XCTest
@testable import Locant

final class ElementRefinderTests: XCTestCase {
    private func snap(_ role: String, label: String? = nil, id: String? = nil, x: Double, y: Double, w: Double = 60, h: Double = 40) -> ElementSnapshot {
        ElementSnapshot(element: AttributeSet(role: role, description: label, identifier: id, frame: Frame(x: x, y: y, w: w, h: h), childCount: 0), ancestors: [])
    }
    private func target(_ role: String, label: String? = nil, id: String? = nil, x: Double, y: Double) -> ResolvedElement {
        ResolvedElement(role: role, rawRole: "AX" + role, label: label, identifier: id, identifierSource: id == nil ? .unknown : .declared, value: nil, frame: Frame(x: x, y: y, w: 60, h: 40), path: [])
    }

    func testIdentifierWinsOverSameLabelSibling() {
        let live = [snap("AXButton", label: "Save", x: 0, y: 0), snap("AXButton", label: "Save", id: "saveButton", x: 500, y: 500)]
        let found = ElementRefinder.match(target("button", label: "Save", id: "saveButton", x: 0, y: 0), among: live)
        XCTAssertEqual(found?.identifier, "saveButton")
        XCTAssertEqual(found?.frame.x, 500)
    }

    func testRoleAndLabelWhenNoIdentifier() {
        let live = [snap("AXStaticText", label: "Save", x: 10, y: 10), snap("AXButton", label: "Save", x: 300, y: 300), snap("AXButton", label: "Cancel", x: 0, y: 0)]
        let found = ElementRefinder.match(target("button", label: "Save", x: 0, y: 0), among: live)
        XCTAssertEqual(found?.role, "button")
        XCTAssertEqual(found?.frame.x, 300)
    }

    func testNearestSameRoleWithin200Points() {
        let live = [snap("AXButton", label: "Other", x: 100, y: 100), snap("AXButton", label: "Far", x: 900, y: 900)]
        XCTAssertEqual(ElementRefinder.match(target("button", label: "Gone", x: 0, y: 0), among: live)?.label, "Other")
        XCTAssertNil(ElementRefinder.match(target("button", label: "Gone", x: 0, y: 0), among: [snap("AXButton", label: "Far", x: 900, y: 900)]))
        XCTAssertNil(ElementRefinder.match(target("cluster", x: 0, y: 0), among: live), "clusters are computed, never refound")
    }
}
