import AppKit
let dirs = Array(CommandLine.arguments.dropFirst(2)); let outp = CommandLine.arguments[1]
let W = 40 + dirs.count*440, H = 900
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep); let ctx = NSGraphicsContext.current!.cgContext
ctx.setFillColor(NSColor(white: 0.93, alpha: 1).cgColor); ctx.fill(CGRect(x: 0, y: 450, width: CGFloat(W), height: 450))
ctx.setFillColor(NSColor(white: 0.12, alpha: 1).cgColor); ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(W), height: 450))
for (i, d) in dirs.enumerated() {
    NSImage(contentsOfFile: "\(d)/Default.png")!.draw(in: CGRect(x: 40 + CGFloat(i)*440, y: 475, width: 400, height: 400))
    NSImage(contentsOfFile: "\(d)/Dark.png")!.draw(in: CGRect(x: 40 + CGFloat(i)*440, y: 25, width: 400, height: 400))
}
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outp))
