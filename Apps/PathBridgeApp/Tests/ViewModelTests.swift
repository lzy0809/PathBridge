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
        XCTAssertTrue(viewModel.activateAfterOpen)
    }

    func test_extensionGuide_hasInstallGuideMessage() {
        let viewModel = ExtensionGuideViewModel()
        XCTAssertFalse(viewModel.statusMessage.isEmpty)
    }

    func test_supportResources_existInBundle() {
        XCTAssertNotNil(Bundle.main.url(forResource: "donation-qr-1", withExtension: "png"))
        XCTAssertNotNil(Bundle.main.url(forResource: "donation-qr-2", withExtension: "png"))
    }
}
