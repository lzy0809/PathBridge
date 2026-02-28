import XCTest
@testable import PathBridgeShared

final class AppSettingsStoreTests: XCTestCase {
    func test_loadWithSource_readsHostContainerPreferences() throws {
        let fixtureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppSettingsStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtureURL, withIntermediateDirectories: true)
        let plistURL = fixtureURL.appendingPathComponent("com.liangzhiyuan.pathbridge.plist", isDirectory: false)

        let expected = AppSettings(
            defaultTerminalID: "warp",
            defaultOpenMode: .newTab,
            defaultCommandTemplate: "cd %PATH_QUOTED%; clear; pwd"
        )
        let data = try JSONEncoder().encode(expected)
        let dict: NSDictionary = [
            "com.liangzhiyuan.pathbridge.app-settings": data
        ]
        XCTAssertTrue(dict.write(to: plistURL, atomically: true))

        let suiteName = "AppSettingsStoreTests-host-container-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppSettingsStore(
            userDefaults: defaults,
            hostContainerPreferencesURL: plistURL
        )
        let result = store.loadWithSource()

        XCTAssertEqual(result.source, .hostContainerPreferences)
        XCTAssertEqual(result.settings, expected)
    }

    func test_loadWithSource_returnsDefaultSourceWhenNoSavedValue() {
        let defaults = UserDefaults(suiteName: "AppSettingsStoreTests-source-default")!
        defaults.removePersistentDomain(forName: "AppSettingsStoreTests-source-default")

        let store = AppSettingsStore(userDefaults: defaults)
        let result = store.loadWithSource()

        XCTAssertEqual(result.source, .defaultValue)
        XCTAssertEqual(result.settings.defaultTerminalID, "system-terminal")
    }

    func test_loadWithSource_returnsUserDefaultsSource() {
        let defaults = UserDefaults(suiteName: "AppSettingsStoreTests-source-user")!
        defaults.removePersistentDomain(forName: "AppSettingsStoreTests-source-user")

        let expected = AppSettings(
            defaultTerminalID: "warp",
            defaultOpenMode: .newTab,
            defaultCommandTemplate: "cd %PATH_QUOTED%"
        )

        let store = AppSettingsStore(userDefaults: defaults)
        store.save(expected)

        let result = store.loadWithSource()
        XCTAssertEqual(result.source, .userDefaults)
        XCTAssertEqual(result.settings, expected)
    }

    func test_openModeReuseCurrent_resolvesToDefaultMode() {
        XCTAssertEqual(OpenMode.reuseCurrent.resolved(default: .newTab), .newTab)
        XCTAssertEqual(OpenMode.newWindow.resolved(default: .newTab), .newWindow)
    }

    func test_defaultSettings_areReturnedWhenNoSavedValue() {
        let defaults = UserDefaults(suiteName: "AppSettingsStoreTests-defaults")!
        defaults.removePersistentDomain(forName: "AppSettingsStoreTests-defaults")

        let store = AppSettingsStore(userDefaults: defaults)
        let settings = store.load()

        XCTAssertEqual(settings.defaultTerminalID, "system-terminal")
        XCTAssertEqual(settings.defaultOpenMode, .newWindow)
        XCTAssertEqual(settings.defaultCommandTemplate, "cd %PATH_QUOTED%; clear; pwd")
    }

    func test_saveAndLoad_roundTripsSettings() {
        let defaults = UserDefaults(suiteName: "AppSettingsStoreTests-roundtrip")!
        defaults.removePersistentDomain(forName: "AppSettingsStoreTests-roundtrip")

        let store = AppSettingsStore(userDefaults: defaults)
        let expected = AppSettings(
            defaultTerminalID: "iterm2",
            defaultOpenMode: .newTab,
            defaultCommandTemplate: "cd %PATH_QUOTED%; npm run dev"
        )

        store.save(expected)
        let actual = store.load()

        XCTAssertEqual(actual, expected)
    }
}
