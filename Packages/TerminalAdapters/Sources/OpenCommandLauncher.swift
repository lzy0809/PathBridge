import AppKit
import Foundation
import OSLog
import PathBridgeShared

enum OpenCommandLauncher {
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "open-command")

    static func open(bundleIdentifiers: [String], appName: String, paths: [URL], mode: OpenMode) throws {
        logger.info(
            "attempt bundle launch appName=\(appName, privacy: .public) mode=\(mode.rawValue, privacy: .public) pathCount=\(paths.count)"
        )
        if let bundleIdentifier = resolveBundleIdentifier(bundleIdentifiers: bundleIdentifiers) {
            do {
                logger.info("bundle resolved bundleID=\(bundleIdentifier, privacy: .public)")
                try open(arguments: arguments(bundleIdentifier: bundleIdentifier, appName: nil, paths: paths, mode: mode))
                return
            } catch {
                logger.error(
                    "bundle launch failed bundleID=\(bundleIdentifier, privacy: .public) error=\(error.localizedDescription, privacy: .public), fallback to appName"
                )
                // Fall back to app name if bundle launch fails unexpectedly.
            }
        }

        try open(appName: appName, paths: paths, mode: mode)
    }

    static func open(appName: String, paths: [URL], mode: OpenMode) throws {
        logger.info("attempt app launch appName=\(appName, privacy: .public) mode=\(mode.rawValue, privacy: .public) pathCount=\(paths.count)")
        try open(arguments: arguments(bundleIdentifier: nil, appName: appName, paths: paths, mode: mode))
    }

    private static func arguments(bundleIdentifier: String?, appName: String?, paths: [URL], mode: OpenMode) -> [String] {
        var args: [String] = []
        if mode == .newWindow {
            args.append("-n")
        }
        if let bundleIdentifier {
            args += ["-b", bundleIdentifier]
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

    private static func resolveBundleIdentifier(bundleIdentifiers: [String]) -> String? {
        for bundleIdentifier in bundleIdentifiers {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil {
                return bundleIdentifier
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
