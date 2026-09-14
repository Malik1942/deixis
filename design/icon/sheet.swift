import AppKit
// Contact sheet: for each appearance, 512 render, then 128/64/32/16 shown at 1x pixels (nearest) on a matching desktop-ish background.
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
let W = 1400, H = 700
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let gc = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gc
let ctx = gc.cgContext
for (row, (name, bg)) in [("light", NSColor(white: 0.93, alpha: 1)), ("dark", NSColor(white: 0.12, alpha: 1))].enumerated() {
    let y0 = CGFloat(row == 0 ? 350 : 0)
    ctx.setFillColor(bg.cgColor); ctx.fill(CGRect(x: 0, y: y0, width: CGFloat(W), height: 350))
    let big = NSImage(contentsOf: dir.appendingPathComponent("\(name)-512.png"))!
    big.draw(in: CGRect(x: 30, y: y0 + 19, width: 312, height: 312))
    var x: CGFloat = 400
    for px in [256, 128, 64, 32, 16] {
        let img = NSImage(contentsOf: dir.appendingPathComponent("\(name)-\(px).png"))!
        ctx.interpolationQuality = .none
        img.draw(in: CGRect(x: x, y: y0 + 175 - CGFloat(px)/2, width: CGFloat(px), height: CGFloat(px)))
        x += CGFloat(px) + 60
    }
    // 16 and 32 magnified 4x so the reading at small size is visible
    for (i, px) in [32, 16].enumerated() {
        let img = NSImage(contentsOf: dir.appendingPathComponent("\(name)-\(px).png"))!
        ctx.interpolationQuality = .none
        img.draw(in: CGRect(x: 1080 + CGFloat(i)*160, y: y0 + 175 - CGFloat(px)*2, width: CGFloat(px)*4, height: CGFloat(px)*4))
    }
}
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent("sheet.png"))
