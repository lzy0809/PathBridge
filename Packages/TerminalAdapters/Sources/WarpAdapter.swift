import AppKit
import Foundation
import PathBridgeShared

public struct WarpAdapter: TerminalAdapter {
    public let id = "warp"
    public let displayName = "Warp"
    public let bundleIdentifier: String? = "dev.warp.Warp-Stable"
    private let supportedBundleIDs = [
        "dev.warp.Warp-Stable",
        "dev.warp.Warp",
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
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appName: "Warp", paths: paths, mode: mode)
    }
}
