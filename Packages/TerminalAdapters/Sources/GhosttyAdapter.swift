import AppKit
import Foundation
import PathBridgeShared

public struct GhosttyAdapter: TerminalAdapter {
    public let id = "ghostty"
    public let displayName = "Ghostty"
    public let bundleIdentifier: String? = "com.mitchellh.ghostty"
    private let supportedBundleIDs = [
        "com.mitchellh.ghostty",
    ]

    public init() {}

    public func isInstalled() -> Bool {
        for candidate in supportedBundleIDs {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) != nil {
                return true
            }
        }
        return false
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appName: "Ghostty", paths: paths, mode: mode)
    }
}
