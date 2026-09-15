import XCTest
@testable import Deixis

final class UpdateCheckTests: XCTestCase {
    private let latestJSON = """
    {
      "url": "https://api.github.com/repos/Malik1942/deixis/releases/1",
      "html_url": "https://github.com/Malik1942/deixis/releases/tag/v0.7",
      "tag_name": "v0.7",
      "name": "Deixis 0.7.0",
      "draft": false,
      "prerelease": false,
      "assets": [
        {
          "name": "Deixis.dmg",
          "content_type": "application/octet-stream",
          "size": 3818682,
          "download_count": 12,
          "browser_download_url": "https://github.com/Malik1942/deixis/releases/download/v0.7/Deixis.dmg"
        }
      ],
      "body": "Notes"
    }
    """.data(using: .utf8)!

    // 1
    func testVersionParsing() {
        XCTAssertEqual(AppVersion("0.6.0")?.components, [0, 6, 0])
        XCTAssertEqual(AppVersion("v0.6")?.components, [0, 6])
        XCTAssertEqual(AppVersion(" 1.2.3-beta.1 ")?.components, [1, 2, 3])
        XCTAssertEqual(AppVersion("1.2.3+45")?.components, [1, 2, 3])
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("v"))
        XCTAssertNil(AppVersion("1..2"))
        XCTAssertNil(AppVersion("main"))
    }

    // 2
    func testVersionOrdering() {
        XCTAssertLessThan(AppVersion("0.9.1")!, AppVersion("0.10.0")!)
        XCTAssertLessThan(AppVersion("0.5")!, AppVersion("0.5.1")!)
        XCTAssertEqual(AppVersion("0.6")!, AppVersion("0.6.0")!)
        XCTAssertFalse(AppVersion("0.6.0")! < AppVersion("v0.6")!)
        XCTAssertGreaterThan(AppVersion("1.0")!, AppVersion("0.99.99")!)
        XCTAssertEqual(AppVersion("0.6.0")!.description, "0.6.0")
    }

    // 3
    func testReleaseDecoding() throws {
        let release = try GitHubRelease.decode(latestJSON)
        XCTAssertEqual(release.tagName, "v0.7")
        XCTAssertEqual(release.version, AppVersion("0.7.0"))
        XCTAssertEqual(release.downloadURL.absoluteString, "https://github.com/Malik1942/deixis/releases/download/v0.7/Deixis.dmg")
    }

    // 4
    func testReleaseWithoutDmgOpensThePage() throws {
        let json = """
        {"tag_name": "v0.7", "html_url": "https://github.com/Malik1942/deixis/releases/tag/v0.7", "assets": [{"name": "notes.txt", "browser_download_url": "https://example.com/notes.txt"}]}
        """.data(using: .utf8)!
        let release = try GitHubRelease.decode(json)
        XCTAssertEqual(release.downloadURL.absoluteString, "https://github.com/Malik1942/deixis/releases/tag/v0.7")
    }

    // 5
    func testOutcome() throws {
        let release = try GitHubRelease.decode(latestJSON)
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.6.0")!, skipped: nil), .available(release))
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.7.0")!, skipped: nil), .upToDate)
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.8.0")!, skipped: nil), .upToDate)
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.6.0")!, skipped: "0.7.0"), .skipped(release))
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.6.0")!, skipped: "v0.7"), .skipped(release))
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.6.0")!, skipped: "0.6.5"), .available(release))
    }

    // 6
    func testUnparsableTagIsUpToDate() throws {
        let json = """
        {"tag_name": "nightly", "html_url": "https://github.com/Malik1942/deixis/releases", "assets": []}
        """.data(using: .utf8)!
        let release = try GitHubRelease.decode(json)
        XCTAssertEqual(UpdateCheck.outcome(latest: release, current: AppVersion("0.6.0")!, skipped: nil), .upToDate)
    }

    // 7
    func testDailyLimit() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(UpdateCheck.isDue(lastCheck: nil, now: now))
        XCTAssertFalse(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-3600), now: now))
        XCTAssertFalse(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-UpdateCheck.interval + 1), now: now))
        XCTAssertTrue(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-UpdateCheck.interval), now: now))
        XCTAssertTrue(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-3 * UpdateCheck.interval), now: now))
    }

    // 8
    func testRequestCarriesOnlyTheVersion() {
        let request = UpdateCheck.request(current: AppVersion("0.6.0"))
        XCTAssertEqual(request.url, UpdateCheck.endpoint)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "Deixis/0.6.0")
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 2)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.timeoutInterval, UpdateCheck.timeout)
    }
}
