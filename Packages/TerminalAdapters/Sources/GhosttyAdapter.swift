import AppKit
import Foundation
import OSLog
import PathBridgeShared

public struct GhosttyAdapter: TerminalAdapter {
    public let id = "ghostty"
    public let displayName = "Ghostty"
    public let bundleIdentifier: String? = "com.mitchellh.ghostty"
    private let supportedBundleIDs = [
        "com.mitchellh.ghostty",
    ]
    private let supportedAppNames = [
        "Ghostty",
    ]
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "ghostty-adapter")
    private static let appleScriptTimeoutSeconds = 20

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        var referenceFrame = bundleIdentifier.flatMap { WindowAccessibilityController.focusedWindowFrame(bundleIdentifier: $0) }

        for path in paths {
            let targetFrame = mode == .newWindow ? referenceFrame.map { WindowOffsetStrategy.offset(frame: $0) } : nil
            let script = Self.makeAppleScript(mode: mode, cwd: path)
            try Self.runAppleScript(script)
            activateGhostty()

            if mode == .newWindow {
                if let targetFrame, let bundleIdentifier {
                    _ = WindowAccessibilityController.moveFocusedWindow(
                        bundleIdentifier: bundleIdentifier,
                        to: targetFrame,
                        promptForTrust: true
                    )
                }
                referenceFrame = targetFrame ?? bundleIdentifier.flatMap {
                    WindowAccessibilityController.focusedWindowFrame(bundleIdentifier: $0)
                }
            }
        }
    }

    static func makeAppleScript(mode: OpenMode, cwd: URL) -> String {
        let workingDirectory = appleScriptEscaped(cwd.path)
        let cdCommand = appleScriptEscaped("cd \(shellQuoted(cwd.path))")
        let configurationLine = """
            set surfaceConfig to new surface configuration from {initial working directory:"\(workingDirectory)"}
        """

        switch mode {
        case .newWindow:
            return withTimeout("""
            tell application id "com.mitchellh.ghostty"
                activate
            \(configurationLine)
                set newWindow to new window with configuration surfaceConfig
                activate window newWindow
            end tell
            """)
        case .newTab:
            return withTimeout("""
            tell application id "com.mitchellh.ghostty"
                activate
            \(configurationLine)
                if (count of windows) is 0 then
                    set newWindow to new window with configuration surfaceConfig
                    activate window newWindow
                else
                    set createdTab to new tab in front window with configuration surfaceConfig
                    select tab createdTab
                end if
            end tell
            """)
        case .reuseCurrent:
            return withTimeout("""
            tell application id "com.mitchellh.ghostty"
                activate
            \(configurationLine)
                if (count of windows) is 0 then
                    set newWindow to new window with configuration surfaceConfig
                    activate window newWindow
                else
                    set currentTerminal to focused terminal of selected tab of front window
                    input text "\(cdCommand)" & return to currentTerminal
                end if
            end tell
            """)
        }
    }

    private static func runAppleScript(_ source: String) throws {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw AdapterLaunchError.processStartFailed("Failed to compile Ghostty AppleScript")
        }

        _ = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            logger.error("ghostty applescript failed error=\(message, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(message)
        }
    }

    private func activateGhostty() {
        guard let bundleIdentifier else {
            return
        }
        if let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).last {
            _ = application.activate(options: [.activateAllWindows])
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func withTimeout(_ body: String) -> String {
        """
        with timeout of \(appleScriptTimeoutSeconds) seconds
        \(body)
        end timeout
        """
    }
}
