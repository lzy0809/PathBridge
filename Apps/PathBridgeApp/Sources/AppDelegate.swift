import AppKit
import OSLog
import PathBridgeCore
import PathBridgeShared
import PathBridgeTerminalAdapters

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "host-app")
    private let settingsStore = AppSettingsStore()
    private let defaultTerminalMarker = "default-terminal"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundlePath = Bundle.main.bundleURL.path
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        logger.info("host boot bundlePath=\(bundlePath, privacy: .public) version=\(shortVersion, privacy: .public)(\(version, privacy: .public))")

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleOpenRequest(_:)),
            name: OpenRequestChannel.notificationName,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        logger.info("PathBridge host app observer started")
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let requestID = UUID().uuidString
        logger.info("Application open event requestID=\(requestID, privacy: .public) urls=\(urls.count)")

        if urls.isEmpty, let finderURL = resolveFinderFrontDirectory() {
            openPaths(
                rawURLs: [finderURL],
                requestedTerminalID: defaultTerminalMarker,
                requestedMode: nil,
                requestedCommandTemplate: nil,
                requestID: requestID
            )
            return
        }

        openPaths(
            rawURLs: urls,
            requestedTerminalID: defaultTerminalMarker,
            requestedMode: nil,
            requestedCommandTemplate: nil,
            requestID: requestID
        )
    }

    @objc
    private func handleOpenRequest(_ notification: Notification) {
        guard let request = OpenRequestChannel.decode(from: notification.userInfo) else {
            logger.error("Failed to decode open request payload")
            return
        }

        let rawURLs = request.paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        openPaths(
            rawURLs: rawURLs,
            requestedTerminalID: request.terminalID,
            requestedMode: request.mode,
            requestedCommandTemplate: request.commandTemplate,
            requestID: request.requestID
        )
    }

    private func openPaths(
        rawURLs: [URL],
        requestedTerminalID: String?,
        requestedMode: OpenMode?,
        requestedCommandTemplate: String?,
        requestID: String
    ) {
        let urls = SelectionResolver.normalize(rawURLs)
        guard !urls.isEmpty else {
            logger.error("No valid URL resolved for open request requestID=\(requestID, privacy: .public)")
            return
        }

        let settingsResult = settingsStore.loadWithSource()
        let settings = settingsResult.settings
        let preferredID = resolveTerminalID(requestedTerminalID: requestedTerminalID, settings: settings)
        let openMode = (requestedMode ?? .reuseCurrent).resolved(default: settings.defaultOpenMode)
        let commandTemplate = requestedCommandTemplate ?? settings.defaultCommandTemplate
        let registry = TerminalAdapterRegistry.shared
        guard let adapter = registry.adapter(id: preferredID) else {
            logger.error("open failed requestID=\(requestID, privacy: .public) reason=adapter-not-found terminalID=\(preferredID, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(preferredID, detail: "未找到对应终端适配器")
            return
        }
        guard adapter.isInstalled() else {
            logger.error("open failed requestID=\(requestID, privacy: .public) reason=adapter-not-installed adapter=\(adapter.id, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: "终端未安装或不可用")
            return
        }
        logger.info(
            "open requestID=\(requestID, privacy: .public) settingsSource=\(settingsResult.source.rawValue, privacy: .public) settingsTerminal=\(settings.defaultTerminalID, privacy: .public) requestedTerminal=\(requestedTerminalID ?? "nil", privacy: .public) resolvedTerminal=\(preferredID, privacy: .public) requestedMode=\(requestedMode?.rawValue ?? "nil", privacy: .public) resolvedMode=\(openMode.rawValue, privacy: .public) pathCount=\(urls.count)"
        )

        do {
            try adapter.open(paths: urls, mode: openMode, command: commandTemplate)
            logger.info("open success requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public) pathCount=\(urls.count)")
        } catch {
            logger.error("open failed requestID=\(requestID, privacy: .public) adapter=\(adapter.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            UserToastNotifier.showUnsupportedTerminal(adapter.displayName, detail: "当前路径或打开方式暂不支持")
        }
    }

    private func resolveTerminalID(requestedTerminalID: String?, settings: AppSettings) -> String {
        guard let requestedTerminalID else {
            return settings.defaultTerminalID
        }
        if requestedTerminalID == defaultTerminalMarker {
            return settings.defaultTerminalID
        }
        return requestedTerminalID
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
                logger.error("Failed to read Finder front directory: \(String(describing: errorInfo), privacy: .public)")
            }
            return nil
        }

        guard let path = descriptor.stringValue, !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}
