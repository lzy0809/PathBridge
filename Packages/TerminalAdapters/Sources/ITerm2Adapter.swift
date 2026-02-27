import AppKit
import Foundation
import PathBridgeShared

public struct ITerm2Adapter: TerminalAdapter {
    public let id = "iterm2"
    public let displayName = "iTerm2"
    public let bundleIdentifier: String? = "com.googlecode.iterm2"

    public init() {}

    public func isInstalled() -> Bool {
        guard let bundleIdentifier else {
            return false
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(appName: "iTerm", paths: paths, mode: mode)
    }
}
