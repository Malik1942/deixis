import Foundation

/// R28: images older than the retention period go to the Trash with their sidecars, unless the
/// capture is pinned (extended attribute) or resolved (sidecar). The decision is pure; the sweep
/// applies it.
struct LifecycleEntry: Sendable, Equatable {
    /// The PNG and, for Point captures, its JSON sidecar.
    var urls: [URL]
    var modified: Date
    var pinned: Bool
    var resolved: Bool
}

enum Lifecycle {
    static let pinAttribute = "app.locant.pinned"
    static let sweepInterval: Duration = .seconds(24 * 60 * 60)

    /// Entries to trash: older than `retentionDays` and neither pinned nor resolved. Zero keeps everything.
    static func stale(_ entries: [LifecycleEntry], retentionDays: Int, now: Date) -> [LifecycleEntry] {
        guard retentionDays > 0 else { return [] }
        let cutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
        return entries.filter { !$0.pinned && !$0.resolved && $0.modified < cutoff }
    }

    /// Every Locant image under `folder`, recursively, grouped with its sidecar. v0.8 R58: the
    /// further crops of a set, `<base>-2.png` and on, belong to the capture at `<base>` and go or
    /// stay with it.
    static func entries(in folder: URL) -> [LifecycleEntry] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: keys) else { return [] }
        var byBase: [String: (png: URL?, json: URL?, extras: [URL])] = [:]
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            guard name.hasPrefix("locant-") else { continue }
            let base = url.deletingPathExtension().path(percentEncoded: false)
            switch url.pathExtension {
            case "png": byBase[base, default: (nil, nil, [])].png = url
            case "json": byBase[base, default: (nil, nil, [])].json = url
            default: break
            }
        }
        for (base, pair) in byBase {
            guard pair.json == nil, let png = pair.png, let stem = captureBase(ofExtraImage: base), byBase[stem]?.json != nil else { continue }
            byBase[stem]!.extras.append(png)
            byBase[base] = nil
        }
        return byBase.values.compactMap { pair in
            guard let png = pair.png else { return nil }
            let modified = (try? png.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let resolved = pair.json.flatMap { url -> Bool? in
                guard let data = try? Data(contentsOf: url),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
                return object["resolved"] as? Bool
            } ?? false
            let extras = pair.extras.sorted { $0.lastPathComponent < $1.lastPathComponent }
            return LifecycleEntry(urls: [png] + (pair.json.map { [$0] } ?? []) + extras, modified: modified, pinned: isPinned(png), resolved: resolved)
        }
    }

    /// `…/locant-app-20260916-120000-ab12-2` → `…/locant-app-20260916-120000-ab12`; nil for anything
    /// that is not a capture base followed by `-<number>`.
    static func captureBase(ofExtraImage base: String) -> String? {
        guard let dash = base.lastIndex(of: "-") else { return nil }
        let suffix = base[base.index(after: dash)...]
        guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber) else { return nil }
        let stem = String(base[..<dash])
        // The stem must end in the capture id: yyyyMMdd-HHmmss-xxxx.
        let tail = stem.suffix(20)
        guard tail.count == 20, tail.dropFirst(8).first == "-", tail.dropFirst(15).first == "-" else { return nil }
        return stem
    }

    /// Moves stale captures to the Trash. Returns how many captures went.
    @discardableResult
    static func sweep(folder: URL, retentionDays: Int, now: Date = Date()) -> Int {
        let doomed = stale(entries(in: folder), retentionDays: retentionDays, now: now)
        var count = 0
        for entry in doomed {
            var moved = false
            for url in entry.urls {
                if (try? FileManager.default.trashItem(at: url, resultingItemURL: nil)) != nil { moved = true }
            }
            if moved { count += 1 }
        }
        return count
    }

    // MARK: Pinning

    static func isPinned(_ url: URL) -> Bool {
        getxattr(url.path(percentEncoded: false), pinAttribute, nil, 0, 0, 0) >= 0
    }

    /// v0.5 R44 removed the menu item; files pinned by v0.4 keep their attribute and stay out of the
    /// sweep. Kept for the tests that prove that.
    static func pin(_ urls: [URL]) {
        var flag: UInt8 = 1
        for url in urls {
            setxattr(url.path(percentEncoded: false), pinAttribute, &flag, 1, 0, 0)
        }
    }


    /// The most recently modified capture under `folder`.
    static func newest(in folder: URL) -> LifecycleEntry? {
        entries(in: folder).max { $0.modified < $1.modified }
    }
}
