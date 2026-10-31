// Reproducible native app-icon artwork. Usage: swift scripts/make-icon.swift <output-folder>
// Exports opaque PNGs at every size referenced by the iPhone asset catalog.
import AppKit
import CoreGraphics

let side = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                    bytesPerRow: side * 4, space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setAllowsAntialiasing(true)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [CGFloat((hex >> 16) & 255) / 255,
        CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, alpha])!
}
func gradient(_ colors: [UInt32], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: colorSpace, colors: colors.map { color($0) } as CFArray, locations: locations)!
}
func circle(_ radius: CGFloat) -> CGRect {
    CGRect(x: 512 - radius, y: 512 - radius, width: 2 * radius, height: 2 * radius)
}
func ring(_ radius: CGFloat, _ width: CGFloat, _ hex: UInt32, _ opacity: CGFloat = 1) {
    ctx.setStrokeColor(color(hex, opacity)); ctx.setLineWidth(width)
    ctx.strokeEllipse(in: circle(radius))
}
func polygon(_ points: [CGPoint]) -> CGPath {
    let path = CGMutablePath(); path.addLines(between: points); path.closeSubpath(); return path
}
func fill(_ path: CGPath, _ hex: UInt32) {
    ctx.addPath(path); ctx.setFillColor(color(hex)); ctx.fillPath()
}

// A full square background: iOS supplies the rounded mask.
ctx.drawLinearGradient(gradient([0x203B3C, 0x101E23, 0x080F16], [0, 0.5, 1]),
    start: CGPoint(x: 70, y: 1024), end: CGPoint(x: 890, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

// Machined champagne rim with a restrained, soft shadow.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 40, color: color(0x000000, 0.50))
ctx.setFillColor(color(0xB19C74)); ctx.fillEllipse(in: circle(393))
ctx.restoreGState()
ctx.saveGState(); ctx.addEllipse(in: circle(393)); ctx.clip()
ctx.drawLinearGradient(gradient([0xF0E4C6, 0xB9A47D, 0x6A634F, 0xC6B189], [0, 0.33, 0.72, 1]),
    start: CGPoint(x: 210, y: 940), end: CGPoint(x: 760, y: 100), options: [])
ctx.restoreGState()
ring(392, 2, 0xFAF0D4, 0.45)
ctx.saveGState(); ctx.addEllipse(in: circle(373)); ctx.clip()
ctx.drawRadialGradient(gradient([0x203234, 0x131F25, 0x0C151D], [0, 0.6, 1]),
    startCenter: CGPoint(x: 420, y: 640), startRadius: 0,
    endCenter: CGPoint(x: 512, y: 512), endRadius: 410, options: [.drawsAfterEndLocation])
ctx.restoreGState()
ring(371, 3, 0x050B10, 0.85)
ring(355, 1.5, 0xD5C39C, 0.16)

// Fewer, stronger marks survive downscaling to the home screen.
ctx.setLineCap(.round)
for i in 0..<60 {
    let angle = CGFloat(i) * .pi / 30
    let major = i % 5 == 0
    let outer: CGFloat = 335
    let inner: CGFloat = major ? 303 : 323
    ctx.setStrokeColor(color(i == 0 ? 0xFF7560 : (major ? 0xEAE4D2 : 0x9DABAA), major ? 1 : 0.53))
    ctx.setLineWidth(major ? 7 : 3)
    ctx.move(to: CGPoint(x: 512 + sin(angle) * inner, y: 512 + cos(angle) * inner))
    ctx.addLine(to: CGPoint(x: 512 + sin(angle) * outer, y: 512 + cos(angle) * outer))
    ctx.strokePath()
}
for (label, x, y, tint) in [("N", 512.0, 777.0, UInt32(0xFF7963)),
                          ("E", 777.0, 512.0, UInt32(0xD1D8CD)),
                          ("S", 512.0, 247.0, UInt32(0xD1D8CD)),
                          ("W", 247.0, 512.0, UInt32(0xD1D8CD))] {
    let text = label as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: label == "N" ? 64 : 48, weight: .medium),
        .foregroundColor: NSColor(cgColor: color(tint))!]
    let measured = text.size(withAttributes: attrs)
    text.draw(at: CGPoint(x: x - measured.width / 2, y: y - measured.height / 2), withAttributes: attrs)
}
ring(205, 1.5, 0xD5C39C, 0.10)

// The broad, faceted needle is the recognisable silhouette of the icon.
ctx.saveGState()
ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: -.pi / 7)
let top = CGPoint(x: 0, y: 279)
let bottom = CGPoint(x: 0, y: -279)
let left = CGPoint(x: -71, y: 0)
let right = CGPoint(x: 71, y: 0)
let center = CGPoint.zero
let silhouette = polygon([top, right, bottom, left])
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 9, height: -12), blur: 16, color: color(0x000000, 0.70))
fill(silhouette, 0xB22F30)
ctx.restoreGState()
fill(polygon([top, left, center]), 0xFF9276)
fill(polygon([top, center, right]), 0xF05046)
fill(polygon([bottom, left, center]), 0xECE8D6)
fill(polygon([bottom, center, right]), 0xA3B1B1)
ctx.setStrokeColor(color(0xFFFFFF, 0.25)); ctx.setLineWidth(1.5)
ctx.move(to: top); ctx.addLine(to: center); ctx.strokePath()
ctx.restoreGState()

// Small brass pivot; dark centre keeps the needle legible.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -3), blur: 5, color: color(0x000000, 0.6))
ctx.setFillColor(color(0xE2C590)); ctx.fillEllipse(in: circle(28))
ctx.restoreGState()
ctx.setFillColor(color(0x122028)); ctx.fillEllipse(in: circle(18))
ring(27, 2, 0xFBEBBF, 0.75)
ctx.setFillColor(color(0xEDD6A9)); ctx.fillEllipse(in: circle(5))
NSGraphicsContext.restoreGraphicsState()

let master = ctx.makeImage()!
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for pixels in [40, 58, 60, 80, 87, 120, 180, 1024] {
    let small = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
                         bytesPerRow: pixels * 4, space: colorSpace,
                         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    small.interpolationQuality = .high
    small.draw(master, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    let rep = NSBitmapImageRep(cgImage: small.makeImage()!)
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("Icon-v2-\(pixels).png"))
}
print("Generated 8 opaque PNG sizes in \(output.path)")
