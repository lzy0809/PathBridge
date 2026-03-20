import Foundation
import XCTest
@testable import PathBridgeTerminalAdapters
@testable import PathBridgeShared

@MainActor
final class TerminalAdapterRegistryTests: XCTestCase {
    func test_kakuLaunchStrategies_newWindow_forGUIStartCommand() {
        let args = KakuAdapter.makeLaunchStrategies(
            profile: .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                commandStyle: .start,
                supportsNewTab: true
            ),
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp", isDirectory: true)
        )
        XCTAssertEqual(
            args,
            [
                ["start", "--cwd", "/tmp"],
            ]
        )
    }

    func test_kakuLaunchStrategies_newTab_forGUIStartCommand() {
        let args = KakuAdapter.makeLaunchStrategies(
            profile: .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                commandStyle: .start,
                supportsNewTab: true
            ),
            mode: .newTab,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true)
        )
        XCTAssertEqual(
            args,
            [
                ["start", "--new-tab", "--cwd", "/tmp/project"],
                ["start", "--cwd", "/tmp/project"],
            ]
        )
    }

    func test_kakuLaunchStrategies_newWindow_forLegacyCliSpawnCommand() {
        let args = KakuAdapter.makeLaunchStrategies(
            profile: .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku",
                commandStyle: .cliSpawn,
                supportsNewTab: true
            ),
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp/legacy", isDirectory: true)
        )
        XCTAssertEqual(
            args,
            [
                ["cli", "spawn", "--new-window", "--cwd", "/tmp/legacy"],
                ["cli", "spawn", "--cwd", "/tmp/legacy"],
            ]
        )
    }

    func test_kakuExecutableProfile_prefersGUIStartWhenHelpAdvertisesIt() {
        let help = """
        Usage: kaku-gui [OPTIONS] [COMMAND]

        Commands:
          start  Start the GUI, optionally running an alternative program [aliases: -e]
          help   Print help
        """
        let startHelp = """
        Usage: kaku-gui start [OPTIONS] [PROG]...

        Options:
              --always-new-process
              --new-tab
              --cwd <CWD>
        """

        let profile = KakuAdapter.detectExecutableProfile(
            executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
            helpOutput: help,
            startHelpOutput: startHelp
        )

        XCTAssertEqual(
            profile,
            .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                commandStyle: .start,
                supportsNewTab: true
            )
        )
    }

    func test_kakuExecutableProfile_supportsLegacyCliSpawnOnlyWhenAdvertised() {
        let help = """
        Usage: kaku [OPTIONS] [COMMAND]

        Commands:
          cli     Manage CLI helpers
          help    Print help
        """
        let cliHelp = """
        Usage: kaku cli [OPTIONS] <COMMAND>

        Commands:
          spawn   Spawn a command into a new window or tab
          help    Print help
        """

        let profile = KakuAdapter.detectExecutableProfile(
            executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku",
            helpOutput: help,
            startHelpOutput: nil,
            cliHelpOutput: cliHelp
        )

        XCTAssertEqual(
            profile,
            .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku",
                commandStyle: .cliSpawn,
                supportsNewTab: false
            )
        )
    }

    func test_kakuExecutableCandidates_includeCLIAndGUIBinary() {
        let appURL = URL(fileURLWithPath: "/Applications/Kaku.app", isDirectory: true)
        XCTAssertEqual(
            KakuAdapter.makeExecutableCandidates(forAppURL: appURL),
            [
                "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                "/Applications/Kaku.app/Contents/MacOS/kaku",
            ]
        )
    }

    func test_preferredAdapter_returnsRequestedAdapterEvenWhenMarkedUninstalled() {
        let requested = MockAdapter(id: "warp", installed: false)
        let system = MockAdapter(id: "system-terminal", installed: true)
        let registry = TerminalAdapterRegistry(adapters: [system, requested])

        XCTAssertEqual(registry.preferredAdapter(preferredID: "warp").id, "warp")
    }

    func test_preferredAdapter_fallsBackToSystemWhenUnknown() {
        let requested = MockAdapter(id: "warp", installed: true)
        let system = MockAdapter(id: "system-terminal", installed: true)
        let registry = TerminalAdapterRegistry(adapters: [requested, system])

        XCTAssertEqual(registry.preferredAdapter(preferredID: "unknown").id, "system-terminal")
    }

    func test_registryReturnsInstalledAdaptersOnly() {
        let installed = MockAdapter(id: "installed", installed: true)
        let unavailable = MockAdapter(id: "unavailable", installed: false)

        let registry = TerminalAdapterRegistry(adapters: [installed, unavailable])

        XCTAssertEqual(registry.installedAdapters().map(\.id), ["installed"])
    }

    func test_defaultAdapterFallsBackToSystemTerminal() {
        let system = MockAdapter(id: "system-terminal", installed: true)
        let iterm = MockAdapter(id: "iterm2", installed: true)

        let registry = TerminalAdapterRegistry(adapters: [iterm, system])

        XCTAssertEqual(registry.defaultAdapter(preferredID: "unknown-terminal").id, "system-terminal")
    }
}

private struct MockAdapter: TerminalAdapter {
    let id: String
    let displayName: String
    let bundleIdentifier: String? = nil
    let installed: Bool

    init(id: String, installed: Bool) {
        self.id = id
        self.displayName = id
        self.installed = installed
    }

    func isInstalled() -> Bool {
        installed
    }

    func open(paths: [URL], mode: OpenMode, command: String?) throws {}
}
