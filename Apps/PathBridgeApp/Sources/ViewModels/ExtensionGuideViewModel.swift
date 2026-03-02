import Foundation

enum ExtensionGuideState: Equatable {
    case defaultGuide
    case autoInstalled
    case manualInstallRequired
}

@MainActor
final class ExtensionGuideViewModel: ObservableObject {
    @Published private(set) var state: ExtensionGuideState = .defaultGuide

    private let installer = FinderToolbarInstaller()

    func installToFinderToolbar() {
        switch installer.install() {
        case .autoInstalled:
            state = .autoInstalled
        case .requiresManualInstall:
            installer.revealForManualInstall()
            state = .manualInstallRequired
        }
    }
}
