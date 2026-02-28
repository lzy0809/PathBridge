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

let sourceCandidates = [
    "build/design/reference/AppIcon.icns",
    "build/design/reference/AppIcon.iconset/icon_128x128@2x.png",
]

func makeBitmap(size: Int) -> NSBitmapImageRep? {
    NSBitmapImageRep(
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
    )
}

func render(image: NSImage, size: Int) -> NSBitmapImageRep? {
    guard let bitmap = makeBitmap(size: size) else { return nil }
    bitmap.size = NSSize(width: CGFloat(size), height: CGFloat(size))
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
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

guard let sourcePath = sourceCandidates.first(where: { fileManager.fileExists(atPath: $0) }) else {
    throw NSError(
        domain: "icon-gen",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "No reference icon found under build/design/reference"]
    )
}

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    throw NSError(
        domain: "icon-gen",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Failed to load reference icon: \(sourcePath)"]
    )
}

for iconset in iconsets {
    let baseURL = URL(fileURLWithPath: iconset, isDirectory: true)
    for (name, size) in targets {
        guard let bitmap = render(image: sourceImage, size: size) else {
            throw NSError(domain: "icon-gen", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to render \(name)"])
        }
        try writePNG(bitmap, to: baseURL.appendingPathComponent(name))
    }
    print("updated \(iconset) from \(sourcePath)")
}
