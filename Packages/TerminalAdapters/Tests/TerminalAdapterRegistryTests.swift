import Foundation
import XCTest
@testable import PathBridgeTerminalAdapters
@testable import PathBridgeShared

@MainActor
final class TerminalAdapterRegistryTests: XCTestCase {
    func test_ghosttyAppleScript_newWindow_usesSurfaceConfigurationWorkingDirectory() {
        let script = GhosttyAdapter.makeAppleScript(
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true)
        )

        XCTAssertTrue(script.contains("new surface configuration"))
        XCTAssertTrue(script.contains("initial working directory:\"/tmp/project\""))
        XCTAssertTrue(script.contains("new window with configuration"))
        XCTAssertTrue(script.contains("activate"))
        XCTAssertTrue(script.contains("with timeout of"))
        XCTAssertFalse(script.contains("/usr/bin/open"))
        XCTAssertFalse(script.contains(" -n "))
    }

    func test_ghosttyAppleScript_newTab_createsTabInExistingWindowWhenAvailable() {
        let script = GhosttyAdapter.makeAppleScript(
            mode: .newTab,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true)
        )

        XCTAssertTrue(script.contains("if (count of windows) is 0 then"))
        XCTAssertTrue(script.contains("new tab in front window with configuration"))
        XCTAssertTrue(script.contains("select tab"))
    }

    func test_ghosttyAppleScript_reuseCurrent_inputsCdInFocusedTerminal() {
        let script = GhosttyAdapter.makeAppleScript(
            mode: .reuseCurrent,
            cwd: URL(fileURLWithPath: "/tmp/project with space", isDirectory: true)
        )

        XCTAssertTrue(script.contains("focused terminal of selected tab of front window"))
        XCTAssertTrue(script.contains("input text \"cd '/tmp/project with space'"))
    }

    func test_iTerm2AppleScript_newWindow_usesCreateWindowAndOffsetBounds() {
        let script = ITerm2Adapter.makeAppleScript(
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true),
            targetFrame: CGRect(x: 128, y: 148, width: 900, height: 620)
        )

        XCTAssertTrue(script.contains("create window with default profile"))
        XCTAssertTrue(script.contains("cd '/tmp/project'"))
        XCTAssertTrue(script.contains("set bounds of newWindow to {128, 148, 1028, 768}"))
        XCTAssertTrue(script.contains("activate"))
        XCTAssertTrue(script.contains("with timeout of"))
    }

    func test_iTerm2AppleScript_newTab_usesCurrentWindow() {
        let script = ITerm2Adapter.makeAppleScript(
            mode: .newTab,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true),
            targetFrame: nil
        )

        XCTAssertTrue(script.contains("tell current window"))
        XCTAssertTrue(script.contains("create tab with default profile"))
        XCTAssertFalse(script.contains("set bounds of newWindow"))
    }

    func test_windowOffset_offsetsFrameByDefaultDelta() {
        let frame = WindowOffsetStrategy.offset(
            frame: CGRect(x: 100, y: 120, width: 900, height: 620)
        )

        XCTAssertEqual(frame, CGRect(x: 128, y: 148, width: 900, height: 620))
    }

    func test_kakuServiceName_prefersMacOSServiceForWindowAndTabModes() {
        XCTAssertEqual(KakuAdapter.serviceName(for: .newWindow), "New Kaku Window Here")
        XCTAssertEqual(KakuAdapter.serviceName(for: .newTab), "New Kaku Tab Here")
        XCTAssertNil(KakuAdapter.serviceName(for: .reuseCurrent))
    }

    func test_kakuLaunchProfileOrder_prefersCliSpawnWhenApplicationAlreadyRunning() {
        let profiles = KakuAdapter.prioritizeLaunchProfiles(
            [
                .init(
                    executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                    commandStyle: .start,
                    supportsNewTab: true
                ),
                .init(
                    executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku",
                    commandStyle: .cliSpawn,
                    supportsNewTab: false
                ),
            ],
            prefersExistingInstance: true
        )

        XCTAssertEqual(profiles.map(\.commandStyle), [.cliSpawn, .start])
    }

    func test_kakuLaunchProfileOrder_prefersGUIStartWhenApplicationNotRunning() {
        let profiles = KakuAdapter.prioritizeLaunchProfiles(
            [
                .init(
                    executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku",
                    commandStyle: .cliSpawn,
                    supportsNewTab: false
                ),
                .init(
                    executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                    commandStyle: .start,
                    supportsNewTab: true
                ),
            ],
            prefersExistingInstance: false
        )

        XCTAssertEqual(profiles.map(\.commandStyle), [.start, .cliSpawn])
    }

    func test_kakuLaunchStrategies_newWindow_forGUIStartCommand_whenNoExistingInstance() {
        let args = KakuAdapter.makeLaunchStrategies(
            profile: .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                commandStyle: .start,
                supportsNewTab: true,
                supportsPosition: true
            ),
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp", isDirectory: true),
            targetPosition: CGPoint(x: 128, y: 148)
        )
        XCTAssertEqual(args, [["start", "--position", "128,148", "--cwd", "/tmp"]])
    }

    func test_kakuLaunchStrategies_newTab_forGUIStartCommand() {
        let args = KakuAdapter.makeLaunchStrategies(
            profile: .init(
                executablePath: "/Applications/Kaku.app/Contents/MacOS/kaku-gui",
                commandStyle: .start,
                supportsNewTab: true,
                supportsPosition: true
            ),
            mode: .newTab,
            cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true),
            targetPosition: nil
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
                supportsNewTab: true,
                supportsPosition: false
            ),
            mode: .newWindow,
            cwd: URL(fileURLWithPath: "/tmp/legacy", isDirectory: true),
            targetPosition: CGPoint(x: 128, y: 148)
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
              --position <POSITION>
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
                supportsNewTab: true,
                supportsPosition: true
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
