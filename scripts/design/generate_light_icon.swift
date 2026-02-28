import AppKit
import Foundation

let iconsets = [
    "Apps/PathBridgeApp/Resources/Assets.xcassets/AppIcon.appiconset",
    "Apps/PathBridgeLauncher/Resources/Assets.xcassets/AppIcon.appiconset",
]

let targets: [(String, Int)] = [
    ("icon-16.png", 16),
    ("icon-16@2x.png", 32),
    ("icon-32.png", 32),
    ("icon-32@2x.png", 64),
    ("icon-128.png", 128),
    ("icon-128@2x.png", 256),
    ("icon-256.png", 256),
    ("icon-256@2x.png", 512),
    ("icon-512.png", 512),
    ("icon-512@2x.png", 1024),
]

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

func strokeLine(from: NSPoint, to: NSPoint, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.move(to: from)
    path.line(to: to)
    path.stroke()
}

func drawChevron(center: NSPoint, width: CGFloat, height: CGFloat, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: NSPoint(x: center.x - width / 2, y: center.y + height / 2))
    path.line(to: NSPoint(x: center.x, y: center.y))
    path.line(to: NSPoint(x: center.x - width / 2, y: center.y - height / 2))
    path.stroke()
}

func drawSmile(in rect: NSRect, lineWidth: CGFloat) {
    let smile = NSBezierPath()
    smile.lineWidth = lineWidth
    smile.lineCapStyle = .round
    smile.appendArc(
        withCenter: NSPoint(x: rect.midX, y: rect.midY + rect.height * 0.22),
        radius: rect.width * 0.52,
        startAngle: 205,
        endAngle: 335
    )
    smile.stroke()
}

func drawIcon(size: Int) -> NSBitmapImageRep? {
    let s = CGFloat(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return nil
    }

    bitmap.size = NSSize(width: s, height: s)
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let canvasRect = NSRect(x: 0, y: 0, width: s, height: s)
    let baseInset = s * 0.05
    let baseRect = canvasRect.insetBy(dx: baseInset, dy: baseInset)
    let baseCorner = s * 0.23
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: baseCorner, yRadius: baseCorner)

    if let backgroundGradient = NSGradient(colors: [
        color(246, 250, 254, 1.0),
        color(233, 241, 249, 1.0),
    ]) {
        backgroundGradient.draw(in: basePath, angle: 90)
    } else {
        color(234, 242, 249, 1.0).setFill()
        basePath.fill()
    }
    color(162, 180, 196, 0.55).setStroke()
    basePath.lineWidth = max(1.0, s * 0.012)
    basePath.stroke()

    let promptRect = NSRect(x: s * 0.24, y: s * 0.57, width: s * 0.52, height: s * 0.18)
    let promptPath = NSBezierPath(roundedRect: promptRect, xRadius: s * 0.06, yRadius: s * 0.06)
    if let promptGradient = NSGradient(colors: [
        color(255, 255, 255, 0.92),
        color(242, 248, 253, 0.9),
    ]) {
        promptGradient.draw(in: promptPath, angle: 90)
    } else {
        color(248, 251, 255, 0.9).setFill()
        promptPath.fill()
    }
    color(156, 179, 197, 0.8).setStroke()
    promptPath.lineWidth = max(1.0, s * 0.008)
    promptPath.stroke()

    color(70, 118, 147, 0.95).setStroke()
    let promptLineWidth = max(1.1, s * 0.022)
    drawChevron(
        center: NSPoint(x: s * 0.40, y: s * 0.66),
        width: s * 0.065,
        height: s * 0.065,
        lineWidth: promptLineWidth
    )
    let rightEye = NSBezierPath()
    rightEye.lineWidth = promptLineWidth
    rightEye.lineCapStyle = .round
    rightEye.move(to: NSPoint(x: s * 0.54, y: s * 0.63))
    rightEye.line(to: NSPoint(x: s * 0.57, y: s * 0.69))
    rightEye.line(to: NSPoint(x: s * 0.60, y: s * 0.63))
    rightEye.stroke()
    drawSmile(
        in: NSRect(x: s * 0.445, y: s * 0.598, width: s * 0.11, height: s * 0.05),
        lineWidth: max(1.0, s * 0.014)
    )

    let archPath = NSBezierPath()
    archPath.lineWidth = max(1.6, s * 0.055)
    archPath.lineCapStyle = .round
    archPath.move(to: NSPoint(x: s * 0.24, y: s * 0.36))
    archPath.curve(
        to: NSPoint(x: s * 0.76, y: s * 0.36),
        controlPoint1: NSPoint(x: s * 0.37, y: s * 0.59),
        controlPoint2: NSPoint(x: s * 0.63, y: s * 0.59)
    )
    color(90, 132, 161, 0.96).setStroke()
    archPath.stroke()

    let deckRect = NSRect(x: s * 0.18, y: s * 0.30, width: s * 0.64, height: s * 0.08)
    let deckPath = NSBezierPath(roundedRect: deckRect, xRadius: s * 0.04, yRadius: s * 0.04)
    color(105, 147, 176, 0.95).setFill()
    deckPath.fill()

    color(89, 128, 155, 0.95).setStroke()
    let pillarWidth = max(1.3, s * 0.036)
    strokeLine(
        from: NSPoint(x: s * 0.36, y: s * 0.30),
        to: NSPoint(x: s * 0.36, y: s * 0.20),
        lineWidth: pillarWidth
    )
    strokeLine(
        from: NSPoint(x: s * 0.64, y: s * 0.30),
        to: NSPoint(x: s * 0.64, y: s * 0.20),
        lineWidth: pillarWidth
    )

    let footingRect = NSRect(x: s * 0.22, y: s * 0.16, width: s * 0.56, height: s * 0.04)
    let footingPath = NSBezierPath(roundedRect: footingRect, xRadius: s * 0.02, yRadius: s * 0.02)
    color(122, 160, 188, 0.82).setFill()
    footingPath.fill()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        throw NSError(domain: "icon-gen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render PNG"])
    }
    try data.write(to: url, options: .atomic)
}

let fileManager = FileManager.default
for iconset in iconsets {
    let baseURL = URL(fileURLWithPath: iconset, isDirectory: true)
    for (name, size) in targets {
        guard let bitmap = drawIcon(size: size) else {
            throw NSError(domain: "icon-gen", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap for \(name)"])
        }
        let outURL = baseURL.appendingPathComponent(name)
        try writePNG(bitmap, to: outURL)
    }
    if fileManager.fileExists(atPath: baseURL.path) {
        print("updated \(iconset)")
    }
}
