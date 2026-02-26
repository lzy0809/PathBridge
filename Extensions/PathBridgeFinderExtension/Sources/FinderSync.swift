import AppKit
import FinderSync
import OSLog
import PathBridgeCore

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

        do {
            try TerminalLauncher.openInSystemTerminal(urls: urls)
        } catch {
            NSSound.beep()
            logger.error("Failed to open Terminal: \(error.localizedDescription, privacy: .public)")
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
