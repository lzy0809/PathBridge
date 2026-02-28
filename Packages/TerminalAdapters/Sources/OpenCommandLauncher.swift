import AppKit
import Foundation
import OSLog
import PathBridgeShared

enum OpenCommandLauncher {
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "open-command")

    static func isInstalled(bundleIdentifiers: [String], appNames: [String]) -> Bool {
        resolveApplicationURL(bundleIdentifiers: bundleIdentifiers, appNames: appNames) != nil
    }

    static func open(bundleIdentifiers: [String], appName: String, paths: [URL], mode: OpenMode) throws {
        try open(bundleIdentifiers: bundleIdentifiers, appNames: [appName], paths: paths, mode: mode)
    }

    static func open(bundleIdentifiers: [String], appNames: [String], paths: [URL], mode: OpenMode) throws {
        let primaryName = appNames.first ?? "Terminal"
        logger.info(
            "attempt bundle launch appName=\(primaryName, privacy: .public) mode=\(mode.rawValue, privacy: .public) pathCount=\(paths.count)"
        )
        if let resolvedURL = resolveApplicationURL(bundleIdentifiers: bundleIdentifiers, appNames: appNames) {
            do {
                logger.info("bundle resolved appURL=\(resolvedURL.path, privacy: .public)")
                try open(arguments: arguments(bundleIdentifier: nil, appPath: resolvedURL.path, appName: nil, paths: paths, mode: mode))
                return
            } catch {
                logger.error(
                    "bundle launch failed appURL=\(resolvedURL.path, privacy: .public) error=\(error.localizedDescription, privacy: .public), fallback to appName"
                )
                // Fall back to app name if bundle launch fails unexpectedly.
            }
        }

        try open(appName: primaryName, paths: paths, mode: mode)
    }

    static func open(appName: String, paths: [URL], mode: OpenMode) throws {
        logger.info("attempt app launch appName=\(appName, privacy: .public) mode=\(mode.rawValue, privacy: .public) pathCount=\(paths.count)")
        if let resolvedURL = resolveApplicationURL(bundleIdentifiers: [], appNames: [appName]) {
            logger.info("app resolved appURL=\(resolvedURL.path, privacy: .public)")
            try open(arguments: arguments(bundleIdentifier: nil, appPath: resolvedURL.path, appName: nil, paths: paths, mode: mode))
            return
        }
        try open(arguments: arguments(bundleIdentifier: nil, appPath: nil, appName: appName, paths: paths, mode: mode))
    }

    private static func arguments(bundleIdentifier: String?, appPath: String?, appName: String?, paths: [URL], mode: OpenMode) -> [String] {
        var args: [String] = []
        if mode == .newWindow {
            args.append("-n")
        }
        if let bundleIdentifier {
            args += ["-b", bundleIdentifier]
        } else if let appPath {
            args += ["-a", appPath]
        } else if let appName {
            args += ["-a", appName]
        }
        args += paths.map(\.path)
        return args
    }

    private static func open(arguments: [String]) throws {
        let joinedArguments = arguments.joined(separator: " ")
        logger.info("run /usr/bin/open arguments=\(joinedArguments, privacy: .public)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = arguments

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            logger.error("process run failed error=\(error.localizedDescription, privacy: .public)")
            throw AdapterLaunchError.processStartFailed(error.localizedDescription)
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let outputData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            logger.error("process exit failed code=\(process.terminationStatus) stderr=\(output, privacy: .public)")
            throw AdapterLaunchError.nonZeroExit(code: process.terminationStatus, output: output)
        }
        logger.info("process exit success")
    }

    private static func resolveApplicationURL(bundleIdentifiers: [String], appNames: [String]) -> URL? {
        for bundleIdentifier in bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return appURL
            }
        }

        for appName in appNames {
            if let appURL = scanCommonApplicationDirectories(appName: appName) {
                return appURL
            }
        }
        return nil
    }

    private static func scanCommonApplicationDirectories(appName: String) -> URL? {
        let normalizedName = appName.hasSuffix(".app") ? appName : "\(appName).app"
        var candidateNames = [normalizedName]

        if appName.caseInsensitiveCompare("iTerm") == .orderedSame {
            candidateNames.append("iTerm2.app")
        }
        if appName.caseInsensitiveCompare("iTerm2") == .orderedSame {
            candidateNames.append("iTerm.app")
        }

        let roots: [URL] = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Setapp", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
        ]

        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            for candidateName in candidateNames {
                let candidate = root.appendingPathComponent(candidateName, isDirectory: true)
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        return nil
    }
}

enum AdapterLaunchError: LocalizedError {
    case processStartFailed(String)
    case nonZeroExit(code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case let .processStartFailed(reason):
            return "Failed to start terminal process: \(reason)"
        case let .nonZeroExit(code, output):
            return "Terminal process exited with code \(code): \(output)"
        }
    }
}
