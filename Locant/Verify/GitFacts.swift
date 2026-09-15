import Foundation

/// R33: what changed in the project between the capture and now. Reads through `/usr/bin/git`;
/// never writes, never installs hooks, never touches the network. Nulls when there is no repository.
struct GitChange: Sendable, Equatable {
    var before: String?
    var after: String?
    var diffStat: String?
    var files: [String]
}

enum GitFacts {
    static func head(at root: String) -> String? {
        run(["rev-parse", "HEAD"], at: root)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Between `before` and HEAD; the working tree against HEAD when they are the same commit or
    /// `before` is unknown.
    static func changes(at root: String, since before: String?) -> GitChange {
        guard let after = head(at: root) else { return GitChange(before: before, after: nil, diffStat: nil, files: []) }
        let range: [String] = (before != nil && before != after) ? [before!, after] : ["HEAD"]
        let stat = run(["diff", "--stat"] + range, at: root)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let names = run(["diff", "--name-only"] + range, at: root) ?? ""
        return GitChange(before: before, after: after, diffStat: (stat?.isEmpty ?? true) ? nil : stat, files: fileList(from: names))
    }

    /// The last line of `git diff --stat`: "3 files changed, 12 insertions(+), 4 deletions(-)".
    static func summaryLine(of diffStat: String?) -> String? {
        guard let diffStat else { return nil }
        let lines = diffStat.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.last { $0.contains("changed") }
    }

    static func fileList(from nameOnly: String) -> [String] {
        nameOnly.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private static func run(_ arguments: [String], at root: String) -> String? {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = ["-C", root] + arguments
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
