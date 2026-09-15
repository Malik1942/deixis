import Foundation

enum CaptureError: Error, Sendable {
    case noAccessibilityPermission
    case noScreenRecordingPermission
    case noElementUnderCursor
    case captureFailed(any Error)

    /// Short text for the 1-second toast.
    var message: String {
        switch self {
        case .noAccessibilityPermission: "Locant needs Accessibility access"
        case .noScreenRecordingPermission: "Locant needs Screen Recording access"
        case .noElementUnderCursor: "No accessibility element under the cursor"
        case .captureFailed: "Capture failed"
        }
    }
}
