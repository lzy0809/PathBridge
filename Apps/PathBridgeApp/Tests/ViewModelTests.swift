import Foundation
import XCTest
@testable import PathBridgeApp
@testable import PathBridgeShared

@MainActor
final class ViewModelTests: XCTestCase {
    func test_settingsViewModel_loadsDefaults() {
        let suiteName = "SettingsViewModelTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppSettingsStore(
            userDefaults: defaults,
            key: "SettingsViewModelTests-key-\(UUID().uuidString)"
        )
        let viewModel = SettingsViewModel(
            settingsStore: store,
            terminalOptions: [
                .init(id: "system-terminal", displayName: "Terminal", isInstalled: true),
                .init(id: "iterm2", displayName: "iTerm2", isInstalled: true),
            ]
        )

        XCTAssertEqual(viewModel.defaultTerminalID, "system-terminal")
        XCTAssertEqual(viewModel.defaultOpenMode, .newWindow)
        XCTAssertEqual(viewModel.commandTemplate, "cd %PATH_QUOTED%; clear; pwd")
        XCTAssertEqual(viewModel.appLanguage, .zhHans)
    }

    func test_extensionGuide_hasInstallGuideMessage() {
        let viewModel = ExtensionGuideViewModel()
        XCTAssertEqual(viewModel.state, .defaultGuide)
        let message = AppLocalizer.installGuideMessage(language: .zhHans, state: viewModel.state)
        XCTAssertFalse(message.isEmpty)
    }

    func test_supportResources_existInBundle() {
        XCTAssertNotNil(Bundle.main.url(forResource: "donation-qr-1", withExtension: "JPG"))
        XCTAssertNotNil(Bundle.main.url(forResource: "donation-qr-2", withExtension: "JPG"))
    }

    func test_settingsViewModel_persistsLanguage() {
        let suiteName = "SettingsViewModelLanguageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppSettingsStore(
            userDefaults: defaults,
            key: "SettingsViewModelLanguageTests-key-\(UUID().uuidString)"
        )
        let viewModel = SettingsViewModel(
            settingsStore: store,
            userDefaults: defaults,
            terminalOptions: [
                .init(id: "system-terminal", displayName: "Terminal", isInstalled: true),
            ]
        )

        viewModel.appLanguage = .en
        viewModel.saveLanguage()

        XCTAssertEqual(defaults.string(forKey: AppLanguage.storageKey), AppLanguage.en.rawValue)
    }
}
