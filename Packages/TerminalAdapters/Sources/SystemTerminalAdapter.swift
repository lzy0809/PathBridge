import Foundation
import PathBridgeShared

public struct SystemTerminalAdapter: TerminalAdapter {
    public let id = "system-terminal"
    public let displayName = "Terminal"
    public let bundleIdentifier: String? = "com.apple.Terminal"
    private let supportedBundleIDs = [
        "com.apple.Terminal",
    ]
    private let supportedAppNames = [
        "Terminal",
    ]

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        try OpenCommandLauncher.open(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames, paths: paths, mode: mode)
    }
}
