import Foundation

/// Section 5: `Capture` → Markdown for the clipboard. Pure; derived from the JSON, never the reverse.
enum MarkdownBuilder {
    static func build(_ capture: Capture) -> String {
        var sections: [String] = ["## Deixis capture (\(capture.mode.rawValue))"]
        let note = noteBlock(capture.note)
        let extras = [elementsBlock(capture), nearbyBlock(capture), textBlock(capture)].compactMap { $0 }
        switch capture.mode {
        case .fix:
            sections.append(sourceBlock(capture))
            sections.append(elementBlock(capture.element))
            sections.append(contentsOf: extras)
            if let note { sections.append(note) }
        case .reference:
            if let note { sections.append(note) }
            sections.append(sourceBlock(capture))
            sections.append(elementBlock(capture.element))
            sections.append(contentsOf: extras)
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
        let regionNote = capture.elements != nil ? "drawn frame"
            : capture.element == nil ? "around the click point" : "element + \(number(Geometry.cropPadding)) pt"
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
            return "### Target element\nNo element information available (app exposes no accessibility tree). Use the image.\nIf this view is yours, give it .accessibilityElement() and .accessibilityIdentifier(\"…\") so Deixis can point at it next time."
        }
        if element.role == ElementResolver.clusterRole {
            let members = element.members ?? []
            var lines = [
                "### Target element",
                "cluster · \(members.count) elements (visual grouping computed by Deixis, not an accessibility element; frame approximate)",
                "Members: " + members.map(memberText).joined(separator: " · "),
            ]
            let f = element.frame
            lines.append("Frame: x=\(number(f.x)) y=\(number(f.y)) w=\(number(f.w)) h=\(number(f.h))")
            lines.append("Path: " + element.path.map(pathText).joined(separator: " > "))
            return lines.joined(separator: "\n")
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

    // v0.2 blocks

    private static func elementsBlock(_ capture: Capture) -> String? {
        guard let elements = capture.elements else { return nil }
        guard !elements.isEmpty else { return "### Elements in frame (0)\nNo accessibility elements inside the frame." }
        return (["### Elements in frame (\(elements.count))"] + elements.map { regionLine($0, suffix: nil) }).joined(separator: "\n")
    }

    private static func nearbyBlock(_ capture: Capture) -> String? {
        guard let nearby = capture.nearby, !nearby.isEmpty, let crop = capture.image.crop else { return nil }
        let center = CGPoint(x: crop.x + crop.w / 2, y: crop.y + crop.h / 2)
        return (["### Nearby"] + nearby.map { regionLine($0, suffix: RegionResolver.offsetText(from: center, to: $0.frame.cgRect)) }).joined(separator: "\n")
    }

    private static func textBlock(_ capture: Capture) -> String? {
        guard let ocr = capture.ocr, !ocr.isEmpty else { return nil }
        return "### Text in image\n" + ocr
    }

    private static func regionLine(_ e: RegionElement, suffix: String?) -> String {
        var text = e.role
        if let label = e.label { text += " \"\(label)\"" }
        if let identifier = e.identifier {
            text += " · id=\(identifier)"
            if e.identifierSource == .possiblySymbolName { text += " (may be a symbol name)" }
        }
        if let suffix {
            text += " · \(suffix)"
        } else {
            text += " · x=\(number(e.frame.x)) y=\(number(e.frame.y)) w=\(number(e.frame.w)) h=\(number(e.frame.h))"
        }
        return text
    }

    private static func noteBlock(_ note: String) -> String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return "### Note\n\(trimmed)"
    }

    // MARK: Formatting

    private static func memberText(_ member: ElementMember) -> String {
        var text = member.role
        if let label = member.label { text += " \"\(label)\"" }
        if let identifier = member.identifier { text += "#\(identifier)" }
        return text
    }

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
