import AppKit
let a = CommandLine.arguments; let hexs = a[2]; let v = UInt32(hexs, radix: 16)!
let col = NSColor(srgbRed: CGFloat((v>>16)&255)/255, green: CGFloat((v>>8)&255)/255, blue: CGFloat(v&255)/255, alpha: 1)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext; ctx.setShouldAntialias(true)
let r: CGFloat = 1024*0.56/2; ctx.setFillColor(col.cgColor); ctx.fillEllipse(in: CGRect(x: 512-r, y: 512-r, width: 2*r, height: 2*r))
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[1]))
