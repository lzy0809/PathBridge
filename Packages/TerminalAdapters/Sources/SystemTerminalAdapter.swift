import Foundation
import PathBridgeShared

public struct SystemTerminalAdapter: TerminalAdapter {
    public let id = "system-terminal"
    public let displayName = "Terminal"
    public let bundleIdentifier: String? = "com.apple.Terminal"

    public init() {}

    public func isInstalled() -> Bool {
        true
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(appName: "Terminal", paths: paths, mode: mode)
    }
}
