import Foundation

/// Section 5: `Capture` → Markdown for the clipboard. Pure; derived from the JSON, never the reverse.
enum MarkdownBuilder {
    static func build(_ capture: Capture) -> String {
        var sections: [String] = ["## Deixis capture (\(capture.mode.rawValue))"]
        let note = noteBlock(capture.note)
        switch capture.mode {
        case .fix:
            sections.append(sourceBlock(capture))
            sections.append(elementBlock(capture.element))
            if let note { sections.append(note) }
        case .reference:
            if let note { sections.append(note) }
            sections.append(sourceBlock(capture))
            sections.append(elementBlock(capture.element))
        }
        // The heading sits directly on the first block (section 5); blocks are separated by a blank line.
        let heading = sections.removeFirst()
        return heading + "\n" + sections.joined(separator: "\n\n") + "\n"
    }

    // MARK: Blocks

    private static func sourceBlock(_ capture: Capture) -> String {
        let source = capture.source
        let bundleId = source.simulator?.appBundleId ?? source.app.bundleId
        let windowTitle = source.window?.title ?? "none"
        let region = "\(number(capture.image.widthPt))×\(number(capture.image.heightPt)) pt @\(number(capture.image.scale))x"
        let regionNote = capture.element == nil ? "around the click point" : "element + \(number(Geometry.cropPadding)) pt"
        var lines = [
            "Image: \(capture.image.path)",
            "App: \(source.app.name) (\(bundleId)) · Window: \(windowTitle)",
            "Captured: \(capturedText(capture.createdAt)) · Image region: \(region) (\(regionNote))",
        ]
        if let url = source.url { lines.append("URL: \(url)") }
        return lines.joined(separator: "\n")
    }

    private static func elementBlock(_ element: ResolvedElement?) -> String {
        guard let element else {
            return "### Target element\nNo element information available (app exposes no accessibility tree). Use the image."
        }
        var head = element.role
        if let label = element.label { head += " \"\(label)\"" }
        if let identifier = element.identifier {
            head += " · id=\(identifier)"
            if element.identifierSource == .possiblySymbolName {
                head += " (may be a symbol name, not a declared identifier)"
            }
        } else {
            head += " · no identifier"
        }
        var lines = ["### Target element", head]
        if element.identifier == nil {
            lines.append("No identifier. Grep the label text; add .accessibilityIdentifier(\"…\") to this view so the next capture is exact.")
        }
        if let value = element.value { lines.append("Value: \(valueText(value))") }
        let f = element.frame
        lines.append("Frame: x=\(number(f.x)) y=\(number(f.y)) w=\(number(f.w)) h=\(number(f.h))")
        lines.append("Path: " + element.path.map(pathText).joined(separator: " > "))
        return lines.joined(separator: "\n")
    }

    private static func noteBlock(_ note: String) -> String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return "### Note\n\(trimmed)"
    }

    // MARK: Formatting

    private static func pathText(_ entry: PathEntry) -> String {
        guard let identifier = entry.identifier else { return entry.role }
        return "\(entry.role)#\(identifier)"
    }

    private static func valueText(_ value: ElementValue) -> String {
        switch value {
        case .string(let s): "\"\(s)\""
        case .number(let d): number(d)
        case .bool(let b): b ? "true" : "false"
        }
    }

    /// "2026-09-12T14:03:12-07:00" → "2026-09-12 14:03"
    static func capturedText(_ createdAt: String) -> String {
        guard createdAt.count >= 16 else { return createdAt }
        return String(createdAt.prefix(16)).replacingOccurrences(of: "T", with: " ")
    }

    /// Integers print without a fraction; anything else keeps one decimal.
    static func number(_ d: Double) -> String {
        d.rounded() == d ? String(Int(d)) : String(format: "%.1f", d)
    }
}
