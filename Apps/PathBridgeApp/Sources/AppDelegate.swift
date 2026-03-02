import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "host-app")

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
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
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
}
