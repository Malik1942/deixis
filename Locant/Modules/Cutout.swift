import AppKit
import CoreImage
import Vision

/// R26 Cut: the subject under the point (or every subject in a drawn region) composited onto
/// transparency. Vision's foreground instance mask; no flood-fill fallback in this version.
enum Cutout {
    static func fileName(appName: String, id: String) -> String {
        "locant-cut-\(FileStore.slug(appName))-\(id).png"
    }

    /// `point` is normalized to the image (0…1, top-left origin). Nil when Vision finds no subject.
    static func subject(inPNG data: Data, at point: CGPoint, wholeRegion: Bool) async throws -> Data? {
        guard let image = NSBitmapImageRep(data: data)?.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        guard let result = request.results?.first, !result.allInstances.isEmpty else { return nil }

        var instances = result.allInstances
        if !wholeRegion {
            // Vision's mask coordinates have a bottom-left origin.
            let x = Int(point.x * CGFloat(image.width)), y = Int((1 - point.y) * CGFloat(image.height))
            if let hit = instanceContaining(x: x, y: y, in: result, imageSize: CGSize(width: image.width, height: image.height)) {
                instances = hit
            }
        }
        let buffer = try result.generateMaskedImage(ofInstances: instances, from: handler, croppedToInstancesExtent: true)
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cg)
        return rep.representation(using: .png, properties: [:])
    }

    private static func instanceContaining(x: Int, y: Int, in result: VNInstanceMaskObservation, imageSize: CGSize) -> IndexSet? {
        let mask = result.instanceMask
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        let width = CVPixelBufferGetWidth(mask), height = CVPixelBufferGetHeight(mask)
        let mx = Int(CGFloat(x) / imageSize.width * CGFloat(width)), my = Int(CGFloat(y) / imageSize.height * CGFloat(height))
        guard mx >= 0, my >= 0, mx < width, my < height, let base = CVPixelBufferGetBaseAddress(mask) else { return nil }
        let row = CVPixelBufferGetBytesPerRow(mask)
        let value = base.assumingMemoryBound(to: UInt8.self)[my * row + mx]
        return value == 0 ? nil : IndexSet(integer: Int(value))
    }
}
