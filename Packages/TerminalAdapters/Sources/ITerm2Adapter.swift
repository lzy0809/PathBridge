import AppKit
import Foundation
import OSLog
import PathBridgeShared

public struct ITerm2Adapter: TerminalAdapter {
    public let id = "iterm2"
    public let displayName = "iTerm2"
    public let bundleIdentifier: String? = "com.googlecode.iterm2"
    private let supportedBundleIDs = [
        "com.googlecode.iterm2",
    ]
    private let supportedAppNames = [
        "iTerm2",
        "iTerm",
    ]
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "iterm2-adapter")

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        var referenceFrame = bundleIdentifier.flatMap { WindowAccessibilityController.focusedWindowFrame(bundleIdentifier: $0) }

        for path in paths {
            let targetFrame = mode == .newWindow ? referenceFrame.map { WindowOffsetStrategy.offset(frame: $0) } : nil
            let script = Self.makeAppleScript(mode: mode, cwd: path, targetFrame: targetFrame)
            try Self.runAppleScript(script)
            activateITerm()

            if mode == .newWindow {
                referenceFrame = targetFrame ?? bundleIdentifier.flatMap {
                    WindowAccessibilityController.focusedWindowFrame(bundleIdentifier: $0)
                }
            }
        }
    }

    static func makeAppleScript(mode: OpenMode, cwd: URL, targetFrame: CGRect?) -> String {
        let command = appleScriptEscaped("cd \(shellQuoted(cwd.path))")
        let boundsLine = targetFrame.map { frame in
            let maxX = Int(frame.origin.x + frame.width)
            let maxY = Int(frame.origin.y + frame.height)
            return "    set bounds of newWindow to {\(Int(frame.origin.x)), \(Int(frame.origin.y)), \(maxX), \(maxY)}\n"
        } ?? ""

        switch mode {
        case .newWindow:
            return """
            tell application id "com.googlecode.iterm2"
                activate
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text "\(command)"
                end tell
            \(boundsLine)end tell
            """
        case .newTab:
            return """
            tell application id "com.googlecode.iterm2"
                activate
                if (count of windows) is 0 then
                    set newWindow to (create window with default profile)
                    tell current session of newWindow
                        write text "\(command)"
                    end tell
                else
                    tell current window
                        create tab with default profile
                        tell current session
                            write text "\(command)"
                        end tell
                    end tell
                end if
            end tell
            """
        case .reuseCurrent:
            return """
            tell application id "com.googlecode.iterm2"
                activate
                if (count of windows) is 0 then
                    set newWindow to (create window with default profile)
                    tell current session of newWindow
                        write text "\(command)"
                    end tell
                else
                    tell current session of current window
                        write text "\(command)"
                    end tell
                end if
            end tell
            """
        }
    }

    private static func runAppleScript(_ source: String) throws {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw AdapterLaunchError.processStartFailed("Failed to compile iTerm2 AppleScript")
        }

        guard script.executeAndReturnError(&errorInfo).descriptorType != 0 || errorInfo == nil else {
            let message = errorInfo?[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            logger.error("iterm2 applescript failed error=\(message, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(message)
        }
    }

    private func activateITerm() {
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
}
