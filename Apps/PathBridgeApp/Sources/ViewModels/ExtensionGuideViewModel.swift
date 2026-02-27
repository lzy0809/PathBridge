import AppKit
import Foundation
import SwiftUI

enum ExtensionGuideState: Equatable {
    case defaultGuide
    case located
    case missingLauncher
}

@MainActor
final class ExtensionGuideViewModel: ObservableObject {
    private let launcherBundleID = "com.liangzhiyuan.pathbridge.launcher"

    @Published private(set) var state: ExtensionGuideState = .defaultGuide

    func installToFinderToolbar() {
        if let launcherURL = resolveLauncherAppURL() {
            NSWorkspace.shared.activateFileViewerSelecting([launcherURL])
            state = .located
            return
        }

        NSSound.beep()
        state = .missingLauncher
    }

    private func resolveLauncherAppURL() -> URL? {
        let siblingURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("PathBridgeLauncher.app", isDirectory: true)
        if FileManager.default.fileExists(atPath: siblingURL.path) {
            return siblingURL
        }

        if let installedURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: launcherBundleID) {
            return installedURL
        }

        return nil
    }
}
