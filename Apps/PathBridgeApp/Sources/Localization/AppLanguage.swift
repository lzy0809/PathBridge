import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case en = "en"

    static let storageKey = "com.liangzhiyuan.pathbridge.ui-language"

    var id: String { rawValue }

    var pickerLabel: String {
        switch self {
        case .zhHans:
            return "中文"
        case .en:
            return "EN"
        }
    }
}

