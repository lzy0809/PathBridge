import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultCommandTemplate = "cd %PATH_QUOTED%; clear; pwd"

    public var defaultTerminalID: String
    public var defaultOpenMode: OpenMode
    public var defaultCommandTemplate: String

    public init(
        defaultTerminalID: String,
        defaultOpenMode: OpenMode,
        defaultCommandTemplate: String
    ) {
        self.defaultTerminalID = defaultTerminalID
        self.defaultOpenMode = defaultOpenMode
        self.defaultCommandTemplate = defaultCommandTemplate
    }

    public static let `default` = AppSettings(
        defaultTerminalID: "system-terminal",
        defaultOpenMode: .newWindow,
        defaultCommandTemplate: AppSettings.defaultCommandTemplate
    )
}
