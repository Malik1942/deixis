import CoreGraphics
import XCTest
@testable import Deixis

final class GeometryTests: XCTestCase {
    let primaryHeight: CGFloat = 1329

    // 1
    func testPointFlipRoundTrips() {
        let appKit = CGPoint(x: 228, y: 402)
        let cg = Geometry.cgPoint(fromAppKit: appKit, primaryHeight: primaryHeight)
        XCTAssertEqual(cg, CGPoint(x: 228, y: 927))
        XCTAssertEqual(Geometry.appKitPoint(fromCG: cg, primaryHeight: primaryHeight), appKit)
    }

    // 2
    func testRectFlip() {
        let cg = CGRect(x: 43, y: 893, width: 370, height: 50)
        let appKit = Geometry.appKitRect(fromCG: cg, primaryHeight: primaryHeight)
        XCTAssertEqual(appKit, CGRect(x: 43, y: 1329 - 943, width: 370, height: 50))
        XCTAssertEqual(Geometry.cgRect(fromAppKit: appKit, primaryHeight: primaryHeight), cg)
    }

    // 3
    func testCropPadsAndClampsToWindowThenDisplay() {
        let display = CGRect(x: 0, y: 0, width: 2056, height: 1329)
        let window = CGRect(x: 0, y: 101, width: 456, height: 972)
        let element = CGRect(x: 43, y: 893, width: 370, height: 50)
        let crop = Geometry.cropRect(element: element, clickPoint: .zero, window: window, display: display)
        // x clamps at the window's left edge (43 - 40 = 3 stays inside), right edge 413 + 40 = 453 stays inside
        XCTAssertEqual(crop, CGRect(x: 3, y: 853, width: 450, height: 130))

        let nearEdge = CGRect(x: 10, y: 110, width: 100, height: 20)
        let clamped = Geometry.cropRect(element: nearEdge, clickPoint: .zero, window: window, display: display)
        XCTAssertEqual(clamped, CGRect(x: 0, y: 101, width: 150, height: 69))

        let noElement = Geometry.cropRect(element: nil, clickPoint: CGPoint(x: 228, y: 927), window: window, display: display)
        XCTAssertEqual(noElement, CGRect(x: 128, y: 827, width: 200, height: 200))

        let topOfDisplay = Geometry.cropRect(element: CGRect(x: 100, y: 0, width: 50, height: 10), clickPoint: .zero, window: nil, display: display)
        XCTAssertEqual(topOfDisplay, CGRect(x: 60, y: 0, width: 130, height: 50))
    }

    // 4
    func testPixelRectOnSecondaryDisplayWithNegativeOrigin() {
        let secondary = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        let rect = CGRect(x: -1000, y: 300, width: 200, height: 100)
        XCTAssertEqual(Geometry.displayLocalRect(rect, inDisplay: secondary), CGRect(x: 920, y: 500, width: 200, height: 100))
        XCTAssertEqual(Geometry.pixelRect(rect, inDisplay: secondary, scale: 2), CGRect(x: 1840, y: 1000, width: 400, height: 200))
    }

    // 5
    func testWindowHitTestSkipsOwnWindowsAndNonZeroLayers() {
        let point = CGPoint(x: 228, y: 927)
        let windows: [Geometry.WindowRecord] = [
            .init(ownerPID: 999, layer: 1000, bounds: CGRect(x: 0, y: 0, width: 2056, height: 1329)), // Deixis overlay
            .init(ownerPID: 500, layer: 25, bounds: CGRect(x: 0, y: 0, width: 2056, height: 24)),     // menu bar
            .init(ownerPID: 45450, layer: 0, bounds: CGRect(x: 0, y: 101, width: 456, height: 972)),  // Simulator
            .init(ownerPID: 777, layer: 0, bounds: CGRect(x: 0, y: 0, width: 2056, height: 1329)),   // app behind
        ]
        XCTAssertEqual(Geometry.windowOwner(at: point, windows: windows, excludingPID: 999)?.ownerPID, 45450)
        XCTAssertEqual(Geometry.windowOwner(at: CGPoint(x: 1500, y: 700), windows: windows, excludingPID: 999)?.ownerPID, 777)
        XCTAssertNil(Geometry.windowOwner(at: point, windows: [windows[0], windows[1]], excludingPID: 999))
    }
}
