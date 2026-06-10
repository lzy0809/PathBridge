import AppKit
import OSLog
import PathBridgeCore
import PathBridgeShared
import PathBridgeTerminalAdapters

@MainActor
final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.launcher", category: "launcher")
    private let settingsStore = AppSettingsStore()
    private var didHandleOpenEvent = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let bundlePath = Bundle.main.bundleURL.path
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        logger.info("launcher boot bundlePath=\(bundlePath, privacy: .public) version=\(shortVersion, privacy: .public)(\(version, privacy: .public))")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self else { return }
            if !self.didHandleOpenEvent {
                self.handleFallbackLaunch()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleOpenEvent = true
        if urls.isEmpty {
            handleFallbackLaunch()
            return
        }
        openPaths(urls)
    }

    private func handleFallbackLaunch() {
        guard let directory = resolveFinderFrontDirectory() else {
            logger.error("No Finder front directory resolved for launcher")
            UserToastNotifier.show(
                title: "PathBridge 需要自动化权限",
                body: "请在系统设置 > 隐私与安全性 > 自动化 中允许 PathBridge 控制 Finder"
            )
            terminateSoon()
            return
        }
        openPaths([directory])
    }

    private func openPaths(_ rawURLs: [URL]) {
        let requestID = UUID().uuidString
        let urls = SelectionResolver.normalize(rawURLs)
        guard !urls.isEmpty else {
            logger.error("No normalized URLs resolved in launcher requestID=\(requestID, privacy: .public)")
            terminateSoon()
            return
        }

        let settingsResult = settingsStore.loadWithSource()
        let settings = settingsResult.settings
        let registry = TerminalAdapterRegistry.shared
        guard let adapter = registry.adapter(id: settings.defaultTerminalID) else {
            logger.error("launcher failed requestID=\(requestID, privacy: .public) reason=adapter-not-found terminalID=\(settings.defaultTerminalID, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(settings.defaultTerminalID, detail: "未找到对应终端适配器")
            terminateSoon()
            return
        }
        guard adapter.isInstalled() else {
            logger.error("launcher failed requestID=\(requestID, privacy: .public) reason=adapter-not-installed adapter=\(adapter.id, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: "终端未安装或不可用")
            terminateSoon()
            return
        }
        logger.info(
            "launcher open requestID=\(requestID, privacy: .public) settingsSource=\(settingsResult.source.rawValue, privacy: .public) terminal=\(settings.defaultTerminalID, privacy: .public) mode=\(settings.defaultOpenMode.rawValue, privacy: .public) pathCount=\(urls.count)"
        )

        do {
            try adapter.open(paths: urls, mode: settings.defaultOpenMode, command: settings.defaultCommandTemplate)
            logger.info("launcher success requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public)")
        } catch {
            logger.error("launcher failed requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: userFacingLaunchFailureDetail(error))
        }

        terminateSoon()
    }

    private func resolveFinderFrontDirectory() -> URL? {
        var errorInfo: NSDictionary?
        let script = NSAppleScript(source: """
        with timeout of 20 seconds
        tell application "Finder"
            if (count of Finder windows) is 0 then
                return POSIX path of (desktop as alias)
            end if
            return POSIX path of (target of front Finder window as alias)
        end tell
        end timeout
        """)

        guard let descriptor = script?.executeAndReturnError(&errorInfo) else {
            if let errorInfo {
                logger.error("Launcher Finder script error: \(String(describing: errorInfo), privacy: .public)")
            }
            return nil
        }

        guard let path = descriptor.stringValue, !path.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func terminateSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.terminate(nil)
        }
    }

    private func userFacingLaunchFailureDetail(_ error: Error) -> String {
        let message = error.localizedDescription
        let lowercasedMessage = message.lowercased()

        if lowercasedMessage.contains("not authorized") || lowercasedMessage.contains("not authorised") {
            return "自动化权限未授权，请在系统设置 > 隐私与安全性 > 自动化 中允许 PathBridge 控制该终端"
        }

        if lowercasedMessage.contains("timed out") || message.contains("超时") {
            return "等待终端自动化响应超时，请确认已允许 PathBridge 控制该终端"
        }

        return "当前路径或打开方式暂不支持"
    }
}
