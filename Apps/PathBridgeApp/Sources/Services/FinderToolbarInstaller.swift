import AppKit
import Foundation
import OSLog

enum FinderToolbarInstallResult: Equatable {
    case autoInstalled
    case launcherMissing
    case requiresManualInstall
}

final class FinderToolbarInstaller {
    private let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge", category: "finder-toolbar-installer")
    private let finderDomain = "com.apple.finder"
    private let toolbarKey = "NSToolbar Configuration Browser"
    private let toolbarItemsKey = "TB Item Identifiers"
    private let toolbarPlistsKey = "TB Item Plists"
    private let finderSearchIdentifier = "com.apple.finder.SRCH"
    private let finderLocationIdentifier = "com.apple.finder.loc "
    private let launcherBundleID = "com.liangzhiyuan.pathbridge.launcher"

    func install() -> FinderToolbarInstallResult {
        guard let launcherURL = resolveLauncherURL() else {
            logger.error("install failed reason=launcher-missing")
            return .launcherMissing
        }

        guard updateFinderToolbar(with: launcherURL) else {
            logger.error("install failed reason=update-toolbar-failed")
            return .requiresManualInstall
        }

        guard relaunchFinder() else {
            logger.error("install partial reason=relaunch-finder-failed")
            return .requiresManualInstall
        }

        logger.info("install success launcher=\(launcherURL.path, privacy: .public)")
        return .autoInstalled
    }

    func resolveLauncherURL() -> URL? {
        let embedded = Bundle.main.bundleURL
            .appendingPathComponent("Contents/MacOS/PathBridgeLauncher.app", isDirectory: true)
        if FileManager.default.fileExists(atPath: embedded.path) {
            return embedded
        }

        let sibling = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("PathBridgeLauncher.app", isDirectory: true)
        if FileManager.default.fileExists(atPath: sibling.path) {
            return sibling
        }

        if let installed = NSWorkspace.shared.urlForApplication(withBundleIdentifier: launcherBundleID) {
            return installed
        }

        return nil
    }

    func revealForManualInstall() {
        if let launcherURL = resolveLauncherURL() {
            NSWorkspace.shared.activateFileViewerSelecting([launcherURL])
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    private func updateFinderToolbar(with launcherURL: URL) -> Bool {
        var finderPrefs = UserDefaults.standard.persistentDomain(forName: finderDomain) ?? [:]
        var toolbar = finderPrefs[toolbarKey] as? [String: Any] ?? [:]

        let existingIdentifiers = (toolbar[toolbarItemsKey] as? [Any] ?? []).compactMap { $0 as? String }
        guard !existingIdentifiers.isEmpty else {
            logger.error("toolbar update failed reason=missing-item-identifiers")
            return false
        }

        let existingPlists = toolbar[toolbarPlistsKey] as? NSDictionary ?? [:]
        var pairs: [(id: String, plist: Any?)] = existingIdentifiers.enumerated().map { index, identifier in
            let plist = existingPlists["\(index)"] ?? existingPlists[index]
            return (identifier, plist)
        }

        pairs.removeAll { pair in
            guard pair.id == finderLocationIdentifier else { return false }
            return isPathBridgeLauncherItem(pair.plist)
        }

        let launcherPlist = makeLauncherToolbarItemPlist(launcherURL: launcherURL)
        let insertIndex = pairs.firstIndex(where: { $0.id == finderSearchIdentifier }) ?? pairs.count
        pairs.insert((finderLocationIdentifier, launcherPlist), at: insertIndex)

        toolbar[toolbarItemsKey] = pairs.map(\.id)
        var rebuiltPlists: [String: Any] = [:]
        for (index, pair) in pairs.enumerated() {
            if let plist = pair.plist {
                rebuiltPlists["\(index)"] = plist
            }
        }
        toolbar[toolbarPlistsKey] = rebuiltPlists
        finderPrefs[toolbarKey] = toolbar

        UserDefaults.standard.setPersistentDomain(finderPrefs, forName: finderDomain)
        let synced = CFPreferencesAppSynchronize(finderDomain as CFString)
        logger.info("toolbar update synced=\(synced, privacy: .public)")
        return synced
    }

    private func makeLauncherToolbarItemPlist(launcherURL: URL) -> [String: Any] {
        var value: [String: Any] = [
            "_CFURLString": launcherURL.absoluteString,
            "_CFURLStringType": 15,
        ]

        if let bookmark = try? launcherURL.bookmarkData(options: [.suitableForBookmarkFile], includingResourceValuesForKeys: nil, relativeTo: nil) {
            value["_CFURLAliasData"] = bookmark
        }
        return value
    }

    private func isPathBridgeLauncherItem(_ plist: Any?) -> Bool {
        guard
            let dict = plist as? [String: Any],
            let urlString = dict["_CFURLString"] as? String,
            !urlString.isEmpty
        else {
            return false
        }

        if urlString.contains("PathBridgeLauncher.app") {
            return true
        }
        if let url = URL(string: urlString), url.path.contains("PathBridgeLauncher.app") {
            return true
        }
        return false
    }

    private func relaunchFinder() -> Bool {
        _ = runProcess(executable: "/usr/bin/killall", arguments: ["Finder"], allowNonZeroExit: true)
        return runProcess(executable: "/usr/bin/open", arguments: ["-a", "Finder"], allowNonZeroExit: false)
    }

    @discardableResult
    private func runProcess(executable: String, arguments: [String], allowNonZeroExit: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.error("process run failed path=\(executable, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            return false
        }

        if allowNonZeroExit {
            return true
        }
        let success = process.terminationStatus == 0
        if !success {
            logger.error("process non-zero path=\(executable, privacy: .public) code=\(process.terminationStatus)")
        }
        return success
    }
}
