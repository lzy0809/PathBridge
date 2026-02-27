import AppKit
import Foundation
import SwiftUI

@MainActor
final class SupportViewModel: ObservableObject {
    struct QRCode: Identifiable, Hashable {
        let id: String
        let imageName: String
    }

    let qrcodes: [QRCode] = [
        .init(id: "donation-1", imageName: "donation-qr-1"),
        .init(id: "donation-2", imageName: "donation-qr-2"),
    ]

    @Published var selectedQRCode: QRCode?

    func localizedTitle(for code: QRCode, language: AppLanguage) -> String {
        switch code.id {
        case "donation-1":
            return AppLocalizer.text(.supportLabel1, language: language)
        case "donation-2":
            return AppLocalizer.text(.supportLabel2, language: language)
        default:
            return AppLocalizer.text(.thankTheDevelopers, language: language)
        }
    }

    func image(for code: QRCode) -> NSImage? {
        let extensions = ["JPG", "jpg", "JPEG", "jpeg", "png", "PNG"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: code.imageName, withExtension: ext),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }
}
