import AppKit
import Foundation

enum IconStyle {
    case app
}

struct IconTarget {
    let name: String
    let iconsetPath: String
    let style: IconStyle
}

let iconTargets = [
    IconTarget(
        name: "PathBridgeApp",
        iconsetPath: "Apps/PathBridgeApp/Resources/Assets.xcassets/AppIcon.appiconset",
        style: .app
    ),
]

let iconSizes: [(String, Int)] = [
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

func drawGradient(in path: NSBezierPath, colors: [NSColor], angle: CGFloat) {
    if let gradient = NSGradient(colors: colors) {
        gradient.draw(in: path, angle: angle)
    } else {
        colors.first?.setFill()
        path.fill()
    }
}

func drawBrushedTexture(in rect: NSRect, clipPath: NSBezierPath, size: CGFloat, lightAlpha: CGFloat, darkAlpha: CGFloat) {
    clipPath.addClip()

    let spacing = max(1.5, size * 0.014)
    let lightPath = NSBezierPath()
    lightPath.lineWidth = max(0.5, size * 0.0024)

    let start = -rect.height
    let end = rect.width + rect.height
    var x = start
    while x <= end {
        lightPath.move(to: NSPoint(x: rect.minX + x, y: rect.minY))
        lightPath.line(to: NSPoint(x: rect.minX + x + rect.height, y: rect.maxY))
        x += spacing
    }

    color(255, 255, 255, lightAlpha).setStroke()
    lightPath.stroke()

    let darkPath = NSBezierPath()
    darkPath.lineWidth = max(0.5, size * 0.0018)
    x = start + spacing * 0.5
    while x <= end {
        darkPath.move(to: NSPoint(x: rect.minX + x, y: rect.minY))
        darkPath.line(to: NSPoint(x: rect.minX + x + rect.height, y: rect.maxY))
        x += spacing
    }

    color(112, 132, 144, darkAlpha).setStroke()
    darkPath.stroke()
}

func drawPathArcSymbol(in rect: NSRect, iconSize: CGFloat, style: IconStyle) {
    let stroke = color(44, 116, 136, style == .app ? 0.94 : 0.98)
    let lineWidth = max(1.2, iconSize * (style == .app ? 0.028 : 0.032))

    // Bridge arc.
    let bridge = NSBezierPath()
    bridge.lineWidth = lineWidth * 0.9
    bridge.lineCapStyle = .round
    bridge.lineJoinStyle = .round
    bridge.move(to: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.37))
    bridge.curve(
        to: NSPoint(x: rect.minX + rect.width * 0.8, y: rect.minY + rect.height * 0.37),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.66),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.66)
    )
    stroke.setStroke()
    bridge.stroke()

    // Path line crossing the bridge.
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: NSPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.29))
    path.line(to: NSPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.29))
    path.curve(
        to: NSPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.53),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.29),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.53)
    )
    path.line(to: NSPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.53))
    path.line(to: NSPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.65))
    path.stroke()

    let arrow = NSBezierPath()
    arrow.lineWidth = lineWidth * 0.78
    arrow.lineCapStyle = .round
    arrow.move(to: NSPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.65))
    arrow.line(to: NSPoint(x: rect.minX + rect.width * 0.77, y: rect.minY + rect.height * 0.64))
    arrow.move(to: NSPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.65))
    arrow.line(to: NSPoint(x: rect.minX + rect.width * 0.83, y: rect.minY + rect.height * 0.58))
    arrow.stroke()
}

func renderIcon(size: Int, style: IconStyle) -> NSBitmapImageRep? {
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

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: s, height: s).fill()

    let inset = style == .app ? s * 0.09 : s * 0.11
    let tileRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let tileCorner = style == .app ? s * 0.19 : s * 0.18
    let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: tileCorner, yRadius: tileCorner)

    let shadowBlur = style == .app ? s * 0.055 : s * 0.03
    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -s * 0.018),
        blur: shadowBlur,
        color: color(35, 58, 76, style == .app ? 0.32 : 0.22).cgColor
    )

    drawGradient(
        in: tilePath,
        colors: style == .app
            ? [color(217, 231, 239), color(186, 203, 214)]
            : [color(215, 228, 236), color(194, 209, 220)],
        angle: 90
    )

    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    if style == .app {
        NSGraphicsContext.saveGraphicsState()
        drawBrushedTexture(in: tileRect, clipPath: tilePath, size: s, lightAlpha: 0.12, darkAlpha: 0.06)
        NSGraphicsContext.restoreGraphicsState()
    }

    color(156, 176, 191, style == .app ? 0.9 : 0.72).setStroke()
    tilePath.lineWidth = max(1.0, s * (style == .app ? 0.0078 : 0.006))
    tilePath.stroke()

    let panelInset = style == .app ? s * 0.12 : s * 0.13
    let panelRect = tileRect.insetBy(dx: panelInset, dy: panelInset)
    let panelCorner = style == .app ? s * 0.11 : s * 0.1
    let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: panelCorner, yRadius: panelCorner)

    drawGradient(
        in: panelPath,
        colors: style == .app
            ? [color(205, 219, 228), color(191, 207, 218)]
            : [color(206, 220, 230), color(198, 213, 223)],
        angle: 90
    )

    color(160, 181, 195, style == .app ? 0.72 : 0.62).setStroke()
    panelPath.lineWidth = max(0.8, s * 0.0045)
    panelPath.stroke()

    let symbolInsetX = style == .app ? panelRect.width * 0.1 : panelRect.width * 0.06
    let symbolInsetY = style == .app ? panelRect.height * 0.13 : panelRect.height * 0.1
    let symbolRect = panelRect.insetBy(dx: symbolInsetX, dy: symbolInsetY)
    drawPathArcSymbol(in: symbolRect, iconSize: s, style: style)

    // Subtle top glow to keep native Apple-like material feeling.
    let glow = NSBezierPath(roundedRect: tileRect, xRadius: tileCorner, yRadius: tileCorner)
    NSGraphicsContext.saveGraphicsState()
    glow.addClip()
    if let shine = NSGradient(colors: [color(255, 255, 255, 0.27), color(255, 255, 255, 0.0)]) {
        shine.draw(in: NSRect(x: tileRect.minX, y: tileRect.midY, width: tileRect.width, height: tileRect.height * 0.62), angle: 90)
    }
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        throw NSError(domain: "icon-gen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG"])
    }
    try data.write(to: url, options: .atomic)
}

let fileManager = FileManager.default
for target in iconTargets {
    let iconsetURL = URL(fileURLWithPath: target.iconsetPath, isDirectory: true)
    guard fileManager.fileExists(atPath: iconsetURL.path) else {
        throw NSError(
            domain: "icon-gen",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Iconset not found: \(target.iconsetPath)"]
        )
    }

    for (filename, size) in iconSizes {
        guard let bitmap = renderIcon(size: size, style: target.style) else {
            throw NSError(
                domain: "icon-gen",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to render \(filename) for \(target.name)"]
            )
        }
        try writePNG(bitmap, to: iconsetURL.appendingPathComponent(filename))
    }

    print("updated \(target.name) (\(target.style))")
}
