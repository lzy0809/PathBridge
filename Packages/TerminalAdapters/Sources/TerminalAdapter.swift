import Foundation
import PathBridgeShared

public protocol TerminalAdapter {
    var id: String { get }
    var displayName: String { get }
    func isInstalled() -> Bool
    func open(paths: [URL], mode: OpenMode, command: String?) throws
}
