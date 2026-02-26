import AppKit
import OSLog
import PathBridgeCore
import PathBridgeShared

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "host-app")

    func applicationDidFinishLaunching(_ notification: Notification) {
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

    @objc
    private func handleOpenRequest(_ notification: Notification) {
        guard let request = OpenRequestChannel.decode(from: notification.userInfo) else {
            logger.error("Failed to decode open request payload")
            return
        }

        let urls = request.paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        do {
            try TerminalLauncher.openInSystemTerminal(urls: urls)
            logger.info("Handled open request for \(request.paths.count) path(s)")
        } catch {
            logger.error("Failed to handle open request: \(error.localizedDescription, privacy: .public)")
        }
    }
}

