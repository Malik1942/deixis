import AppKit
import CoreGraphics

/// v0.6 R52: does the element look different from last time? A pixel counts as changed when any
/// channel moves by more than `channelTolerance`; the image counts as changed when more than
/// `changedFraction` of its pixels did, so a blinking caret or an antialiasing wobble is not an
/// iteration but a moved label is. Different sizes are always a change.
enum ImageDiff {
    static let channelTolerance: Int = 24
    static let changedFraction: Double = 0.005

    static func differs(_ a: CGImage, _ b: CGImage) -> Bool {
        guard a.width == b.width, a.height == b.height, a.width > 0, a.height > 0 else { return true }
        guard let pa = rgba(a), let pb = rgba(b) else { return true }
        let pixels = a.width * a.height
        var changed = 0
        let limit = Int(Double(pixels) * changedFraction)
        pa.withUnsafeBufferPointer { ba in
            pb.withUnsafeBufferPointer { bb in
                var i = 0
                let end = pixels * 4
                while i < end {
                    if abs(Int(ba[i]) - Int(bb[i])) > channelTolerance
                        || abs(Int(ba[i + 1]) - Int(bb[i + 1])) > channelTolerance
                        || abs(Int(ba[i + 2]) - Int(bb[i + 2])) > channelTolerance {
                        changed += 1
                        if changed > limit { return }
                    }
                    i += 4
                }
            }
        }
        return changed > limit
    }

    /// PNG bytes, as the store writes them. Unreadable data counts as a change.
    static func differs(png a: Data, png b: Data) -> Bool {
        guard let ia = image(fromPNG: a), let ib = image(fromPNG: b) else { return true }
        return differs(ia, ib)
    }

    static func image(fromPNG data: Data) -> CGImage? {
        NSBitmapImageRep(data: data)?.cgImage
    }

    /// Straight RGBA8 pixels, drawn through one context so both images share a layout.
    private static func rgba(_ image: CGImage) -> [UInt8]? {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let ok = bytes.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return ok ? bytes : nil
    }
}
