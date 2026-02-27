import Foundation
import PathBridgeShared
import PathBridgeTerminalAdapters
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    struct TerminalOption: Identifiable, Hashable {
        let id: String
        let displayName: String
        let isInstalled: Bool
    }

    @Published var terminalOptions: [TerminalOption]
    @Published var defaultTerminalID: String
    @Published var defaultOpenMode: OpenMode
    @Published var commandTemplate: String
    @Published var activateAfterOpen: Bool
    @Published var debugMode: Bool
    @Published var appLanguage: AppLanguage

    private let settingsStore: AppSettingsStore
    private let registry: TerminalAdapterRegistry
    private let userDefaults: UserDefaults

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        registry: TerminalAdapterRegistry = .shared,
        userDefaults: UserDefaults = .standard,
        terminalOptions: [TerminalOption]? = nil
    ) {
        self.settingsStore = settingsStore
        self.registry = registry
        self.userDefaults = userDefaults

        let loaded = settingsStore.load()
        let detected = terminalOptions ?? Self.detectTerminalOptions(using: registry)
        let fallbackOptions = detected.isEmpty
            ? [TerminalOption(id: "system-terminal", displayName: "Terminal", isInstalled: true)]
            : detected

        self.terminalOptions = fallbackOptions
        self.defaultTerminalID = fallbackOptions.contains(where: { $0.id == loaded.defaultTerminalID })
            ? loaded.defaultTerminalID
            : fallbackOptions[0].id
        self.defaultOpenMode = loaded.defaultOpenMode
        self.commandTemplate = loaded.defaultCommandTemplate
        self.activateAfterOpen = loaded.activateAfterOpen
        self.debugMode = loaded.debugMode
        self.appLanguage = Self.loadLanguage(from: userDefaults)
    }

    func save() {
        settingsStore.save(currentSettings())
    }

    func restoreDefaultCommandTemplate() {
        commandTemplate = AppSettings.defaultCommandTemplate
        save()
    }

    func saveLanguage() {
        userDefaults.set(appLanguage.rawValue, forKey: AppLanguage.storageKey)
    }

    func terminalDisplayName(for id: String) -> String {
        terminalOptions.first(where: { $0.id == id })?.displayName ?? "Terminal"
    }

    private func currentSettings() -> AppSettings {
        AppSettings(
            defaultTerminalID: defaultTerminalID,
            defaultOpenMode: defaultOpenMode,
            defaultCommandTemplate: commandTemplate,
            activateAfterOpen: activateAfterOpen,
            debugMode: debugMode
        )
    }

    private static func detectTerminalOptions(using registry: TerminalAdapterRegistry) -> [TerminalOption] {
        var options = registry.allAdapters().map {
            TerminalOption(
                id: $0.id,
                displayName: $0.displayName,
                isInstalled: $0.isInstalled()
            )
        }

        if !options.contains(where: { $0.id == "system-terminal" }) {
            options.insert(TerminalOption(id: "system-terminal", displayName: "Terminal", isInstalled: true), at: 0)
        }

        return options
    }

    private static func loadLanguage(from userDefaults: UserDefaults) -> AppLanguage {
        if let stored = userDefaults.string(forKey: AppLanguage.storageKey),
           let language = AppLanguage(rawValue: stored) {
            return language
        }
        return .zhHans
    }
}
