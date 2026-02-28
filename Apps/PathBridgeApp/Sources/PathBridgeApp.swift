import SwiftUI

@main
struct PathBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("PathBridge") {
            ContentView()
        }
        .defaultSize(width: 420, height: 410)
        .windowResizability(.automatic)
    }
}
