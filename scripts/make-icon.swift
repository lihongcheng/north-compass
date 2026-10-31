import AppKit
let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.085, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
let gold = NSColor(calibratedRed: 0.87, green: 0.73, blue: 0.47, alpha: 1)
let ivory = NSColor(calibratedRed: 0.94, green: 0.92, blue: 0.84, alpha: 1)
let red = NSColor(calibratedRed: 0.98, green: 0.36, blue: 0.3, alpha: 1)
let circle=NSBezierPath(ovalIn: NSRect(x: 120, y: 120, width: 784, height: 784)); gold.withAlphaComponent(0.3).setStroke();circle.lineWidth=3;circle.stroke()
for tick in 0..<72 {
    let a = Double(tick)*Double.pi/36
    let r:Double=366
    let inner = r - (tick % 6 == 0 ? 40.0 : 16.0)
    let p=NSBezierPath();p.move(to:NSPoint(x:512+sin(a)*r,y:512+cos(a)*r));p.line(to:NSPoint(x:512+sin(a)*inner,y:512+cos(a)*inner));p.lineWidth=tick % 6 == 0 ? 5:2
    (tick % 6 == 0 ? ivory : gold.withAlphaComponent(0.45)).setStroke();p.stroke()
}
let n="N" as NSString
let attr:[NSAttributedString.Key:Any]=[.font:NSFont.monospacedSystemFont(ofSize:76,weight:.medium),.foregroundColor:red]
let textSize=n.size(withAttributes:attr);n.draw(at:NSPoint(x:512-textSize.width/2,y:720),withAttributes:attr)
func triangle(_ points:[NSPoint], _ color:NSColor) {let p=NSBezierPath();p.move(to:points[0]);for point in points.dropFirst(){p.line(to:point)};p.close();color.setFill();p.fill()}
triangle([NSPoint(x:618,y:710),NSPoint(x:568,y:480),NSPoint(x:465,y:533)],red)
triangle([NSPoint(x:405,y:315),NSPoint(x:465,y:533),NSPoint(x:568,y:480)],ivory.withAlphaComponent(0.65))
let center=NSBezierPath(ovalIn:NSRect(x:496,y:496,width:32,height:32));gold.setFill();center.fill()
NSGraphicsContext.restoreGraphicsState()
let root=URL(fileURLWithPath:CommandLine.arguments[1])
try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("Icon-1024.png"))
