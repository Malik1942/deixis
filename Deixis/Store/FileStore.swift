import Foundation

/// R7: writes the PNG and its JSON sidecar to the capture folder. Nothing is written until both
/// bytes and the capture exist, so a failed capture leaves the folder untouched.
struct FileStore: Sendable {
    var directory: URL
    var organization: CaptureOrganization = .none

    static let defaultDirectory: URL = FileManager.default
        .urls(for: .picturesDirectory, in: .userDomainMask)[0]
        .appending(path: "Deixis", directoryHint: .isDirectory)

    init(directory: URL = FileStore.defaultDirectory, organization: CaptureOrganization = .none) {
        self.directory = directory
        self.organization = organization
    }

    /// The folder a capture lands in: the root, or one subfolder per app, project, or month (R21).
    func folder(for capture: Capture) -> URL {
        switch organization {
        case .none:
            return directory
        case .byApp:
            return directory.appending(path: Self.slug(capture.source.app.name), directoryHint: .isDirectory)
        case .byProject:
            let name = capture.source.projectRoot.map { URL(filePath: $0).lastPathComponent } ?? Self.slug(capture.source.app.name)
            return directory.appending(path: name, directoryHint: .isDirectory)
        case .byMonth:
            let stamp = capture.id
            let month = stamp.count >= 6 ? "\(stamp.prefix(4))-\(stamp.dropFirst(4).prefix(2))" : "undated"
            return directory.appending(path: month, directoryHint: .isDirectory)
        }
    }

    /// Finder tags for a capture: Deixis, the app, the mode, and the project name when known.
    static func tags(for capture: Capture) -> [String] {
        var tags = ["Deixis", capture.source.app.name, capture.mode.rawValue]
        if let root = capture.source.projectRoot { tags.append(URL(filePath: root).lastPathComponent) }
        return tags
    }

    /// Writes the PNG, fills `image.path`, then writes the sidecar, then tags both. Returns the
    /// capture as written.
    @discardableResult
    func write(png: Data, capture: Capture) throws -> Capture {
        let folder = folder(for: capture)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let slug = Self.slug(capture.source.app.name)
        let base = "deixis-\(slug)-\(capture.id)"
        let pngURL = folder.appending(path: "\(base).png")
        let jsonURL = folder.appending(path: "\(base).json")

        var written = capture
        written.image.path = pngURL.path(percentEncoded: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let json = try encoder.encode(written)

        try png.write(to: pngURL, options: .atomic)
        try json.write(to: jsonURL, options: .atomic)
        let tags = Self.tags(for: written)
        for url in [pngURL, jsonURL] {
            Self.setFinderTags(tags, on: url)
        }
        return written
    }

    /// Finder tags live in the `com.apple.metadata:_kMDItemUserTags` extended attribute as a binary
    /// plist array of strings. Written directly, since the URL resource setter needs macOS 26.
    static func setFinderTags(_ tags: [String], on url: URL) {
        guard let data = try? PropertyListSerialization.data(fromPropertyList: tags, format: .binary, options: 0) else { return }
        let path = url.path(percentEncoded: false)
        _ = data.withUnsafeBytes { bytes in
            setxattr(path, "com.apple.metadata:_kMDItemUserTags", bytes.baseAddress, data.count, 0, 0)
        }
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
