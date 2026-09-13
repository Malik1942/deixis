import XCTest
@testable import Deixis

final class MarkdownBuilderTests: XCTestCase {
    private func element(identifier: String? = "captureButton", role: String = "button", label: String? = "Capture",
                         source: IdentifierSource = .declared) -> ResolvedElement {
        ResolvedElement(
            role: role, rawRole: "AX" + role.prefix(1).uppercased() + role.dropFirst(), label: label,
            identifier: identifier, identifierSource: source, value: nil,
            frame: Frame(x: 312, y: 88, w: 64, h: 32),
            path: [PathEntry(role: "group", identifier: nil), PathEntry(role: "toolbar", identifier: nil), PathEntry(role: role, identifier: identifier)]
        )
    }

    private func capture(mode: CaptureMode = .fix, element: ResolvedElement?, note: String = "make this rounded") -> Capture {
        Capture(
            id: "20260912-140312-k7q2",
            createdAt: "2026-09-12T14:03:12-07:00",
            mode: mode,
            image: ImageInfo(path: "/Users/malik/Pictures/Deixis/deixis-simulator-20260912-140312-k7q2.png", widthPt: 144, heightPt: 112, scale: 2, crop: Frame(x: 272, y: 48, w: 144, h: 112)),
            source: SourceInfo(
                app: AppInfo(bundleId: "com.apple.iphonesimulator", name: "Simulator"),
                window: WindowInfo(title: "iPhone 17 Pro"),
                url: nil,
                simulator: SimulatorInfo(device: "iPhone 17 Pro", appBundleId: "com.malikzhang.oryne")
            ),
            element: element,
            note: note
        )
    }

    private func lines(_ md: String) -> [String] { md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) }

    // 1
    func testFixModeOrdering() {
        let md = MarkdownBuilder.build(capture(element: element()))
        let l = lines(md)
        XCTAssertEqual(l[0], "## Deixis capture (fix)")
        XCTAssertEqual(l[1], "Image: /Users/malik/Pictures/Deixis/deixis-simulator-20260912-140312-k7q2.png")
        XCTAssertEqual(l[2], "App: Simulator (com.malikzhang.oryne) · Window: iPhone 17 Pro")
        XCTAssertEqual(l[3], "Captured: 2026-09-12 14:03 · Image region: 144×112 pt @2x (element + 40 pt)")
        let element = try! XCTUnwrap(md.range(of: "### Target element"))
        let note = try! XCTUnwrap(md.range(of: "### Note"))
        XCTAssertLessThan(element.lowerBound, note.lowerBound)
        XCTAssertTrue(md.contains("button \"Capture\" · id=captureButton\n"))
        XCTAssertTrue(md.contains("Frame: x=312 y=88 w=64 h=32\n"))
        XCTAssertTrue(md.contains("Path: group > toolbar > button#captureButton\n"))
        XCTAssertTrue(md.hasSuffix("### Note\nmake this rounded\n"))
    }

    // 2
    func testReferenceModeLeadsWithNote() {
        let md = MarkdownBuilder.build(capture(mode: .reference, element: element(), note: "make mine like this"))
        let l = lines(md)
        XCTAssertEqual(l[0], "## Deixis capture (reference)")
        XCTAssertEqual(l[1], "### Note")
        XCTAssertEqual(l[2], "make mine like this")
        XCTAssertEqual(l[3], "")
        let note = md.range(of: "### Note")!, image = md.range(of: "Image: ")!, element = md.range(of: "### Target element")!
        XCTAssertLessThan(note.lowerBound, image.lowerBound)
        XCTAssertLessThan(image.lowerBound, element.lowerBound)
    }

    // 3
    func testNullElementRendersNoInformationBlock() {
        let md = MarkdownBuilder.build(capture(element: nil))
        XCTAssertTrue(md.contains("### Target element\nNo element information available (app exposes no accessibility tree). Use the image.\n"))
        XCTAssertTrue(md.contains("(around the click point)"))
        XCTAssertFalse(md.contains("Frame:"))
    }

    // 4
    func testEmptyNoteOmitsNoteSection() {
        XCTAssertFalse(MarkdownBuilder.build(capture(element: element(), note: "")).contains("### Note"))
        XCTAssertFalse(MarkdownBuilder.build(capture(element: element(), note: "  \n")).contains("### Note"))
    }

    // 5
    func testIdentifierWithHashAndQuotesIsNotEscaped() {
        let weird = "tab#2\"main\""
        let md = MarkdownBuilder.build(capture(element: element(identifier: weird)))
        XCTAssertTrue(md.contains("· id=tab#2\"main\"\n"))
        XCTAssertTrue(md.contains("> button#tab#2\"main\"\n"))
        XCTAssertFalse(md.contains("\\\""))
    }

    // 6
    func testSymbolNameCaveat() {
        let symbol = MarkdownBuilder.build(capture(element: element(identifier: "plus", role: "image", label: nil, source: .possiblySymbolName)))
        XCTAssertTrue(symbol.contains("image · id=plus (may be a symbol name, not a declared identifier)\n"))
        let declared = MarkdownBuilder.build(capture(element: element()))
        XCTAssertFalse(declared.contains("may be a symbol name"))
    }

    // 7
    func testNullIdentifierRendersHint() {
        let md = MarkdownBuilder.build(capture(element: element(identifier: nil, source: .unknown)))
        XCTAssertTrue(md.contains("button \"Capture\" · no identifier\nNo identifier. Grep the label text; add .accessibilityIdentifier(\"…\") to this view so the next capture is exact.\n"))
        XCTAssertTrue(md.contains("Path: group > toolbar > button\n"))
    }

    func testCaptureJSONRoundTripsWithExplicitNulls() throws {
        let c = capture(element: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(c)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue(json["element"] is NSNull)
        XCTAssertTrue(json["ocr"] is NSNull)
        XCTAssertEqual((json["iterations"] as? [Any])?.count, 0)
        let source = try XCTUnwrap(json["source"] as? [String: Any])
        XCTAssertTrue(source["url"] is NSNull)
        let decoded = try JSONDecoder().decode(Capture.self, from: data)
        XCTAssertEqual(decoded, c)

        let withElement = capture(element: element(identifier: nil, source: .unknown))
        let json2 = try XCTUnwrap(JSONSerialization.jsonObject(with: try encoder.encode(withElement)) as? [String: Any])
        let el = try XCTUnwrap(json2["element"] as? [String: Any])
        XCTAssertTrue(el["identifier"] is NSNull)
        XCTAssertTrue(el["value"] is NSNull)
        XCTAssertEqual(el["rawRole"] as? String, "AXButton")
    }
}
