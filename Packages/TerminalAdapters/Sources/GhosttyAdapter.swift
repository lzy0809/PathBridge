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
    private let supportedAppNames = [
        "Ghostty",
    ]

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames, paths: paths, mode: mode)
    }
}
