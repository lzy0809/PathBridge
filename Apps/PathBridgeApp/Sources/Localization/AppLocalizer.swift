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
    case installGuideAutoInstalled
    case installGuideManualInstallRequired
    case installGuideLauncherMissing
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
        case .autoInstalled:
            return text(.installGuideAutoInstalled, language: language)
        case .manualInstallRequired:
            return text(.installGuideManualInstallRequired, language: language)
        case .launcherMissing:
            return text(.installGuideLauncherMissing, language: language)
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
        .installGuideDefault: "点击“一键添加到 Finder”将自动注入工具栏入口；若系统拦截会自动回退到手动拖拽。",
        .installGuideAutoInstalled: "已自动添加 Finder 工具栏入口。点击 Finder 工具栏中的 PathBridge 图标可直接打开默认终端。",
        .installGuideManualInstallRequired: "自动添加失败：已在 Finder 定位 PathBridgeLauncher。请按住 Command 拖到 Finder 工具栏。",
        .installGuideLauncherMissing: "未检测到 PathBridgeLauncher。请重新安装 PathBridge，或先运行一次 PathBridgeLauncher scheme。",
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
        .installGuideDefault: "Click \"Add PathBridge to Finder\" to auto-insert the toolbar button. If blocked, fallback will show manual drag guidance.",
        .installGuideAutoInstalled: "Finder toolbar entry was added automatically. Click PathBridge in Finder toolbar to open your default terminal.",
        .installGuideManualInstallRequired: "Auto-install failed. PathBridgeLauncher has been revealed in Finder. Hold Command and drag it to Finder toolbar.",
        .installGuideLauncherMissing: "PathBridgeLauncher was not found. Reinstall PathBridge, or run the PathBridgeLauncher scheme once in development.",
    ]
}
