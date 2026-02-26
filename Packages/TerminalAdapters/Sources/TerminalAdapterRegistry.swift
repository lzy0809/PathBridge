import Foundation

@MainActor
public final class TerminalAdapterRegistry {
    public static let shared = TerminalAdapterRegistry()

    private init() {}

    private var adapters: [any TerminalAdapter] = []

    public func register(_ adapter: any TerminalAdapter) {
        adapters.append(adapter)
    }

    public func installedAdapters() -> [any TerminalAdapter] {
        adapters.filter { $0.isInstalled() }
    }
}
