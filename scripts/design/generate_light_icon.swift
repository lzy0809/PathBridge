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

let go2ShellIconPath = "/Applications/Go2Shell.app/Contents/Resources/Icon.icns"

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

func drawCaret(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat, upward: Bool, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round

    if upward {
        path.move(to: NSPoint(x: centerX - width / 2, y: centerY - height / 2))
        path.line(to: NSPoint(x: centerX, y: centerY + height / 2))
        path.line(to: NSPoint(x: centerX + width / 2, y: centerY - height / 2))
    } else {
        path.move(to: NSPoint(x: centerX - width / 2, y: centerY + height / 2))
        path.line(to: NSPoint(x: centerX, y: centerY - height / 2))
        path.line(to: NSPoint(x: centerX + width / 2, y: centerY + height / 2))
    }
    path.stroke()
}

func drawBaseIcon(_ baseIcon: NSImage, size: Int) -> NSBitmapImageRep? {
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
    baseIcon.draw(in: canvasRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    // Overlay the center symbol area so the final face keeps Go2Shell's outer shell style.
    let symbolPanelRect = NSRect(x: s * 0.10, y: s * 0.22, width: s * 0.80, height: s * 0.56)
    let symbolPanelPath = NSBezierPath(roundedRect: symbolPanelRect, xRadius: s * 0.06, yRadius: s * 0.06)
    if let symbolPanelGradient = NSGradient(colors: [
        color(206, 219, 228, 1.0),
        color(188, 203, 215, 1.0),
    ]) {
        symbolPanelGradient.draw(in: symbolPanelPath, angle: 90)
    } else {
        color(194, 208, 219, 0.95).setFill()
        symbolPanelPath.fill()
    }
    color(118, 142, 158, 0.45).setStroke()
    symbolPanelPath.lineWidth = max(1.0, s * 0.008)
    symbolPanelPath.stroke()

    let glyphColor = color(27, 73, 92, 0.95)
    glyphColor.setStroke()
    glyphColor.setFill()

    let eyeWidth = s * 0.10
    let eyeHeight = s * 0.08
    let eyeLineWidth = max(1.5, s * 0.032)
    drawCaret(centerX: s * 0.40, centerY: s * 0.54, width: eyeWidth, height: eyeHeight, upward: true, lineWidth: eyeLineWidth)
    drawCaret(centerX: s * 0.60, centerY: s * 0.54, width: eyeWidth, height: eyeHeight, upward: true, lineWidth: eyeLineWidth)

    let mouthRect = NSRect(x: s * 0.39, y: s * 0.36, width: s * 0.22, height: s * 0.045)
    let mouthPath = NSBezierPath(roundedRect: mouthRect, xRadius: s * 0.018, yRadius: s * 0.018)
    mouthPath.fill()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        throw NSError(domain: "icon-gen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render PNG"])
    }
    try data.write(to: url, options: .atomic)
}

guard let baseIcon = NSImage(contentsOfFile: go2ShellIconPath) else {
    throw NSError(
        domain: "icon-gen",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Base icon not found: \(go2ShellIconPath)"]
    )
}

let fileManager = FileManager.default
for iconset in iconsets {
    let baseURL = URL(fileURLWithPath: iconset, isDirectory: true)
    for (name, size) in targets {
        guard let bitmap = drawBaseIcon(baseIcon, size: size) else {
            throw NSError(domain: "icon-gen", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap for \(name)"])
        }
        let outURL = baseURL.appendingPathComponent(name)
        try writePNG(bitmap, to: outURL)
    }
    if fileManager.fileExists(atPath: baseURL.path) {
        print("updated \(iconset)")
    }
}
