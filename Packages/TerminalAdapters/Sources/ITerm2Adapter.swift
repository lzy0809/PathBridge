import AppKit
import Foundation
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

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames, paths: paths, mode: mode)
    }
}
