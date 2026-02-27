import AppKit
import FinderSync
import OSLog
import PathBridgeCore
import PathBridgeShared

final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "finder-extension")
    private let hostBundleID = "com.liangzhiyuan.pathbridge"
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

        if ensureHostIsRunning() {
            do {
                try OpenRequestChannel.post(request)
                logger.info("request dispatched to host requestID=\(request.requestID, privacy: .public)")
                return
            } catch {
                logger.error("request dispatch failed requestID=\(request.requestID, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        } else {
            logger.info("host not running requestID=\(request.requestID, privacy: .public), using fallback")
        }

        if openWithLauncher(urls: normalized) {
            logger.info("fallback launcher dispatched requestID=\(request.requestID, privacy: .public) pathCount=\(normalized.count)")
            return
        }

        NSSound.beep()
        UserToastNotifier.show(title: "PathBridge 暂不支持", body: "未能打开所选终端，请先确认 PathBridgeLauncher 可用")
        logger.error("fallback launcher unavailable requestID=\(request.requestID, privacy: .public)")
    }

    private func ensureHostIsRunning() -> Bool {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: hostBundleID).isEmpty {
            return true
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: hostBundleID) else {
            return false
        }
        NSWorkspace.shared.open(appURL)

        for _ in 0 ..< 10 {
            if !NSRunningApplication.runningApplications(withBundleIdentifier: hostBundleID).isEmpty {
                return true
            }
            usleep(50_000)
        }

        return false
    }

    private func openWithLauncher(urls: [URL]) -> Bool {
        guard let launcherURL = resolveLauncherAppURL() else {
            logger.error("launcher resolve failed")
            return false
        }
        logger.info("launcher resolved path=\(launcherURL.path, privacy: .public)")

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false

        NSWorkspace.shared.open(urls, withApplicationAt: launcherURL, configuration: configuration) { _, _ in }
        return true
    }

    private func resolveLauncherAppURL() -> URL? {
        // Prefer launcher built next to current app bundle to avoid stale DerivedData bundles.
        let bundledLauncherURL = Bundle.main.bundleURL
            .deletingLastPathComponent() // PlugIns
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // PathBridgeApp.app
            .deletingLastPathComponent() // Build/Products/Debug
            .appendingPathComponent("PathBridgeLauncher.app", isDirectory: true)

        if FileManager.default.fileExists(atPath: bundledLauncherURL.path) {
            return bundledLauncherURL
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
