import Foundation
import XCTest
@testable import PathBridgeTerminalAdapters
@testable import PathBridgeShared

@MainActor
final class TerminalAdapterRegistryTests: XCTestCase {
    func test_kakuCLIArguments_newWindow() {
        let args = KakuAdapter.makeCLIArguments(mode: .newWindow, cwd: URL(fileURLWithPath: "/tmp", isDirectory: true))
        XCTAssertEqual(args, ["start", "--cwd", "/tmp"])
    }

    func test_kakuCLIArguments_newTab() {
        let args = KakuAdapter.makeCLIArguments(mode: .newTab, cwd: URL(fileURLWithPath: "/tmp/project", isDirectory: true))
        XCTAssertEqual(args, ["start", "--new-tab", "--cwd", "/tmp/project"])
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
