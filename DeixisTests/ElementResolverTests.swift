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

    func testRetryReReadsAFirstContainerHitOnce() async throws {
        let container = ElementSnapshot(element: AttributeSet(role: "AXGroup", frame: Frame(x: 0, y: 0, w: 1448, h: 944), childCount: 40), ancestors: [])
        let refined = ScriptedProvider(script: [container, try fixture("swiftui-button")])
        let e = await ElementResolver.resolve(at: .zero, using: refined, retries: 5, delay: .zero)
        XCTAssertEqual(e?.identifier, "captureButton")
        let calls = await refined.calls
        XCTAssertEqual(calls, 2)

        let stubborn = ScriptedProvider(script: [container, container])
        let f = await ElementResolver.resolve(at: .zero, using: stubborn, retries: 1, delay: .zero)
        XCTAssertEqual(f?.role, "group", "a container that stays a container is still the answer")
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

    // R2 hover precision
    private func node(_ role: String, id: String? = nil, x: Double, y: Double, w: Double, h: Double) -> AttributeSet {
        AttributeSet(role: role, identifier: id, frame: Frame(x: x, y: y, w: w, h: h), childCount: 0)
    }

    func testRefinerPicksSmallestControlNearPoint() {
        let window = node("AXGroup", x: 0, y: 0, w: 456, h: 900)
        let candidates = [
            node("AXGroup", id: "content", x: 0, y: 0, w: 456, h: 900),   // same size as base: never
            node("AXToolbar", x: 0, y: 840, w: 456, h: 60),               // container, near
            node("AXButton", id: "capture", x: 43, y: 850, w: 370, h: 40), // control, 5 pt away
            node("AXButton", id: "far", x: 43, y: 700, w: 370, h: 40),     // control, far
        ]
        let point = CGPoint(x: 228, y: 895) // 5 pt below the capture button
        XCTAssertEqual(HitRefiner.choose(from: candidates, replacing: window, at: point)?.identifier, "capture")
    }

    func testRefinerFallsBackToSmallerContainerThenNil() {
        let window = node("AXGroup", x: 0, y: 0, w: 456, h: 900)
        let toolbar = node("AXToolbar", x: 0, y: 840, w: 456, h: 60)
        let button = node("AXButton", id: "capture", x: 43, y: 850, w: 100, h: 40)
        XCTAssertNil(HitRefiner.choose(from: [toolbar, button], replacing: window, at: CGPoint(x: 228, y: 895))?.identifier)
        XCTAssertEqual(HitRefiner.choose(from: [toolbar, button], replacing: window, at: CGPoint(x: 228, y: 895))?.role, "AXToolbar")
        XCTAssertNil(HitRefiner.choose(from: [toolbar, button], replacing: window, at: CGPoint(x: 228, y: 400)), "blank area keeps the container")
    }

    func testStickinessKeepsControlsNotContainers() throws {
        let button = try XCTUnwrap(ElementResolver.resolve(try fixture("swiftui-button"))) // 43,893.67 370×50.33
        XCTAssertTrue(HitRefiner.sticks(button, to: CGPoint(x: 228, y: 950)))   // 6 pt below
        XCTAssertFalse(HitRefiner.sticks(button, to: CGPoint(x: 228, y: 970)))  // 26 pt below
        let group = try XCTUnwrap(ElementResolver.resolve(try fixture("empty-group")))
        XCTAssertFalse(HitRefiner.sticks(group, to: CGPoint(x: 100, y: 300)))
        XCTAssertFalse(HitRefiner.sticks(nil, to: .zero))
    }

    func testAncestorDepthReRootsSnapshot() throws {
        let snapshot = try fixture("swiftui-button")
        let parent = try XCTUnwrap(HitRefiner.ancestor(of: snapshot, depth: 1))
        XCTAssertEqual(ElementResolver.resolve(parent)?.role, "group")
        XCTAssertEqual(parent.ancestors.count, 2)
        XCTAssertEqual(ElementResolver.resolve(try XCTUnwrap(HitRefiner.ancestor(of: snapshot, depth: 3)))?.role, "window")
        XCTAssertNil(HitRefiner.ancestor(of: snapshot, depth: 4))
        XCTAssertEqual(HitRefiner.ancestor(of: snapshot, depth: 0), snapshot)
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
