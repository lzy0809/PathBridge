import AppKit
import FinderSync
import OSLog
import PathBridgeCore
import PathBridgeShared

final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "finder-extension")

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: NSHomeDirectory())]
    }

    override var toolbarItemName: String {
        "PathBridge"
    }

    override var toolbarItemToolTip: String {
        "Open current Finder path in Terminal"
    }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "terminal", accessibilityDescription: "PathBridge")
            ?? NSImage(named: NSImage.applicationIconName)
            ?? NSImage()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "PathBridge")

        let openItem = NSMenuItem(
            title: "Open in Terminal",
            action: #selector(openInPathBridge(_:)),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        return menu
    }

    @objc
    private func openInPathBridge(_ sender: Any?) {
        let urls = selectedOrTargetedURLs()
        guard !urls.isEmpty else {
            NSSound.beep()
            logger.error("No selected or targeted URL in Finder context")
            return
        }

        let normalized = SelectionResolver.normalize(urls)
        let request = OpenRequest(
            paths: normalized.map(\.path),
            terminalID: "system-terminal",
            mode: .newWindow,
            commandTemplate: nil
        )

        let hostBundleID = "com.liangzhiyuan.pathbridge"
        let hostRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: hostBundleID).isEmpty

        if hostRunning {
            do {
                try OpenRequestChannel.post(request)
                logger.info("Dispatched open request to host app with \(request.paths.count) path(s)")
                return
            } catch {
                logger.error("Failed to dispatch request to host app: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            logger.info("Host app not running, using direct terminal open fallback")
        }

        do {
            try TerminalLauncher.openInSystemTerminal(urls: urls)
            logger.info("Fallback open in Terminal succeeded")
        } catch {
            NSSound.beep()
            logger.error("Fallback open in Terminal failed: \(error.localizedDescription, privacy: .public)")
        }
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
