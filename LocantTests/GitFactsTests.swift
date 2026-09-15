import XCTest
@testable import Locant

final class GitFactsTests: XCTestCase {
    func testSummaryLineAndFileList() {
        let stat = " Oryne/A.swift | 12 ++++---\n Oryne/B.swift |  4 +-\n 2 files changed, 12 insertions(+), 4 deletions(-)\n"
        XCTAssertEqual(GitFacts.summaryLine(of: stat), "2 files changed, 12 insertions(+), 4 deletions(-)")
        XCTAssertNil(GitFacts.summaryLine(of: nil))
        XCTAssertNil(GitFacts.summaryLine(of: ""))
        XCTAssertEqual(GitFacts.fileList(from: "Oryne/A.swift\nOryne/B.swift\n\n"), ["Oryne/A.swift", "Oryne/B.swift"])
    }

    func testNoRepositoryYieldsNulls() {
        let dir = FileManager.default.temporaryDirectory.appending(path: "LocantNoRepo-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        XCTAssertNil(GitFacts.head(at: dir.path(percentEncoded: false)))
        let change = GitFacts.changes(at: dir.path(percentEncoded: false), since: "abc")
        XCTAssertEqual(change, GitChange(before: "abc", after: nil, diffStat: nil, files: []))
    }
}
