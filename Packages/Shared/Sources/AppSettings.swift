import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultCommandTemplate = "cd %PATH_QUOTED%; clear; pwd"

    public var defaultTerminalID: String
    public var defaultOpenMode: OpenMode
    public var defaultCommandTemplate: String
    public var activateAfterOpen: Bool
    public var debugMode: Bool

    public init(
        defaultTerminalID: String,
        defaultOpenMode: OpenMode,
        defaultCommandTemplate: String,
        activateAfterOpen: Bool,
        debugMode: Bool
    ) {
        self.defaultTerminalID = defaultTerminalID
        self.defaultOpenMode = defaultOpenMode
        self.defaultCommandTemplate = defaultCommandTemplate
        self.activateAfterOpen = activateAfterOpen
        self.debugMode = debugMode
    }

    public static let `default` = AppSettings(
        defaultTerminalID: "system-terminal",
        defaultOpenMode: .newWindow,
        defaultCommandTemplate: AppSettings.defaultCommandTemplate,
        activateAfterOpen: true,
        debugMode: false
    )
}
