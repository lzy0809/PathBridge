import AppKit
import Foundation
import SwiftUI

@MainActor
final class SupportViewModel: ObservableObject {
    struct QRCode: Identifiable, Hashable {
        let id: String
        let title: String
        let imageName: String
    }

    let qrcodes: [QRCode] = [
        .init(id: "donation-1", title: "感谢支持 1", imageName: "donation-qr-1"),
        .init(id: "donation-2", title: "感谢支持 2", imageName: "donation-qr-2"),
    ]

    @Published var selectedQRCode: QRCode?

    func image(for code: QRCode) -> NSImage? {
        guard let url = Bundle.main.url(forResource: code.imageName, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
