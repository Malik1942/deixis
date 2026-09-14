import CoreGraphics
import Foundation

/// Mirrors `schema/capture.schema.json` v1. Keys the schema requires are always
/// written, so optionals that are nil encode as explicit `null`.
struct Capture: Codable, Sendable, Equatable {
    var schemaVersion: Int = 1
    var id: String
    var createdAt: String
    var mode: CaptureMode
    var image: ImageInfo
    var source: SourceInfo
    var element: ResolvedElement?
    var note: String
    var ocr: String? = nil
    var iterations: [Iteration] = []
    var resolved: Bool = false
    /// Region captures: every element at least half inside the drawn frame (v0.2).
    var elements: [RegionElement]? = nil
    /// Null-element point captures: the nearest labeled neighbors (v0.2).
    var nearby: [RegionElement]? = nil

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, createdAt, mode, image, source, element, note, ocr, iterations, resolved, elements, nearby
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(mode, forKey: .mode)
        try c.encode(image, forKey: .image)
        try c.encode(source, forKey: .source)
        try c.encode(element, forKey: .element)
        try c.encode(note, forKey: .note)
        try c.encode(ocr, forKey: .ocr)
        try c.encode(iterations, forKey: .iterations)
        try c.encode(resolved, forKey: .resolved)
        try c.encodeIfPresent(elements, forKey: .elements)
        try c.encodeIfPresent(nearby, forKey: .nearby)
    }
}

/// One element inside a drawn frame, or one neighbor of a null element. No path: it is one of many.
struct RegionElement: Codable, Sendable, Equatable {
    var role: String
    var rawRole: String
    var label: String?
    var identifier: String?
    var identifierSource: IdentifierSource
    var frame: Frame

    private enum CodingKeys: String, CodingKey { case role, rawRole, label, identifier, identifierSource, frame }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(rawRole, forKey: .rawRole)
        try c.encode(label, forKey: .label)
        try c.encode(identifier, forKey: .identifier)
        try c.encode(identifierSource, forKey: .identifierSource)
        try c.encode(frame, forKey: .frame)
    }
}

enum CaptureMode: String, Codable, Sendable {
    case fix
    case reference
}

struct ImageInfo: Codable, Sendable, Equatable {
    var path: String
    var widthPt: Double
    var heightPt: Double
    var scale: Double
    var crop: Frame?
}

struct SourceInfo: Codable, Sendable, Equatable {
    var app: AppInfo
    var window: WindowInfo?
    var url: String?
    var simulator: SimulatorInfo?
    /// The project directory that produced the app, when inference found one (v0.3).
    var projectRoot: String? = nil

    private enum CodingKeys: String, CodingKey { case app, window, url, simulator, projectRoot }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(app, forKey: .app)
        try c.encode(window, forKey: .window)
        try c.encode(url, forKey: .url)
        try c.encode(simulator, forKey: .simulator)
        try c.encodeIfPresent(projectRoot, forKey: .projectRoot)
    }
}

struct AppInfo: Codable, Sendable, Equatable {
    var bundleId: String
    var name: String
}

struct WindowInfo: Codable, Sendable, Equatable {
    var title: String?

    private enum CodingKeys: String, CodingKey { case title }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
    }
}

struct SimulatorInfo: Codable, Sendable, Equatable {
    var device: String
    var appBundleId: String?

    private enum CodingKeys: String, CodingKey { case device, appBundleId }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(device, forKey: .device)
        try c.encode(appBundleId, forKey: .appBundleId)
    }
}

/// Platform-neutral description of the element under the cursor.
struct ResolvedElement: Codable, Sendable, Equatable {
    var role: String
    var rawRole: String
    var label: String?
    var identifier: String?
    var identifierSource: IdentifierSource
    var value: ElementValue?
    var frame: Frame
    var path: [PathEntry]
    /// Present only when `role` is `cluster`: what the computed grouping contains (see `HitRefiner`).
    var members: [ElementMember]? = nil

    private enum CodingKeys: String, CodingKey {
        case role, rawRole, label, identifier, identifierSource, value, frame, path, members
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(rawRole, forKey: .rawRole)
        try c.encode(label, forKey: .label)
        try c.encode(identifier, forKey: .identifier)
        try c.encode(identifierSource, forKey: .identifierSource)
        try c.encode(value, forKey: .value)
        try c.encode(frame, forKey: .frame)
        try c.encode(path, forKey: .path)
        try c.encodeIfPresent(members, forKey: .members)
    }
}

/// One accessibility element inside a visual cluster.
struct ElementMember: Codable, Sendable, Equatable {
    var role: String
    var label: String?
    var identifier: String?

    private enum CodingKeys: String, CodingKey { case role, label, identifier }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(label, forKey: .label)
        try c.encode(identifier, forKey: .identifier)
    }
}

enum IdentifierSource: String, Codable, Sendable {
    case declared
    case possiblySymbolName
    case unknown
}

struct PathEntry: Codable, Sendable, Equatable {
    var role: String
    var identifier: String?

    private enum CodingKeys: String, CodingKey { case role, identifier }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(identifier, forKey: .identifier)
    }
}

/// A rectangle in global screen points, top-left origin (the accessibility convention).
struct Frame: Codable, Sendable, Hashable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double

    init(x: Double, y: Double, w: Double, h: Double) {
        self.x = x; self.y = y; self.w = w; self.h = h
    }

    init(_ rect: CGRect) {
        self.init(x: rect.origin.x, y: rect.origin.y, w: rect.width, h: rect.height)
    }

    var cgRect: CGRect { CGRect(x: x, y: y, width: w, height: h) }
}

/// The element's value as the schema allows it: string, number, or boolean.
enum ElementValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)

    init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        self = .number(try c.decode(Double.self))
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let d): try c.encode(d)
        case .bool(let b): try c.encode(b)
        }
    }
}

/// One Verify record (v0.4). Never produced by the v0.1 app; modeled so the sidecar round-trips.
struct Iteration: Codable, Sendable, Equatable {
    var capturedAt: String
    var imagePath: String
    var gitBefore: String?
    var gitAfter: String?
    var diffStat: String?
    var files: [String]

    private enum CodingKeys: String, CodingKey {
        case capturedAt, imagePath, gitBefore, gitAfter, diffStat, files
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(capturedAt, forKey: .capturedAt)
        try c.encode(imagePath, forKey: .imagePath)
        try c.encode(gitBefore, forKey: .gitBefore)
        try c.encode(gitAfter, forKey: .gitAfter)
        try c.encode(diffStat, forKey: .diffStat)
        try c.encode(files, forKey: .files)
    }
}

/// What was on screen at hotkey time (R5). Collected before the overlay appears.
struct CaptureContext: Sendable, Equatable {
    var source: SourceInfo
    var frontPID: pid_t
    /// Signals for mode inference (v0.3): where the bundle lives and who signed it.
    var bundlePath: String? = nil
    var teamID: String? = nil
}
