import Foundation

/// R7: writes the PNG and its JSON sidecar to the capture folder. Nothing is written until both
/// bytes and the capture exist, so a failed capture leaves the folder untouched.
struct FileStore: Sendable {
    var directory: URL

    static let defaultDirectory: URL = FileManager.default
        .urls(for: .picturesDirectory, in: .userDomainMask)[0]
        .appending(path: "Deixis", directoryHint: .isDirectory)

    init(directory: URL = FileStore.defaultDirectory) {
        self.directory = directory
    }

    /// Writes the PNG, fills `image.path`, then writes the sidecar. Returns the capture as written.
    @discardableResult
    func write(png: Data, capture: Capture) throws -> Capture {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let slug = Self.slug(capture.source.app.name)
        let base = "deixis-\(slug)-\(capture.id)"
        let pngURL = directory.appending(path: "\(base).png")
        let jsonURL = directory.appending(path: "\(base).json")

        var written = capture
        written.image.path = pngURL.path(percentEncoded: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let json = try encoder.encode(written)

        try png.write(to: pngURL, options: .atomic)
        try json.write(to: jsonURL, options: .atomic)
        return written
    }

    /// App name lowercased, non-alphanumerics removed, max 16 characters.
    static func slug(_ appName: String) -> String {
        let cleaned = appName.lowercased().filter { $0.isLetter || $0.isNumber }
        let cut = String(cleaned.prefix(16))
        return cut.isEmpty ? "app" : cut
    }

    /// `yyyyMMdd-HHmmss-xxxx`: local stamp plus four base36 characters.
    static func makeID(date: Date, timeZone: TimeZone = .current, suffix: String = randomSuffix()) -> String {
        "\(stamp(date: date, timeZone: timeZone))-\(suffix)"
    }

    static func stamp(date: Date, timeZone: TimeZone = .current) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: date)
    }

    /// ISO 8601 with the local UTC offset, e.g. `2026-09-12T14:03:12-07:00`.
    static func isoTimestamp(date: Date, timeZone: TimeZone = .current) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return f.string(from: date)
    }

    static func randomSuffix() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<4).map { _ in alphabet.randomElement()! })
    }
}
