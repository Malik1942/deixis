import Foundation

/// R24 Text: recognized lines of a region, straight to the clipboard, nothing on disk.
enum OCR {
    static func text(inPNG data: Data) async throws -> [String] {
        try await TextRecognizer.lines(inPNG: data)
    }
}
