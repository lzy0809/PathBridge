import AppKit
import Foundation
import PathBridgeShared

public struct WezTermAdapter: TerminalAdapter {
    public let id = "wezterm"
    public let displayName = "WezTerm"
    public let bundleIdentifier: String? = "com.github.wez.wezterm"
    private let supportedBundleIDs = [
        "com.github.wez.wezterm",
    ]
    private let supportedAppNames = [
        "WezTerm",
    ]

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames, paths: paths, mode: mode)
    }
}
