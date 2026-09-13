import CoreGraphics
import XCTest
@testable import Deixis

final class ElementResolverTests: XCTestCase {
    private func fixture(_ name: String) throws -> ElementSnapshot {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json"), "fixture \(name)")
        return try JSONDecoder().decode(ElementSnapshot.self, from: Data(contentsOf: url))
    }

    // 1
    func testSwiftUIButtonWithIdentifier() throws {
        let e = try XCTUnwrap(ElementResolver.resolve(try fixture("swiftui-button")))
        XCTAssertEqual(e.role, "button")
        XCTAssertEqual(e.rawRole, "AXButton")
        XCTAssertEqual(e.identifier, "captureButton")
        XCTAssertEqual(e.label, "Capture")
        XCTAssertEqual(e.frame, Frame(x: 43, y: 893.6667, w: 370, h: 50.3333))
    }

    // 2
    func testAppKitTextFieldWithoutIdentifier() throws {
        let e = try XCTUnwrap(ElementResolver.resolve(try fixture("appkit-textfield")))
        XCTAssertEqual(e.role, "textField")
        XCTAssertNil(e.identifier)
        XCTAssertEqual(e.identifierSource, .unknown)
        XCTAssertEqual(e.label, "Name")
        XCTAssertEqual(e.value, .string("Malik"))
    }

    // 3
    func testUnknownRoleKeepsRawRole() throws {
        let e = try XCTUnwrap(ElementResolver.resolve(try fixture("unknown-role")))
        XCTAssertEqual(e.role, "unknown")
        XCTAssertEqual(e.rawRole, "AXCustomThing")
    }

    // 4
    func testPathTruncatesAtSixAncestorsRootFirst() throws {
        let e = try XCTUnwrap(ElementResolver.resolve(try fixture("deep-path")))
        XCTAssertEqual(e.path.count, 7)
        XCTAssertEqual(e.path.map(\.identifier), ["a6", "a5", "a4", "a3", "a2", "a1", "leaf"])
        XCTAssertEqual(e.path[2].role, "toolbar")
        XCTAssertEqual(e.path.last?.role, "button")
    }

    // 5
    func testMissingFrameReturnsNil() throws {
        XCTAssertNil(ElementResolver.resolve(try fixture("missing-frame")))
    }

    // 6
    func testSimulatorPathIncludesWindowAndResolvesIdentifier() throws {
        let e = try XCTUnwrap(ElementResolver.resolve(try fixture("simulator-path")))
        XCTAssertEqual(e.identifier, "captureButton")
        XCTAssertEqual(e.identifierSource, .declared)
        XCTAssertTrue(e.path.contains { $0.role == "window" })
        XCTAssertEqual(e.path.first?.role, "application", "five ancestors fit, so the root is the Simulator app")
        XCTAssertEqual(e.path[1].role, "window")
        XCTAssertEqual(e.path.count, 6)
    }

    // 7
    func testRetryReturnsPopulatedReadAfterEmptyOnes() async throws {
        let provider = ScriptedProvider(script: [nil, try fixture("empty-group"), try fixture("swiftui-button")])
        let e = await ElementResolver.resolve(at: CGPoint(x: 228, y: 927), using: provider, retries: 5, delay: .zero)
        XCTAssertEqual(e?.identifier, "captureButton")
        let calls = await provider.calls
        XCTAssertEqual(calls, 3)
    }

    func testRetryGivesUpAfterRetriesAndReturnsNil() async throws {
        let provider = ScriptedProvider(script: [])
        let e = await ElementResolver.resolve(at: .zero, using: provider, retries: 2, delay: .zero)
        XCTAssertNil(e)
        let calls = await provider.calls
        XCTAssertEqual(calls, 3, "one read plus two retries")
    }

    // 8
    func testIdentifierSourceForSymbolImageAndDeclaredButton() throws {
        let image = try XCTUnwrap(ElementResolver.resolve(try fixture("symbol-image")))
        XCTAssertEqual(image.role, "image")
        XCTAssertEqual(image.identifier, "plus")
        XCTAssertEqual(image.identifierSource, .possiblySymbolName)

        let button = try XCTUnwrap(ElementResolver.resolve(try fixture("swiftui-button")))
        XCTAssertEqual(button.identifierSource, .declared)

        XCTAssertEqual(ElementResolver.identifierSource(role: "image", identifier: "person.crop.circle"), .possiblySymbolName)
        XCTAssertEqual(ElementResolver.identifierSource(role: "image", identifier: "avatarImage"), .declared)
        XCTAssertEqual(ElementResolver.identifierSource(role: "button", identifier: "plus"), .declared)
        XCTAssertEqual(ElementResolver.identifierSource(role: "image", identifier: ""), .unknown)
    }

    func testModeClassifier() {
        func source(app: String, simApp: String? = nil, url: String? = nil) -> SourceInfo {
            SourceInfo(
                app: AppInfo(bundleId: app, name: "x"),
                window: nil,
                url: url,
                simulator: app == ModeClassifier.simulatorBundleId ? SimulatorInfo(device: "iPhone", appBundleId: simApp) : nil
            )
        }
        let mine = ["com.example.mine"]
        XCTAssertEqual(ModeClassifier.classify(source(app: "com.example.mine"), myApps: mine), .fix)
        XCTAssertEqual(ModeClassifier.classify(source(app: "com.figma.Desktop"), myApps: mine), .reference)
        XCTAssertEqual(ModeClassifier.classify(source(app: ModeClassifier.simulatorBundleId, simApp: "com.example.mine"), myApps: mine), .fix)
        XCTAssertEqual(ModeClassifier.classify(source(app: ModeClassifier.simulatorBundleId, simApp: "com.other.app"), myApps: mine), .reference)
        XCTAssertEqual(ModeClassifier.classify(source(app: ModeClassifier.simulatorBundleId, simApp: nil), myApps: mine), .fix)
        XCTAssertEqual(ModeClassifier.classify(source(app: "com.apple.Safari", url: "http://localhost:3000/x"), myApps: mine), .fix)
        XCTAssertEqual(ModeClassifier.classify(source(app: "com.apple.Safari", url: "https://example.com"), myApps: mine), .reference)
    }
}

/// Returns scripted snapshots in order, then nil forever. Counts calls.
actor ScriptedProvider: ElementProvider {
    private var script: [ElementSnapshot?]
    private(set) var calls = 0

    init(script: [ElementSnapshot?]) { self.script = script }

    func snapshot(at point: CGPoint) async -> ElementSnapshot? {
        calls += 1
        return script.isEmpty ? nil : script.removeFirst()
    }
}
