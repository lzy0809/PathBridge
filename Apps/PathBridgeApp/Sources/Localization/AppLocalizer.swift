import Foundation

enum AppLocalizerKey: String {
    case finderToTerminal
    case terminalApplicationToUse
    case openTerminalIn
    case commandToExecute
    case commandPlaceholder
    case commandHint
    case addToFinderButton
    case thankTheDevelopers
    case close
    case supportTitle
    case supportLabel1
    case supportLabel2
    case newWindow
    case newTab
    case notInstalledSuffix
    case language
    case restoreDefaultCommand
    case installGuideDefault
    case installGuideLocated
    case installGuideMissing
}

enum AppLocalizer {
    static func text(_ key: AppLocalizerKey, language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return zhHans[key] ?? ""
        case .en:
            return en[key] ?? ""
        }
    }

    static func installGuideMessage(language: AppLanguage, state: ExtensionGuideState) -> String {
        switch state {
        case .defaultGuide:
            return text(.installGuideDefault, language: language)
        case .located:
            return text(.installGuideLocated, language: language)
        case .missingLauncher:
            return text(.installGuideMissing, language: language)
        }
    }

    static func terminalLabel(_ displayName: String, installed: Bool, language: AppLanguage) -> String {
        guard !installed else {
            return displayName
        }
        return "\(displayName) \(text(.notInstalledSuffix, language: language))"
    }

    private static let zhHans: [AppLocalizerKey: String] = [
        .finderToTerminal: "Finder to Terminal",
        .terminalApplicationToUse: "终端应用：",
        .openTerminalIn: "打开方式：",
        .commandToExecute: "终端执行命令：",
        .commandPlaceholder: "cd %PATH_QUOTED%; clear; pwd",
        .commandHint: "%PATH_QUOTED% 会替换为 Finder 当前目录。",
        .addToFinderButton: "一键添加到 Finder",
        .thankTheDevelopers: "感谢支持",
        .close: "关闭",
        .supportTitle: "感谢支持",
        .supportLabel1: "感谢支持 1",
        .supportLabel2: "感谢支持 2",
        .newWindow: "新窗口",
        .newTab: "新标签",
        .notInstalledSuffix: "(未安装)",
        .language: "语言",
        .restoreDefaultCommand: "恢复默认命令模板",
        .installGuideDefault: "系统限制：请点击“一键添加到 Finder”，然后按住 Command 将 PathBridgeLauncher 拖到 Finder 工具栏。",
        .installGuideLocated: "已在 Finder 打开 PathBridgeLauncher，请按住 Command 拖到 Finder 工具栏。",
        .installGuideMissing: "未检测到 PathBridgeLauncher。请先在 Xcode 运行一次 PathBridgeLauncher scheme。",
    ]

    private static let en: [AppLocalizerKey: String] = [
        .finderToTerminal: "Finder to Terminal",
        .terminalApplicationToUse: "Terminal application to use:",
        .openTerminalIn: "Open terminal in:",
        .commandToExecute: "Command to execute in terminal:",
        .commandPlaceholder: "cd %PATH_QUOTED%; clear; pwd",
        .commandHint: "%PATH_QUOTED% will be replaced by the current Finder folder.",
        .addToFinderButton: "Add PathBridge to Finder",
        .thankTheDevelopers: "Thank The Developers",
        .close: "Close",
        .supportTitle: "Thank You",
        .supportLabel1: "Support 1",
        .supportLabel2: "Support 2",
        .newWindow: "New Window",
        .newTab: "New Tab",
        .notInstalledSuffix: "(Not Installed)",
        .language: "Language",
        .restoreDefaultCommand: "Restore default command template",
        .installGuideDefault: "System limitation: click \"Add PathBridge to Finder\", then hold Command and drag PathBridgeLauncher onto the Finder toolbar.",
        .installGuideLocated: "PathBridgeLauncher is now shown in Finder. Hold Command and drag it to the Finder toolbar.",
        .installGuideMissing: "PathBridgeLauncher was not found. Run the PathBridgeLauncher scheme in Xcode first.",
    ]
}

