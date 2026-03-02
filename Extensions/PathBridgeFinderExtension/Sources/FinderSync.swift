import AppKit
import FinderSync
import OSLog
import PathBridgeCore
import PathBridgeShared

final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "finder-extension")
    private let launcherBundleID = "com.liangzhiyuan.pathbridge.launcher"
    private let defaultTerminalMarker = "default-terminal"

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true),
            URL(fileURLWithPath: "/", isDirectory: true),
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .toolbarItemMenu:
            // Go2Shell-style toolbar entry is provided by app icon, not Finder Sync toolbar menu.
            return nil
        default:
            return contextMenu()
        }
    }

    private func contextMenu() -> NSMenu {
        let menu = NSMenu(title: "PathBridge")
        let openItem = NSMenuItem(
            title: "Open in Default Terminal",
            action: #selector(openDefaultTerminal(_:)),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
        return menu
    }

    @objc
    private func openDefaultTerminal(_ sender: Any?) {
        handleOpenRequest(terminalID: defaultTerminalMarker)
    }

    private func handleOpenRequest(terminalID: String) {
        let urls = selectedOrTargetedURLs()
        guard !urls.isEmpty else {
            NSSound.beep()
            logger.error("No selected or targeted URL in Finder context")
            return
        }

        let normalized = SelectionResolver.normalize(urls)
        let request = OpenRequest(
            paths: normalized.map(\.path),
            terminalID: terminalID,
            mode: .reuseCurrent,
            commandTemplate: nil
        )
        logger.info(
            "request prepared requestID=\(request.requestID, privacy: .public) terminal=\(request.terminalID, privacy: .public) mode=\(request.mode.rawValue, privacy: .public) pathCount=\(request.paths.count)"
        )

        if openWithLauncher(urls: normalized, requestID: request.requestID) {
            logger.info("launcher-open dispatched requestID=\(request.requestID, privacy: .public) pathCount=\(normalized.count)")
            return
        }

        NSSound.beep()
        UserToastNotifier.show(title: "PathBridge 暂不支持", body: "未能打开所选终端，请先确认 PathBridgeLauncher 可用")
        logger.error("launcher-open unavailable requestID=\(request.requestID, privacy: .public)")
    }

    private func openWithLauncher(urls: [URL], requestID: String) -> Bool {
        guard let launcherURL = resolveLauncherURL() else {
            logger.error("launcher resolve failed")
            return false
        }
        logger.info("launcher resolved path=\(launcherURL.path, privacy: .public)")

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.open(urls, withApplicationAt: launcherURL, configuration: configuration) { _, error in
            if let error {
                Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "finder-extension")
                    .error("launcher open completion error requestID=\(requestID, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        }
        return true
    }

    private func resolveLauncherURL() -> URL? {
        // Prefer launcher bundled inside host app in production builds.
        let embeddedLauncherURL = Bundle.main.bundleURL
            .deletingLastPathComponent() // PlugIns
            .deletingLastPathComponent() // Contents
            .appendingPathComponent("MacOS/PathBridgeLauncher.app", isDirectory: true)

        if FileManager.default.fileExists(atPath: embeddedLauncherURL.path) {
            return embeddedLauncherURL
        }

        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: launcherBundleID)
    }

    private func selectedOrTargetedURLs() -> [URL] {
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        if !selected.isEmpty {
            return selected
        }
        if let targeted = controller.targetedURL() {
            return [targeted]
        }
        return []
    }

}
