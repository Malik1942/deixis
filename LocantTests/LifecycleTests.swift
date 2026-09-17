import XCTest
@testable import Locant

final class LifecycleTests: XCTestCase {
    private func entry(daysOld: Double, pinned: Bool = false, resolved: Bool = false, now: Date) -> LifecycleEntry {
        LifecycleEntry(urls: [URL(filePath: "/tmp/locant-\(daysOld).png")], modified: now.addingTimeInterval(-daysOld * 86_400), pinned: pinned, resolved: resolved)
    }

    func testStaleKeepsPinnedResolvedAndRecent() {
        let now = Date()
        let old = entry(daysOld: 40, now: now)
        let recent = entry(daysOld: 10, now: now)
        let pinned = entry(daysOld: 40, pinned: true, now: now)
        let resolved = entry(daysOld: 40, resolved: true, now: now)
        XCTAssertEqual(Lifecycle.stale([old, recent, pinned, resolved], retentionDays: 30, now: now), [old])
        XCTAssertEqual(Lifecycle.stale([old, recent, pinned, resolved], retentionDays: 0, now: now), [])
        XCTAssertEqual(Lifecycle.stale([old, recent], retentionDays: 7, now: now), [old, recent])
    }

    func testExtraImagesOfASetGoAndStayWithTheirCapture() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "LocantLifecycle-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let base = "locant-simulator-20260810-120000-abcd"
        try Data([1]).write(to: dir.appending(path: "\(base).png"))
        try #"{"resolved": true}"#.data(using: .utf8)!.write(to: dir.appending(path: "\(base).json"))
        try Data([1]).write(to: dir.appending(path: "\(base)-2.png"))
        try Data([1]).write(to: dir.appending(path: "\(base)-3.png"))
        // A Snap named like a capture with a number is not an extra: no sidecar at the stem.
        try Data([1]).write(to: dir.appending(path: "locant-snap-figma-20260901-120000-efgh-2.png"))

        let entries = Lifecycle.entries(in: dir).sorted { $0.urls[0].lastPathComponent < $1.urls[0].lastPathComponent }
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].urls.map(\.lastPathComponent), ["\(base).png", "\(base).json", "\(base)-2.png", "\(base)-3.png"])
        XCTAssertTrue(entries[0].resolved, "the extras inherit the capture's resolved flag by riding in its entry")
        XCTAssertEqual(entries[1].urls.count, 1)
        XCTAssertEqual(Lifecycle.captureBase(ofExtraImage: "/x/\(base)-2"), "/x/\(base)")
        XCTAssertNil(Lifecycle.captureBase(ofExtraImage: "/x/\(base)"))
        XCTAssertNil(Lifecycle.captureBase(ofExtraImage: "/x/locant-snap-figma-2"))
    }

    func testEntriesGroupSidecarsAndReadPinAndResolved() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "LocantLifecycle-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appending(path: "2026-08")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let png = sub.appending(path: "locant-simulator-20260810-120000-abcd.png")
        let json = sub.appending(path: "locant-simulator-20260810-120000-abcd.json")
        try Data([1]).write(to: png)
        try #"{"resolved": true}"#.data(using: .utf8)!.write(to: json)
        let snap = dir.appending(path: "locant-snap-figma-20260901-120000-efgh.png")
        try Data([1]).write(to: snap)
        Lifecycle.pin([snap])
        try Data([1]).write(to: dir.appending(path: "unrelated.png"))

        let entries = Lifecycle.entries(in: dir).sorted { $0.urls[0].lastPathComponent < $1.urls[0].lastPathComponent }
        XCTAssertEqual(entries.count, 2)
        // "locant-simulator…" sorts before "locant-snap…"
        XCTAssertEqual(entries[0].urls.map(\.lastPathComponent), [png.lastPathComponent, json.lastPathComponent])
        XCTAssertTrue(entries[0].resolved)
        XCTAssertFalse(entries[0].pinned)
        XCTAssertEqual(entries[1].urls.count, 1)
        XCTAssertTrue(entries[1].pinned)
        XCTAssertTrue(Lifecycle.isPinned(snap))
        XCTAssertEqual(Lifecycle.newest(in: dir)?.urls.first?.lastPathComponent, snap.lastPathComponent)
    }
}
