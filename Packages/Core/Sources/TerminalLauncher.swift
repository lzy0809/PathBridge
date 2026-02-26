import Foundation

public enum TerminalLaunchError: LocalizedError {
    case emptySelection
    case processStartFailed(String)
    case nonZeroExit(code: Int32, output: String)

    public var errorDescription: String? {
        switch self {
        case .emptySelection:
            return "No valid path selected in Finder."
        case let .processStartFailed(reason):
            return "Failed to start Terminal launch process: \(reason)"
        case let .nonZeroExit(code, output):
            return "Terminal launch failed with code \(code): \(output)"
        }
    }
}

public enum TerminalLauncher {
    public static func openInSystemTerminal(urls: [URL]) throws {
        let normalized = SelectionResolver.normalize(urls)
        let paths = normalized.map(\.path)
        guard !paths.isEmpty else {
            throw TerminalLaunchError.emptySelection
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal"] + paths

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw TerminalLaunchError.processStartFailed(error.localizedDescription)
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let outputData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            throw TerminalLaunchError.nonZeroExit(code: process.terminationStatus, output: output)
        }
    }
}

