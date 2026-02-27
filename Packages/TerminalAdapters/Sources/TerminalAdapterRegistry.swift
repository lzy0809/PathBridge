import Foundation
import OSLog

@MainActor
public final class TerminalAdapterRegistry {
    public static let shared = TerminalAdapterRegistry()
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.adapters", category: "registry")

    private var adapters: [any TerminalAdapter]

    public init(adapters: [any TerminalAdapter]? = nil) {
        self.adapters = adapters ?? [
            SystemTerminalAdapter(),
            ITerm2Adapter(),
            WarpAdapter(),
            WezTermAdapter(),
            GhosttyAdapter(),
            KakuAdapter(),
        ]
    }

    public func register(_ adapter: any TerminalAdapter) {
        adapters.append(adapter)
    }

    public func allAdapters() -> [any TerminalAdapter] {
        adapters
    }

    public func installedAdapters() -> [any TerminalAdapter] {
        adapters.filter { $0.isInstalled() }
    }

    public func preferredAdapter(preferredID: String?) -> any TerminalAdapter {
        if let preferredID,
           let preferred = adapters.first(where: { $0.id == preferredID }) {
            Self.logger.info("preferredAdapter hit id=\(preferredID, privacy: .public)")
            return preferred
        }
        Self.logger.info("preferredAdapter miss id=\(preferredID ?? "nil", privacy: .public), fallback defaultAdapter")
        return defaultAdapter(preferredID: preferredID)
    }

    public func defaultAdapter(preferredID: String?) -> any TerminalAdapter {
        if let preferredID,
           let preferred = adapters.first(where: { $0.id == preferredID && $0.isInstalled() }) {
            Self.logger.info("defaultAdapter using installed preferred id=\(preferredID, privacy: .public)")
            return preferred
        }

        if let system = adapters.first(where: { $0.id == "system-terminal" }) {
            Self.logger.info("defaultAdapter fallback system-terminal")
            return system
        }

        if let firstInstalled = installedAdapters().first {
            Self.logger.info("defaultAdapter fallback firstInstalled id=\(firstInstalled.id, privacy: .public)")
            return firstInstalled
        }

        if let first = adapters.first {
            Self.logger.info("defaultAdapter fallback firstRegistered id=\(first.id, privacy: .public)")
            return first
        }

        Self.logger.info("defaultAdapter fallback synthesized system-terminal")
        return SystemTerminalAdapter()
    }

    public func adapter(id: String) -> (any TerminalAdapter)? {
        adapters.first(where: { $0.id == id })
    }
}
