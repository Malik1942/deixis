import XCTest
@testable import Deixis

final class ColorPickerTests: XCTestCase {
    func testFormats() {
        let c = ColorValue(red: 0.1, green: 0.2, blue: 0.3, space: .sRGB)
        XCTAssertEqual(ColorPicker.format(c, as: .hex), "#1A334D")
        XCTAssertEqual(ColorPicker.format(c, as: .rgb), "rgb(26, 51, 77)")
        XCTAssertEqual(ColorPicker.format(c, as: .hsl), "hsl(210, 50%, 20%)")
        XCTAssertEqual(ColorPicker.format(c, as: .swiftUI), "Color(red: 0.100, green: 0.200, blue: 0.300)")
        let p3 = ColorValue(red: 1, green: 0, blue: 0, space: .displayP3)
        XCTAssertEqual(ColorPicker.format(p3, as: .swiftUI), "Color(.displayP3, red: 1.000, green: 0.000, blue: 0.000)")
        XCTAssertEqual(ColorPicker.format(ColorValue(red: 1, green: 0, blue: 0, space: .sRGB), as: .hsl), "hsl(0, 100%, 50%)")
        XCTAssertEqual(ColorPicker.format(ColorValue(red: 0.5, green: 0.5, blue: 0.5, space: .sRGB), as: .hsl), "hsl(0, 0%, 50%)")
    }

    func testConversionDiffersForSaturatedNotForGrey() {
        let red = ColorValue(red: 1, green: 0, blue: 0, space: .sRGB)
        let redP3 = ColorPicker.convert(red, to: .displayP3)
        XCTAssertEqual(redP3.space, .displayP3)
        XCTAssertLessThan(redP3.red, 0.95, "sRGB red sits inside P3, so its P3 red component is below 1")
        XCTAssertGreaterThan(redP3.green, 0.1)
        let grey = ColorValue(red: 0.5, green: 0.5, blue: 0.5, space: .sRGB)
        let greyP3 = ColorPicker.convert(grey, to: .displayP3)
        XCTAssertEqual(greyP3.red, 0.5, accuracy: 0.01)
        XCTAssertEqual(greyP3.blue, 0.5, accuracy: 0.01)
        XCTAssertEqual(ColorPicker.convert(red, to: .sRGB), red)
    }

    func testPixelRead() throws {
        var bytes: [UInt8] = [26, 51, 77, 255, 255, 255, 255, 255]
        let context = try XCTUnwrap(CGContext(data: &bytes, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                                              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try XCTUnwrap(context.makeImage())
        let color = try XCTUnwrap(ColorPicker.pixel(in: image, x: 0, y: 0, space: .sRGB))
        XCTAssertEqual(color.hex, "#1A334D")
        XCTAssertEqual(ColorPicker.pixel(in: image, x: 1, y: 0, space: .sRGB)?.hex, "#FFFFFF")
        XCTAssertNil(ColorPicker.pixel(in: image, x: 2, y: 0, space: .sRGB))
    }
}
