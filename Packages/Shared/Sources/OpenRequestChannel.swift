import Foundation

public enum OpenRequestChannel {
    public static let notificationName = Notification.Name("com.liangzhiyuan.pathbridge.open-request")
    public static let payloadKey = "payload"

    public static func post(_ request: OpenRequest) throws {
        let data = try JSONEncoder().encode(request)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "PathBridge.OpenRequestChannel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode OpenRequest payload"]
            )
        }

        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: nil,
            userInfo: [payloadKey: payload],
            options: [.deliverImmediately]
        )
    }

    public static func decode(from userInfo: [AnyHashable: Any]?) -> OpenRequest? {
        guard
            let payload = userInfo?[payloadKey] as? String,
            let data = payload.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONDecoder().decode(OpenRequest.self, from: data)
    }
}

