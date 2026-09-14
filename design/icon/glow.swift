import AppKit
// Soft light at the disc center, the icon's version of ball.glow.
let a = CommandLine.arguments; let r = CGFloat(Double(a[2])!) * 1024 / 2
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [NSColor.white.cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
ctx.saveGState(); ctx.addEllipse(in: CGRect(x: 512-r, y: 512-r, width: 2*r, height: 2*r)); ctx.clip()
ctx.drawRadialGradient(g, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: r*0.95, options: [])
ctx.restoreGState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[1]))
