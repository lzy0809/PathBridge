import Foundation
import PathBridgeShared

public protocol TerminalAdapter {
    var id: String { get }
    var displayName: String { get }
    var bundleIdentifier: String? { get }

    func isInstalled() -> Bool
    func open(paths: [URL], mode: OpenMode, command: String?) throws
}
