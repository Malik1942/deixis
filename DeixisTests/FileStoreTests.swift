import XCTest
@testable import Deixis

final class FileStoreTests: XCTestCase {
    // 1
    func testSlug() {
        XCTAssertEqual(FileStore.slug("Simulator"), "simulator")
        XCTAssertEqual(FileStore.slug("Google Chrome"), "googlechrome")
        XCTAssertEqual(FileStore.slug("My Very Long Application Name"), "myverylongapplic")
        XCTAssertEqual(FileStore.slug("!!!"), "app")
    }

    // 2
    func testIDShape() throws {
        let date = Date(timeIntervalSince1970: 1_789_000_000)
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        let id = FileStore.makeID(date: date, timeZone: tz, suffix: "k7q2")
        let regex = try NSRegularExpression(pattern: "^[0-9]{8}-[0-9]{6}-[a-z0-9]{4}$")
        XCTAssertEqual(regex.numberOfMatches(in: id, range: NSRange(id.startIndex..., in: id)), 1, id)
        XCTAssertTrue(id.hasSuffix("-k7q2"))
        XCTAssertEqual(FileStore.randomSuffix().count, 4)
        XCTAssertEqual(FileStore.isoTimestamp(date: date, timeZone: tz).count, "2026-09-12T14:03:12-07:00".count)
        XCTAssertTrue(FileStore.isoTimestamp(date: date, timeZone: tz).hasPrefix(String(FileStore.stamp(date: date, timeZone: tz).prefix(4))))
    }

    func testWriteProducesPNGAndSidecarWithPath() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "DeixisTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = FileStore(directory: dir)
        let capture = Capture(
            id: "20260912-140312-k7q2", createdAt: "2026-09-12T14:03:12-07:00", mode: .fix,
            image: ImageInfo(path: "", widthPt: 10, heightPt: 10, scale: 2, crop: nil),
            source: SourceInfo(app: AppInfo(bundleId: "com.apple.iphonesimulator", name: "Simulator"), window: nil, url: nil, simulator: nil),
            element: nil, note: ""
        )
        let written = try store.write(png: Data([0x89, 0x50, 0x4E, 0x47]), capture: capture)
        XCTAssertEqual(written.image.path, dir.appending(path: "deixis-simulator-20260912-140312-k7q2.png").path(percentEncoded: false))
        XCTAssertTrue(FileManager.default.fileExists(atPath: written.image.path))
        let json = try Data(contentsOf: dir.appending(path: "deixis-simulator-20260912-140312-k7q2.json"))
        let decoded = try JSONDecoder().decode(Capture.self, from: json)
        XCTAssertEqual(decoded, written)
    }
}
