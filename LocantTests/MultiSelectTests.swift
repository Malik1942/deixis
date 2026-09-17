import CoreGraphics
import XCTest
@testable import Locant

/// v0.8 R58: a set selected with Shift.
final class MultiSelectTests: XCTestCase {
    private func element(_ role: String, id: String?, label: String? = nil, frame: Frame) -> ResolvedElement {
        ResolvedElement(role: role, rawRole: "AX" + role.capitalized, label: label, identifier: id,
                        identifierSource: id == nil ? .unknown : .declared, value: nil, frame: frame,
                        path: [PathEntry(role: "window", identifier: nil), PathEntry(role: role, identifier: id)])
    }

    private func capture(_ targets: [CaptureTarget], mode: CaptureMode = .fix) -> Capture {
        Capture(
            id: "20260916-120000-ab12", createdAt: "2026-09-16T12:00:00-07:00", mode: mode,
            image: ImageInfo(path: "/tmp/a.png", widthPt: 500, heightPt: 300, scale: 2, crop: nil),
            source: SourceInfo(app: AppInfo(bundleId: "com.apple.iphonesimulator", name: "Simulator"), window: WindowInfo(title: "iPhone 17 Pro"), url: nil, simulator: nil),
            element: targets[0].element, note: "make this match that", targets: targets
        )
    }

    func testMarkdownNumbersTheSetAndNamesOtherApps() {
        let a = CaptureTarget(element: element("button", id: "captureButton", frame: Frame(x: 43, y: 894, w: 370, h: 50)),
                              app: AppInfo(bundleId: "com.apple.iphonesimulator", name: "Simulator"), window: WindowInfo(title: "iPhone 17 Pro"))
        let b = CaptureTarget(element: element("button", id: nil, label: "Checkout", frame: Frame(x: 1200, y: 700, w: 200, h: 44)),
                              app: AppInfo(bundleId: "company.thebrowser.dia", name: "Dia"), window: WindowInfo(title: "Cart"), url: "https://shop.example.com/cart", imagePath: "/tmp/a-2.png")
        let md = MarkdownBuilder.build(capture([a, b]))
        XCTAssertTrue(md.contains("### Element 1 (this)\nbutton · id=captureButton\n"), md)
        XCTAssertTrue(md.contains("### Element 2 (that)\nApp: Dia (company.thebrowser.dia) · Window: Cart\nURL: https://shop.example.com/cart\nImage: /tmp/a-2.png\nbutton \"Checkout\" · no identifier\n"), md)
        XCTAssertFalse(md.contains("### Target element"))
        XCTAssertTrue(md.contains("the others have their own images"), md)
        XCTAssertTrue(md.contains("### Note\nmake this match that"))
    }

    func testThirdElementHasNoPronoun() {
        let t = (0..<3).map { i in CaptureTarget(element: element("button", id: "b\(i)", frame: Frame(x: Double(i) * 100, y: 0, w: 50, h: 20)),
                                                   app: AppInfo(bundleId: "com.apple.iphonesimulator", name: "Simulator"), window: WindowInfo(title: "iPhone 17 Pro")) }
        let md = MarkdownBuilder.build(capture(t))
        XCTAssertTrue(md.contains("### Element 3\nbutton · id=b2"), md)
        XCTAssertTrue(md.contains("3 elements + 40 pt"), md)
        XCTAssertEqual(md.components(separatedBy: "App: Simulator").count - 1, 1, "same app and window as the source: only the source names it")
    }

    func testSidecarRoundTripsTargets() throws {
        let a = CaptureTarget(element: element("button", id: "x", frame: Frame(x: 0, y: 0, w: 10, h: 10)), app: AppInfo(bundleId: "a", name: "A"), window: nil)
        let b = CaptureTarget(element: element("image", id: nil, frame: Frame(x: 50, y: 0, w: 10, h: 10)), app: AppInfo(bundleId: "b", name: "B"), window: WindowInfo(title: "W"), url: "http://localhost:3000/", imagePath: "/tmp/x-2.png")
        let data = try JSONEncoder().encode(capture([a, b]))
        let back = try JSONDecoder().decode(Capture.self, from: data)
        XCTAssertEqual(back.targets, [a, b])
        XCTAssertEqual(back.element, a.element)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("\"targets\""))
    }

    func testSingleElementCaptureHasNoTargetsKey() throws {
        var c = capture([CaptureTarget(element: element("button", id: "x", frame: Frame(x: 0, y: 0, w: 10, h: 10)), app: AppInfo(bundleId: "a", name: "A"), window: nil)])
        c.targets = nil
        let text = String(decoding: try JSONEncoder().encode(c), as: UTF8.self)
        XCTAssertFalse(text.contains("targets"))
    }

    func testCropRectsUnionWhenTheSetFitsOneDisplay() {
        let display = CGRect(x: 0, y: 0, width: 2000, height: 1200)
        let frames = [CGRect(x: 100, y: 100, width: 200, height: 50), CGRect(x: 600, y: 300, width: 100, height: 100)]
        let rects = Geometry.cropRects(for: frames, display: display, displayFor: { _ in display })
        XCTAssertEqual(rects, [CGRect(x: 60, y: 60, width: 680, height: 380)])
    }

    func testCropRectsSplitWhenTheUnionIsMostOfTheDisplay() {
        let display = CGRect(x: 0, y: 0, width: 2000, height: 1200)
        let frames = [CGRect(x: 50, y: 50, width: 100, height: 100), CGRect(x: 1800, y: 1000, width: 100, height: 100)]
        let rects = Geometry.cropRects(for: frames, display: display, displayFor: { _ in display })
        XCTAssertEqual(rects.count, 2)
        XCTAssertEqual(rects[0], CGRect(x: 10, y: 10, width: 180, height: 180))
        XCTAssertEqual(rects[1], CGRect(x: 1760, y: 960, width: 180, height: 180))
    }

    func testCropRectsSplitAcrossDisplays() {
        let main = CGRect(x: 0, y: 0, width: 2000, height: 1200)
        let second = CGRect(x: 2000, y: 0, width: 1000, height: 1000)
        let frames = [CGRect(x: 100, y: 100, width: 100, height: 100), CGRect(x: 2100, y: 100, width: 100, height: 100)]
        let rects = Geometry.cropRects(for: frames, display: main, displayFor: { $0.x >= 2000 ? second : main })
        XCTAssertEqual(rects.count, 2)
        XCTAssertEqual(rects[1], CGRect(x: 2060, y: 60, width: 180, height: 180))
    }

    func testExtraImageIsNamedBesideTheCapture() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "locant-multiselect-\(UUID().uuidString)")
        let store = FileStore(directory: dir)
        let c = capture([CaptureTarget(element: element("button", id: "x", frame: Frame(x: 0, y: 0, w: 10, h: 10)), app: AppInfo(bundleId: "a", name: "Simulator"), window: nil)])
        let url = try store.writeExtraImage(png: Data([0x89, 0x50]), capture: c, index: 2)
        XCTAssertEqual(url.lastPathComponent, "locant-simulator-20260916-120000-ab12-2.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        try? FileManager.default.removeItem(at: dir)
    }
}
