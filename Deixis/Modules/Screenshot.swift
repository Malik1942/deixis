import Foundation

/// R23 Snap: the pixels of a region or window, kept as a file for the retention period unless the
/// user held ⌥. No sidecar: a snap is not something an agent returns to.
enum Screenshot {
    static func fileName(appName: String, id: String) -> String {
        "deixis-snap-\(FileStore.slug(appName))-\(id).png"
    }
}
