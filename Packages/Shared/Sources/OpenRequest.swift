import Foundation

public enum OpenMode: String, Codable, Sendable {
    case newWindow
    case newTab
    case reuseCurrent
}

public struct OpenRequest: Codable, Sendable {
    public let paths: [String]
    public let terminalID: String
    public let mode: OpenMode
    public let commandTemplate: String?

    public init(paths: [String], terminalID: String, mode: OpenMode, commandTemplate: String?) {
        self.paths = paths
        self.terminalID = terminalID
        self.mode = mode
        self.commandTemplate = commandTemplate
    }
}
