import Foundation
import OSLog

public enum AppSettingsSource: String, Equatable, Sendable {
    case sharedFile
    case userDefaults
    case hostContainerPreferences
    case legacyDefaults
    case defaultValue
}

public struct AppSettingsLoadResult: Equatable, Sendable {
    public let settings: AppSettings
    public let source: AppSettingsSource

    public init(settings: AppSettings, source: AppSettingsSource) {
        self.settings = settings
        self.source = source
    }
}

public final class AppSettingsStore {
    private static let legacySharedSuiteName = "com.liangzhiyuan.pathbridge.shared-defaults"
    private static let hostBundleID = "com.liangzhiyuan.pathbridge"
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.shared", category: "settings-store")
    private let userDefaults: UserDefaults
    private let key: String
    private let sharedFileURL: URL?
    private let hostContainerPreferencesURL: URL?

    public init(
        userDefaults: UserDefaults? = nil,
        key: String = "com.liangzhiyuan.pathbridge.app-settings",
        sharedFileURL: URL? = nil,
        hostContainerPreferencesURL: URL? = nil
    ) {
        self.userDefaults = userDefaults ?? .standard
        self.key = key
        if let sharedFileURL {
            self.sharedFileURL = sharedFileURL
        } else {
            self.sharedFileURL = userDefaults == nil ? AppSettingsStore.defaultSharedFileURL() : nil
        }

        if let hostContainerPreferencesURL {
            self.hostContainerPreferencesURL = hostContainerPreferencesURL
        } else {
            self.hostContainerPreferencesURL = userDefaults == nil ? AppSettingsStore.defaultHostContainerPreferencesURL() : nil
        }
    }

    public func load() -> AppSettings {
        let result = loadWithSource()
        let sharedPath = sharedFileURL?.path ?? "none"
        Self.logger.info(
            "load source=\(result.source.rawValue, privacy: .public) terminal=\(result.settings.defaultTerminalID, privacy: .public) mode=\(result.settings.defaultOpenMode.rawValue, privacy: .public) key=\(self.key, privacy: .public) sharedPath=\(sharedPath, privacy: .public)"
        )
        return result.settings
    }

    public func loadWithSource() -> AppSettingsLoadResult {
        if let sharedFileURL, let settings = loadFromFile(sharedFileURL) {
            return .init(settings: settings, source: .sharedFile)
        }

        if
            let data = userDefaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            return .init(settings: settings, source: .userDefaults)
        }

        if let hostContainerPreferencesURL, let settings = loadFromHostContainerPreferences(hostContainerPreferencesURL) {
            return .init(settings: settings, source: .hostContainerPreferences)
        }

        if
            let legacyDefaults = UserDefaults(suiteName: Self.legacySharedSuiteName),
            let data = legacyDefaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            return .init(settings: settings, source: .legacyDefaults)
        }

        return .init(settings: .default, source: .defaultValue)
    }

    public func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            Self.logger.error("save encode failed key=\(self.key, privacy: .public)")
            return
        }

        userDefaults.set(data, forKey: key)
        if let sharedFileURL {
            saveToFile(data: data, fileURL: sharedFileURL)
        }
        Self.logger.info(
            "save terminal=\(settings.defaultTerminalID, privacy: .public) mode=\(settings.defaultOpenMode.rawValue, privacy: .public) key=\(self.key, privacy: .public)"
        )
    }

    private static func defaultSharedFileURL() -> URL {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        return homeURL
            .appendingPathComponent("Library/Containers/\(hostBundleID)/Data/Library/Application Support/PathBridge", isDirectory: true)
            .appendingPathComponent("app-settings.json", isDirectory: false)
    }

    private static func defaultHostContainerPreferencesURL() -> URL {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        return homeURL
            .appendingPathComponent("Library/Containers/\(hostBundleID)/Data/Library/Preferences", isDirectory: true)
            .appendingPathComponent("\(hostBundleID).plist", isDirectory: false)
    }

    private func loadFromFile(_ fileURL: URL) -> AppSettings? {
        guard
            let data = try? Data(contentsOf: fileURL),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return nil
        }
        return settings
    }

    private func saveToFile(data: Data, fileURL: URL) {
        let directoryURL = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    private func loadFromHostContainerPreferences(_ fileURL: URL) -> AppSettings? {
        guard
            let dictionary = NSDictionary(contentsOf: fileURL) as? [String: Any]
        else {
            return nil
        }

        if
            let data = dictionary[key] as? Data,
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            return settings
        }

        if
            let jsonString = dictionary[key] as? String,
            let data = jsonString.data(using: .utf8),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            return settings
        }

        return nil
    }
}
