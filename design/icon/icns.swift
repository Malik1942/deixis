import AppKit
let img = NSImage(contentsOfFile: CommandLine.arguments[1])!
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 420, pixelsHigh: 160, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(white: 0.93, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 420, height: 160).fill()
img.draw(in: NSRect(x: 16, y: 16, width: 128, height: 128)); img.draw(in: NSRect(x: 170, y: 48, width: 64, height: 64)); img.draw(in: NSRect(x: 260, y: 64, width: 32, height: 32)); img.draw(in: NSRect(x: 320, y: 72, width: 16, height: 16))
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
