import AppKit
import OSLog
import PathBridgeCore
import PathBridgeShared
import PathBridgeTerminalAdapters

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "host-app")
    private let settingsStore = AppSettingsStore()
    private var didHandleOpenEvent = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundlePath = Bundle.main.bundleURL.path
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        logger.info("host boot bundlePath=\(bundlePath, privacy: .public) version=\(shortVersion, privacy: .public)(\(version, privacy: .public))")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowBecameMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
        configureVisibleWindows()
        DispatchQueue.main.async { [weak self] in
            self?.configureVisibleWindows()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self else { return }
            if !self.didHandleOpenEvent && self.isFinderFrontmost() {
                self.handleFallbackQuickOpen(terminateAfterOpen: true)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleOpenEvent = true
        if urls.isEmpty {
            handleFallbackQuickOpen(terminateAfterOpen: true)
            return
        }
        openPaths(urls, terminateAfterOpen: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if isFinderFrontmost() {
            handleFallbackQuickOpen(terminateAfterOpen: !flag)
            return false
        }
        NSApp.setActivationPolicy(.regular)
        return true
    }

    @objc
    private func handleWindowBecameMain(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        configure(window: window)
    }

    private func configureVisibleWindows() {
        for window in NSApp.windows {
            configure(window: window)
        }
    }

    private func configure(window: NSWindow) {
        if window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.remove(.fullSizeContentView)
        }
        window.toolbarStyle = .automatic
        window.titlebarSeparatorStyle = .line
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
    }

    private func isFinderFrontmost() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"
    }

    private func handleFallbackQuickOpen(terminateAfterOpen: Bool) {
        guard let directory = resolveFinderFrontDirectory() else {
            logger.error("No Finder front directory resolved for host quick-open")
            if terminateAfterOpen {
                terminateSoon()
            }
            return
        }
        openPaths([directory], terminateAfterOpen: terminateAfterOpen)
    }

    private func openPaths(_ rawURLs: [URL], terminateAfterOpen: Bool) {
        let requestID = UUID().uuidString
        let urls = SelectionResolver.normalize(rawURLs)
        guard !urls.isEmpty else {
            logger.error("No normalized URLs resolved in host requestID=\(requestID, privacy: .public)")
            if terminateAfterOpen {
                terminateSoon()
            }
            return
        }

        if terminateAfterOpen {
            NSApp.setActivationPolicy(.accessory)
            NSApp.windows.forEach { $0.orderOut(nil) }
        }

        let settingsResult = settingsStore.loadWithSource()
        let settings = settingsResult.settings
        let registry = TerminalAdapterRegistry.shared
        guard let adapter = registry.adapter(id: settings.defaultTerminalID) else {
            logger.error("host quick-open failed requestID=\(requestID, privacy: .public) reason=adapter-not-found terminalID=\(settings.defaultTerminalID, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(settings.defaultTerminalID, detail: "未找到对应终端适配器")
            if terminateAfterOpen {
                terminateSoon()
            }
            return
        }

        guard adapter.isInstalled() else {
            logger.error("host quick-open failed requestID=\(requestID, privacy: .public) reason=adapter-not-installed adapter=\(adapter.id, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: "终端未安装或不可用")
            if terminateAfterOpen {
                terminateSoon()
            }
            return
        }

        logger.info(
            "host quick-open requestID=\(requestID, privacy: .public) settingsSource=\(settingsResult.source.rawValue, privacy: .public) terminal=\(settings.defaultTerminalID, privacy: .public) mode=\(settings.defaultOpenMode.rawValue, privacy: .public) pathCount=\(urls.count)"
        )

        do {
            try adapter.open(paths: urls, mode: settings.defaultOpenMode, command: settings.defaultCommandTemplate)
            logger.info("host quick-open success requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public)")
        } catch {
            logger.error("host quick-open failed requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: "当前路径或打开方式暂不支持")
        }

        if terminateAfterOpen {
            terminateSoon()
        }
    }

    private func resolveFinderFrontDirectory() -> URL? {
        var errorInfo: NSDictionary?
        let script = NSAppleScript(source: """
        tell application "Finder"
            if (count of Finder windows) is 0 then
                return POSIX path of (desktop as alias)
            end if
            return POSIX path of (target of front Finder window as alias)
        end tell
        """)

        guard let descriptor = script?.executeAndReturnError(&errorInfo) else {
            if let errorInfo {
                logger.error("Host Finder script error: \(String(describing: errorInfo), privacy: .public)")
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
}
