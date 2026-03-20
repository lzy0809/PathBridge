import CoreGraphics
import Foundation

enum WindowOffsetStrategy {
    static let defaultDelta = CGSize(width: 28, height: 28)

    static func offset(frame: CGRect, delta: CGSize = defaultDelta) -> CGRect {
        CGRect(
            x: frame.origin.x + delta.width,
            y: frame.origin.y + delta.height,
            width: frame.width,
            height: frame.height
        )
    }
}
