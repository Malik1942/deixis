import AppKit
import Vision

/// v0.2 R14: text in the crop, via Vision. Used only when the payload is vague, so the agent still
/// has something to grep on apps that name nothing.
enum TextRecognizer {
    static let languages = ["en-US", "zh-Hans"]

    /// Recognized lines, top to bottom then left to right. Empty when nothing readable.
    static func lines(inPNG data: Data) async throws -> [String] {
        guard let image = NSBitmapImageRep(data: data)?.cgImage else { return [] }
        return try lines(in: image)
    }

    static func lines(in image: CGImage) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        let observations = request.results ?? []
        // Vision's boxes have a bottom-left origin; sort by descending y, then x.
        let ordered = observations.sorted { a, b in
            let ay = a.boundingBox.midY, by = b.boundingBox.midY
            return abs(ay - by) > 0.01 ? ay > by : a.boundingBox.minX < b.boundingBox.minX
        }
        return ordered.compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
