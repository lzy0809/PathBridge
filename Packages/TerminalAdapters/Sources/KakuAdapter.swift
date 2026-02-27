import AppKit
import Foundation
import OSLog
import PathBridgeShared

public struct KakuAdapter: TerminalAdapter {
    public let id = "kaku"
    public let displayName = "Kaku"
    public let bundleIdentifier: String? = "fun.tw93.kaku"
    private let supportedBundleIDs = [
        "fun.tw93.kaku",
    ]
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "kaku-adapter")

    public init() {}

    public func isInstalled() -> Bool {
        for candidate in supportedBundleIDs {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) != nil {
                return true
            }
        }
        return false
    }

    public func open(paths: [URL], mode: OpenMode, command: String?) throws {
        guard let cliPath = resolveCLIPath() else {
            throw AdapterLaunchError.processStartFailed("Kaku CLI not found")
        }

        for path in paths {
            let arguments = Self.makeCLIArguments(mode: mode, cwd: path)
            Self.logger.info("kaku launch path=\(path.path, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public)")
            try runKaku(cliPath: cliPath, arguments: arguments)
        }
    }

    static func makeCLIArguments(mode: OpenMode, cwd: URL) -> [String] {
        var arguments = ["start"]
        if mode == .newTab {
            arguments.append("--new-tab")
        }
        arguments += ["--cwd", cwd.path]
        return arguments
    }

    private func resolveCLIPath() -> String? {
        for candidate in supportedBundleIDs {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) else {
                continue
            }
            let cliPath = appURL
                .appendingPathComponent("Contents/MacOS/kaku", isDirectory: false)
                .path
            if FileManager.default.isExecutableFile(atPath: cliPath) {
                return cliPath
            }
        }

        let fallbackPath = "/Applications/Kaku.app/Contents/MacOS/kaku"
        return FileManager.default.isExecutableFile(atPath: fallbackPath) ? fallbackPath : nil
    }

    private func runKaku(cliPath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = arguments

        let stderrPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = stdoutPipe

        do {
            try process.run()
        } catch {
            Self.logger.error("kaku run failed error=\(error.localizedDescription, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(error.localizedDescription)
        }

        let waitDeadline = Date().addingTimeInterval(0.35)
        while process.isRunning, Date() < waitDeadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        if process.isRunning {
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

    private static func looksLikeFailureOutput(_ output: String) -> Bool {
        guard !output.isEmpty else {
            return false
        }
        let normalized = output.lowercased()
        return normalized.contains("failed to connect")
            || normalized.contains("terminating")
            || normalized.contains("no such file or directory")
    }
}
