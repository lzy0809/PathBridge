import Foundation

public enum OpenMode: String, Codable, Sendable {
    case newWindow
    case newTab
    case reuseCurrent

    public func resolved(default defaultMode: OpenMode) -> OpenMode {
        switch self {
        case .reuseCurrent:
            return defaultMode
        case .newWindow, .newTab:
            return self
        }
    }
}

public struct OpenRequest: Codable, Sendable {
    public let paths: [String]
    public let terminalID: String
    public let mode: OpenMode
    public let commandTemplate: String?
    public let requestID: String

    public init(
        paths: [String],
        terminalID: String,
        mode: OpenMode,
        commandTemplate: String?,
        requestID: String = UUID().uuidString
    ) {
        self.paths = paths
        self.terminalID = terminalID
        self.mode = mode
        self.commandTemplate = commandTemplate
        self.requestID = requestID
    }

    private enum CodingKeys: String, CodingKey {
        case paths
        case terminalID
        case mode
        case commandTemplate
        case requestID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paths = try container.decode([String].self, forKey: .paths)
        terminalID = try container.decode(String.self, forKey: .terminalID)
        mode = try container.decode(OpenMode.self, forKey: .mode)
        commandTemplate = try container.decodeIfPresent(String.self, forKey: .commandTemplate)
        requestID = try container.decodeIfPresent(String.self, forKey: .requestID) ?? UUID().uuidString
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paths, forKey: .paths)
        try container.encode(terminalID, forKey: .terminalID)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(commandTemplate, forKey: .commandTemplate)
        try container.encode(requestID, forKey: .requestID)
    }
}
