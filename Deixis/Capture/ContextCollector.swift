import AppKit
import Darwin

/// R5: what the user was looking at when the hotkey fired. Runs before the overlay appears.
@MainActor
enum ContextCollector {
    static func collect(reader: AccessibilityReader) async -> CaptureContext? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let bundleId = app.bundleIdentifier ?? "unknown"
        let name = app.localizedName ?? bundleId
        let pid = app.processIdentifier
        let title = await reader.focusedWindowTitle(pid: pid)

        var simulator: SimulatorInfo?
        if bundleId == ModeClassifier.simulatorBundleId {
            simulator = SimulatorInfo(
                device: deviceName(fromWindowTitle: title) ?? "Simulator",
                appBundleId: SimulatorApps.mostRecentlyLaunchedAppBundleId()
            )
        }

        let source = SourceInfo(
            app: AppInfo(bundleId: bundleId, name: name),
            window: WindowInfo(title: title),
            url: nil, // Safari/Chrome read deferred to v0.2
            simulator: simulator
        )
        return CaptureContext(source: source, frontPID: pid)
    }

    /// "iPhone 17 Pro – iOS 26.5" → "iPhone 17 Pro"
    static func deviceName(fromWindowTitle title: String?) -> String? {
        guard let title, !title.isEmpty else { return nil }
        for separator in [" – ", " — ", " - "] {
            if let range = title.range(of: separator) {
                return String(title[..<range.lowerBound])
            }
        }
        return title
    }
}

/// On-screen windows, front to back, in CG coordinates. Feeds the window hit-test (R3) and crop clamp (R4).
enum WindowList {
    static func onScreen() -> [Geometry.WindowRecord] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }
        return list.compactMap { info in
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  let boundsDict = info[kCGWindowBounds as String],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as! CFDictionary)
            else { return nil }
            return Geometry.WindowRecord(ownerPID: pid, layer: layer, bounds: bounds)
        }
    }
}

/// The simulated app is a Mac process under CoreSimulator. The most recently launched one (highest
/// pid) is the best public-API guess for what the Simulator window shows.
enum SimulatorApps {
    static func mostRecentlyLaunchedAppBundleId() -> String? {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return nil }
        var pids = [pid_t](repeating: 0, count: Int(count) * 2)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard filled > 0 else { return nil }

        var buffer = [CChar](repeating: 0, count: 4096)
        var best: (pid: pid_t, bundleId: String)?
        for pid in pids.prefix(Int(filled)) where pid > 0 {
            let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
            guard length > 0 else { continue }
            let path = String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
            guard path.contains("/CoreSimulator/Devices/"),
                  path.contains("/Containers/Bundle/Application/"),
                  !path.contains(".appex/"),
                  let appRange = path.range(of: ".app/")
            else { continue }
            let bundlePath = String(path[..<appRange.lowerBound]) + ".app"
            let remainder = path.dropFirst(bundlePath.count + 1)
            guard !remainder.contains("/") else { continue } // main executable only
            if let best, pid <= best.pid { continue }
            if let bundleId = Bundle(url: URL(filePath: bundlePath))?.bundleIdentifier {
                best = (pid, bundleId)
            }
        }
        return best?.bundleId
    }
}
