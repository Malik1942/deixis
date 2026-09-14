import AppKit

/// R25 Color: a sampled pixel and the strings it becomes. Pure apart from the color-space conversion,
/// which goes through NSColor.
struct ColorValue: Equatable, Sendable {
    /// Components 0…1 in `space`.
    var red: Double
    var green: Double
    var blue: Double
    var space: ColorSpaceChoice

    var hex: String {
        String(format: "#%02X%02X%02X", Self.byte(red), Self.byte(green), Self.byte(blue))
    }

    /// Hue 0…360, saturation and lightness 0…1.
    var hsl: (h: Double, s: Double, l: Double) {
        let maxC = max(red, green, blue), minC = min(red, green, blue)
        let l = (maxC + minC) / 2
        let d = maxC - minC
        guard d > 0.0001 else { return (0, 0, l) }
        let s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
        var h: Double
        if maxC == red {
            h = (green - blue) / d + (green < blue ? 6 : 0)
        } else if maxC == green {
            h = (blue - red) / d + 2
        } else {
            h = (red - green) / d + 4
        }
        h *= 60
        return (h, s, l)
    }

    static func byte(_ component: Double) -> Int {
        Int((min(max(component, 0), 1) * 255).rounded())
    }
}

enum ColorSpaceChoice: String, CaseIterable, Codable, Sendable {
    case sRGB, displayP3

    var title: String {
        switch self {
        case .sRGB: "sRGB"
        case .displayP3: "Display P3"
        }
    }

    var nsColorSpace: NSColorSpace {
        switch self {
        case .sRGB: .sRGB
        case .displayP3: .displayP3
        }
    }
}

enum ColorFormat: String, CaseIterable, Codable, Sendable {
    case hex, rgb, hsl, swiftUI

    var title: String {
        switch self {
        case .hex: "Hex"
        case .rgb: "rgb()"
        case .hsl: "hsl()"
        case .swiftUI: "SwiftUI Color"
        }
    }
}

enum ColorPicker {
    static func format(_ color: ColorValue, as format: ColorFormat) -> String {
        switch format {
        case .hex:
            return color.hex
        case .rgb:
            return "rgb(\(ColorValue.byte(color.red)), \(ColorValue.byte(color.green)), \(ColorValue.byte(color.blue)))"
        case .hsl:
            let (h, s, l) = color.hsl
            return "hsl(\(Int(h.rounded())), \(Int((s * 100).rounded()))%, \(Int((l * 100).rounded()))%)"
        case .swiftUI:
            let r = String(format: "%.3f", color.red), g = String(format: "%.3f", color.green), b = String(format: "%.3f", color.blue)
            return color.space == .displayP3
                ? "Color(.displayP3, red: \(r), green: \(g), blue: \(b))"
                : "Color(red: \(r), green: \(g), blue: \(b))"
        }
    }

    /// The same color expressed in another space.
    static func convert(_ color: ColorValue, to space: ColorSpaceChoice) -> ColorValue {
        guard color.space != space else { return color }
        let source = NSColor(colorSpace: color.space.nsColorSpace, components: [color.red, color.green, color.blue, 1], count: 4)
        guard let converted = source.usingColorSpace(space.nsColorSpace) else { return color }
        return ColorValue(red: converted.redComponent, green: converted.greenComponent, blue: converted.blueComponent, space: space)
    }

    /// The pixel at (x, y) of an image, read in the requested space.
    static func pixel(in image: CGImage, x: Int, y: Int, space: ColorSpaceChoice) -> ColorValue? {
        guard x >= 0, y >= 0, x < image.width, y < image.height,
              let crop = image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else { return nil }
        let name: CFString = space == .displayP3 ? CGColorSpace.displayP3 : CGColorSpace.sRGB
        guard let colorSpace = CGColorSpace(name: name) else { return nil }
        var bytes = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return ColorValue(red: Double(bytes[0]) / 255, green: Double(bytes[1]) / 255, blue: Double(bytes[2]) / 255, space: space)
    }
}
