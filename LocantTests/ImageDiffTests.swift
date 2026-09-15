import AppKit
import XCTest
@testable import Locant

final class ImageDiffTests: XCTestCase {
    /// A solid image with an optional block of another color.
    private func image(width: Int = 40, height: Int = 40, fill: (r: UInt8, g: UInt8, b: UInt8) = (200, 200, 200),
                       block: (x: Int, y: Int, w: Int, h: Int, r: UInt8, g: UInt8, b: UInt8)? = nil) -> CGImage {
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                var (r, g, b) = fill
                if let block, x >= block.x, x < block.x + block.w, y >= block.y, y < block.y + block.h { (r, g, b) = (block.r, block.g, block.b) }
                bytes[i] = r; bytes[i + 1] = g; bytes[i + 2] = b
            }
        }
        let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return context.makeImage()!
    }

    private func png(_ image: CGImage) -> Data {
        NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    }

    // 1
    func testSameImageIsNoChange() {
        let a = image()
        XCTAssertFalse(ImageDiff.differs(a, image()))
        XCTAssertFalse(ImageDiff.differs(png: png(a), png: png(image())))
    }

    // 2
    func testMovedBlockIsAChange() {
        let a = image(block: (5, 5, 10, 10, 20, 20, 20))
        let b = image(block: (15, 5, 10, 10, 20, 20, 20))
        XCTAssertTrue(ImageDiff.differs(a, b))
        XCTAssertTrue(ImageDiff.differs(png: png(a), png: png(b)))
    }

    // 3
    func testAFewPixelsAreNotAChange() {
        // 4 of 1600 pixels (0.25%) is under the 0.5% line: a caret, not an edit.
        let a = image()
        let b = image(block: (10, 10, 2, 2, 0, 0, 0))
        XCTAssertFalse(ImageDiff.differs(a, b))
    }

    // 4
    func testSubtleShadeIsNotAChange() {
        XCTAssertFalse(ImageDiff.differs(image(fill: (200, 200, 200)), image(fill: (210, 190, 205))))
        XCTAssertTrue(ImageDiff.differs(image(fill: (200, 200, 200)), image(fill: (150, 200, 200))))
    }

    // 5
    func testSizeChangeIsAChange() {
        XCTAssertTrue(ImageDiff.differs(image(width: 40, height: 40), image(width: 40, height: 41)))
    }

    // 6
    func testUnreadableDataIsAChange() {
        XCTAssertTrue(ImageDiff.differs(png: Data([1, 2, 3]), png: png(image())))
    }
}
