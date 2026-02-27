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
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appName: "WezTerm", paths: paths, mode: mode)
    }
}
