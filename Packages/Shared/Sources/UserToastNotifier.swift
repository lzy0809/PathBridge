import Foundation

#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

public enum UserToastNotifier {
    public static func showUnsupportedTerminal(_ terminalName: String, detail: String) {
        show(title: "PathBridge 暂不支持", body: "\(terminalName)：\(detail)")
    }

    public static func show(title: String, body: String) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                enqueue(center: center, title: title, body: body)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    enqueue(center: center, title: title, body: body)
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
        #endif
    }

    #if canImport(UserNotifications)
    private static func enqueue(center: UNUserNotificationCenter, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
    #endif
}
