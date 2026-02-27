import AppKit
import Foundation
import SwiftUI

@MainActor
final class ExtensionGuideViewModel: ObservableObject {
    private let launcherBundleID = "com.liangzhiyuan.pathbridge.launcher"

    @Published var statusMessage = "系统限制下无法自动把图标固定到 Finder 工具栏。请点击“一键添加到 Finder”，再按住 Command 将图标拖到工具栏。"

    func installToFinderToolbar() {
        if let launcherURL = resolveLauncherAppURL() {
            NSWorkspace.shared.activateFileViewerSelecting([launcherURL])
            let appName = launcherURL.deletingPathExtension().lastPathComponent
            statusMessage = "已在 Finder 定位 \(appName)（\(launcherURL.path)）。按住 Command，把图标拖到 Finder 工具栏；之后点击图标即可直开默认终端。"
            return
        }

        NSSound.beep()
        statusMessage = "未检测到 PathBridgeLauncher.app。请先在 Xcode 运行一次 PathBridgeLauncher scheme，再点击“一键添加到 Finder”。不要拖 PathBridgeApp 到工具栏。"
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
