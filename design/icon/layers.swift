import AppKit
// Flat 1024-pt layers for the .icon package. No squircle, no shading: the system renders material.
func hex(_ h: String, _ a: CGFloat = 1) -> NSColor {
    let v = UInt32(h, radix: 16)!
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF)/255, green: CGFloat((v >> 8) & 0xFF)/255, blue: CGFloat(v & 0xFF)/255, alpha: a)
}
let S: CGFloat = 1024
let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
var discFrac: CGFloat = 0.56, rectFrac: CGFloat = 1.22, strokeFrac: CGFloat = 0.016, armFrac: CGFloat = 0.17
if CommandLine.arguments.count > 2 { let a = CommandLine.arguments[2].split(separator: ",").map { CGFloat(Double($0)!) }; discFrac = a[0]; rectFrac = a[1]; strokeFrac = a[2]; armFrac = a[3] }
func canvas(_ draw: (CGContext) -> Void, _ name: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    ctx.setShouldAntialias(true); draw(ctx)
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}
let c = CGPoint(x: S/2, y: S/2), r = S*discFrac/2
for (name, color) in [("brackets-light.png", hex("1D1D1F")), ("brackets-dark.png", hex("F5F5F7"))] {
    canvas({ ctx in
        let half = r*rectFrac, arm = S*armFrac
        ctx.setStrokeColor(color.cgColor); ctx.setLineWidth(S*strokeFrac); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        for (corner, dx, dy) in [(CGPoint(x: c.x-half, y: c.y+half), CGFloat(1), CGFloat(-1)), (CGPoint(x: c.x+half, y: c.y-half), CGFloat(-1), CGFloat(1))] {
            ctx.move(to: CGPoint(x: corner.x+dx*arm, y: corner.y)); ctx.addLine(to: corner); ctx.addLine(to: CGPoint(x: corner.x, y: corner.y+dy*arm)); ctx.strokePath()
        }
    }, name)
}
for (name, color) in [("disc-light.png", hex("FFFFFF")), ("disc-dark.png", hex("3A3A3E"))] {
    canvas({ ctx in ctx.setFillColor(color.cgColor); ctx.fillEllipse(in: CGRect(x: c.x-r, y: c.y-r, width: 2*r, height: 2*r)) }, name)
}
print("layers ok")
