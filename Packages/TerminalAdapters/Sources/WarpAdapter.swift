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
    private let supportedAppNames = [
        "Warp",
    ]

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames, paths: paths, mode: mode)
    }
}
