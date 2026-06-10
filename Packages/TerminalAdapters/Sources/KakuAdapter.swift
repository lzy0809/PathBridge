import AppKit
import Foundation
import OSLog
import PathBridgeShared

struct KakuLaunchProfile: Equatable {
    let executablePath: String
    let commandStyle: KakuCommandStyle
    let supportsNewTab: Bool
    let supportsPosition: Bool

    init(
        executablePath: String,
        commandStyle: KakuCommandStyle,
        supportsNewTab: Bool,
        supportsPosition: Bool = false
    ) {
        self.executablePath = executablePath
        self.commandStyle = commandStyle
        self.supportsNewTab = supportsNewTab
        self.supportsPosition = supportsPosition
    }
}

enum KakuCommandStyle: Equatable {
    case start
    case cliSpawn
}

public struct KakuAdapter: TerminalAdapter {
    public let id = "kaku"
    public let displayName = "Kaku"
    public let bundleIdentifier: String? = "fun.tw93.kaku"
    private let supportedBundleIDs = [
        "fun.tw93.kaku",
    ]
    private let supportedAppNames = [
        "Kaku",
    ]
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "kaku-adapter")

    public init() {}

    public func isInstalled() -> Bool {
        OpenCommandLauncher.isInstalled(bundleIdentifiers: supportedBundleIDs, appNames: supportedAppNames)
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        var launchProfiles: [KakuLaunchProfile]?
        var didResolveLaunchProfiles = false
        func fallbackLaunchProfiles() -> [KakuLaunchProfile]? {
            guard !didResolveLaunchProfiles else {
                return launchProfiles
            }
            launchProfiles = resolveLaunchProfiles()
            didResolveLaunchProfiles = true
            return launchProfiles
        }

        var didLaunch = false
        var prefersExistingInstance = isKakuRunning()
        for path in paths {
            var launched = false
            var lastError: Error?
            var attempt = 0
            let previousFrame = mode == .newWindow
                ? bundleIdentifier.flatMap { WindowAccessibilityController.focusedWindowFrame(bundleIdentifier: $0) }
                : nil
            let targetFrame = previousFrame.map { WindowOffsetStrategy.offset(frame: $0) }

            if let serviceName = Self.serviceName(for: mode),
               openViaService(name: serviceName, path: path)
            {
                Self.logger.info("kaku launched via service=\(serviceName, privacy: .public) path=\(path.path, privacy: .public)")
                launched = true
                didLaunch = true
            }

            if !launched {
                guard let launchProfiles = fallbackLaunchProfiles() else {
                    throw lastError ?? AdapterLaunchError.processStartFailed("Kaku service unavailable and executable profile not found")
                }

                for profile in Self.prioritizeLaunchProfiles(launchProfiles, prefersExistingInstance: prefersExistingInstance) {
                    let strategies = Self.makeLaunchStrategies(
                        profile: profile,
                        mode: mode,
                        cwd: path,
                        targetPosition: targetFrame?.origin
                    )
                    for arguments in strategies {
                        attempt += 1
                        Self.logger.info(
                            "kaku attempt=\(attempt) exec=\(profile.executablePath, privacy: .public) style=\(String(describing: profile.commandStyle), privacy: .public) path=\(path.path, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public)"
                        )
                        do {
                            let allowLongRunningProcess = !(prefersExistingInstance && profile.commandStyle == .start)
                            try runKaku(
                                executablePath: profile.executablePath,
                                arguments: arguments,
                                allowLongRunningProcess: allowLongRunningProcess
                            )
                            Self.logger.info("kaku launched via exec=\(profile.executablePath, privacy: .public)")
                            launched = true
                            didLaunch = true
                            break
                        } catch {
                            lastError = error
                            Self.logger.error(
                                "kaku attempt failed exec=\(profile.executablePath, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                            )
                        }

                        if launched {
                            break
                        }
                    }

                    if launched {
                        break
                    }
                }
            }

            guard launched else {
                throw lastError ?? AdapterLaunchError.processStartFailed("Kaku launch failed")
            }

            prefersExistingInstance = true
            activateKaku()

            if mode == .newWindow,
               let bundleIdentifier,
               let targetFrame
            {
                _ = WindowAccessibilityController.moveFocusedWindow(
                    bundleIdentifier: bundleIdentifier,
                    to: targetFrame,
                    promptForTrust: true
                )
            }
        }

        if didLaunch {
            activateKaku()
        }
    }

    static func serviceName(for mode: OpenMode) -> String? {
        switch mode {
        case .newWindow:
            return "New Kaku Window Here"
        case .newTab:
            return "New Kaku Tab Here"
        case .reuseCurrent:
            return nil
        }
    }

    static func prioritizeLaunchProfiles(
        _ profiles: [KakuLaunchProfile],
        prefersExistingInstance: Bool
    ) -> [KakuLaunchProfile] {
        profiles.sorted { lhs, rhs in
            priority(for: lhs.commandStyle, prefersExistingInstance: prefersExistingInstance)
                < priority(for: rhs.commandStyle, prefersExistingInstance: prefersExistingInstance)
        }
    }

    static func makeLaunchStrategies(
        profile: KakuLaunchProfile,
        mode: OpenMode,
        cwd: URL,
        targetPosition: CGPoint? = nil
    ) -> [[String]] {
        let cwdArguments = ["--cwd", cwd.path]
        let positionArguments: [String] = {
            guard
                mode == .newWindow,
                profile.commandStyle == .start,
                profile.supportsPosition,
                let targetPosition
            else {
                return []
            }
            return ["--position", "\(Int(targetPosition.x)),\(Int(targetPosition.y))"]
        }()

        switch profile.commandStyle {
        case .start:
            switch mode {
            case .newTab:
                if profile.supportsNewTab {
                    return [
                        ["start", "--new-tab"] + cwdArguments,
                        ["start"] + cwdArguments,
                    ]
                }
                return [
                    ["start"] + cwdArguments,
                ]
            case .newWindow, .reuseCurrent:
                return [
                    ["start"] + positionArguments + cwdArguments,
                ]
            }
        case .cliSpawn:
            switch mode {
            case .newTab:
                return [
                    ["cli", "spawn"] + cwdArguments,
                ]
            case .newWindow, .reuseCurrent:
                return [
                    ["cli", "spawn", "--new-window"] + cwdArguments,
                    ["cli", "spawn"] + cwdArguments,
                ]
            }
        }
    }

    private static func priority(for style: KakuCommandStyle, prefersExistingInstance: Bool) -> Int {
        switch (prefersExistingInstance, style) {
        case (true, .cliSpawn), (false, .start):
            return 0
        case (true, .start), (false, .cliSpawn):
            return 1
        }
    }

    static func makeExecutableCandidates(forAppURL appURL: URL) -> [String] {
        [
            appURL.appendingPathComponent("Contents/MacOS/kaku-gui", isDirectory: false).path,
            appURL.appendingPathComponent("Contents/MacOS/kaku", isDirectory: false).path,
        ]
    }

    static func detectExecutableProfile(
        executablePath: String,
        helpOutput: String,
        startHelpOutput: String?,
        cliHelpOutput: String? = nil
    ) -> KakuLaunchProfile? {
        let normalizedHelp = helpOutput.lowercased()
        let normalizedStartHelp = startHelpOutput?.lowercased()
        let normalizedCLIHelp = cliHelpOutput?.lowercased()

        if normalizedHelp.contains("start")
            || URL(fileURLWithPath: executablePath).lastPathComponent == "kaku-gui"
        {
            let supportsNewTab = normalizedStartHelp?.contains("--new-tab") == true
            let supportsPosition = normalizedStartHelp?.contains("--position") == true
            return KakuLaunchProfile(
                executablePath: executablePath,
                commandStyle: .start,
                supportsNewTab: supportsNewTab,
                supportsPosition: supportsPosition
            )
        }

        if normalizedCLIHelp?.contains("spawn") == true {
            return KakuLaunchProfile(
                executablePath: executablePath,
                commandStyle: .cliSpawn,
                supportsNewTab: false,
                supportsPosition: false
            )
        }

        return nil
    }

    private func resolveLaunchProfiles() -> [KakuLaunchProfile]? {
        var candidates: [String] = []

        for candidate in supportedBundleIDs {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) else {
                continue
            }
            candidates.append(contentsOf: Self.makeExecutableCandidates(forAppURL: appURL))
        }

        let appCandidates = [
            URL(fileURLWithPath: "/Applications/Kaku.app", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Setapp/Kaku.app", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Kaku.app", isDirectory: true),
        ]
        for appURL in appCandidates {
            candidates.append(contentsOf: Self.makeExecutableCandidates(forAppURL: appURL))
        }

        var seen = Set<String>()
        var profiles: [KakuLaunchProfile] = []
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            guard seen.insert(path).inserted else {
                continue
            }
            let executableName = URL(fileURLWithPath: path).lastPathComponent
            let helpOutput = commandOutput(executablePath: path, arguments: ["--help"]) ?? ""
            let startHelpOutput: String? = executableName == "kaku-gui"
                ? commandOutput(executablePath: path, arguments: ["start", "--help"])
                : nil
            let cliHelpOutput: String? = executableName == "kaku"
                ? commandOutput(executablePath: path, arguments: ["cli", "--help"])
                : nil

            if let profile = Self.detectExecutableProfile(
                executablePath: path,
                helpOutput: helpOutput,
                startHelpOutput: startHelpOutput,
                cliHelpOutput: cliHelpOutput
            ) {
                profiles.append(profile)
                Self.logger.info(
                    "kaku profile detected exec=\(path, privacy: .public) style=\(String(describing: profile.commandStyle), privacy: .public) supportsNewTab=\(profile.supportsNewTab, privacy: .public) supportsPosition=\(profile.supportsPosition, privacy: .public)"
                )
            } else {
                Self.logger.error("kaku profile detection failed exec=\(path, privacy: .public)")
            }
        }
        return profiles.isEmpty ? nil : profiles
    }

    private func runKaku(
        executablePath: String,
        arguments: [String],
        allowLongRunningProcess: Bool
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stderrPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = stdoutPipe

        do {
            try process.run()
        } catch {
            Self.logger.error("kaku run failed exec=\(executablePath, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(error.localizedDescription)
        }

        let waitDeadline = Date().addingTimeInterval(allowLongRunningProcess ? 0.35 : 1.2)
        while process.isRunning, Date() < waitDeadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        if process.isRunning {
            guard allowLongRunningProcess else {
                process.terminate()
                Self.logger.error("kaku command kept running while existing instance was expected, terminated to avoid duplicate GUI")
                throw AdapterLaunchError.processStartFailed("Kaku did not hand off to the existing instance")
            }
            Self.logger.info("kaku command still running, treat as launched")
            return
        }

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""
        let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
        let combinedOutput = "\(stdoutOutput)\n\(stderrOutput)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            Self.logger.error("kaku exit failed code=\(process.terminationStatus) output=\(combinedOutput, privacy: .public)")
            throw AdapterLaunchError.nonZeroExit(code: process.terminationStatus, output: combinedOutput)
        }

        guard !Self.looksLikeFailureOutput(combinedOutput) else {
            Self.logger.error("kaku exited with failure-like output=\(combinedOutput, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(combinedOutput)
        }

        Self.logger.info("kaku exit success")
    }

    private func commandOutput(executablePath: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Self.logger.error("kaku help run failed exec=\(executablePath, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            return nil
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""
        let combinedOutput = "\(stdoutOutput)\n\(stderrOutput)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            Self.logger.error("kaku help exit failed exec=\(executablePath, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public) code=\(process.terminationStatus) output=\(combinedOutput, privacy: .public)")
            return nil
        }

        return combinedOutput
    }

    private func openViaService(name: String, path: URL) -> Bool {
        NSUpdateDynamicServices()
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("com.liangzhiyuan.pathbridge.kaku.\(UUID().uuidString)")
        )
        let fileNamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        pasteboard.clearContents()
        pasteboard.declareTypes([fileNamesType, .fileURL, .string], owner: nil)
        pasteboard.setPropertyList([path.path], forType: fileNamesType)
        pasteboard.setString(path.absoluteString, forType: .fileURL)
        pasteboard.setString(path.path, forType: .string)

        let performed = NSPerformService(name, pasteboard)
        Self.logger.info("kaku service performed=\(performed, privacy: .public) name=\(name, privacy: .public)")
        return performed
    }

    private func activateKaku() {
        guard let bundleIdentifier else {
            return
        }

        let deadline = Date().addingTimeInterval(1.0)
        while Date() < deadline {
            if let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).last {
                let activated = application.activate(options: [.activateAllWindows])
                Self.logger.info("kaku activate result=\(activated, privacy: .public)")
                return
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        Self.logger.error("kaku activate skipped reason=running-application-not-found")
    }

    private func isKakuRunning() -> Bool {
        guard let bundleIdentifier else {
            return false
        }
        return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    private static func looksLikeFailureOutput(_ output: String) -> Bool {
        guard !output.isEmpty else {
            return false
        }
        let normalized = output.lowercased()
        return normalized.contains("failed to connect")
            || normalized.contains("failed to connect to socket")
            || normalized.contains("terminating")
            || normalized.contains("no such file or directory")
            || normalized.contains("unable to determine cwd")
    }
}
