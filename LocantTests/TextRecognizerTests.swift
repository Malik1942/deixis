import AppKit
import XCTest
@testable import Locant

final class TextRecognizerTests: XCTestCase {
    func testRecognizesRenderedLabel() throws {
        let size = NSSize(width: 480, height: 140)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.black.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSAttributedString(string: "Product Ideas", attributes: [
            .font: NSFont.systemFont(ofSize: 36, weight: .medium),
            .foregroundColor: NSColor.white,
        ]).draw(at: NSPoint(x: 40, y: 50))
        image.unlockFocus()
        let cg = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let lines = try TextRecognizer.lines(in: cg)
        XCTAssertTrue(lines.joined(separator: " ").contains("Product Ideas"), "\(lines)")
    }
}
