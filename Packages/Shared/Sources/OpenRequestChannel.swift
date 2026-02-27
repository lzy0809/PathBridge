import Foundation
import OSLog

public enum OpenRequestChannel {
    public static let notificationName = Notification.Name("com.liangzhiyuan.pathbridge.open-request")
    public static let payloadKey = "payload"
    private static let logger = Logger(subsystem: "com.liangzhiyuan.pathbridge.shared", category: "open-request-channel")

    public static func post(_ request: OpenRequest) throws {
        let data = try JSONEncoder().encode(request)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "PathBridge.OpenRequestChannel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode OpenRequest payload"]
            )
        }

        logger.info(
            "post requestID=\(request.requestID, privacy: .public) terminal=\(request.terminalID, privacy: .public) mode=\(request.mode.rawValue, privacy: .public) count=\(request.paths.count)"
        )

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
            logger.error("decode missing payload")
            return nil
        }
        guard let request = try? JSONDecoder().decode(OpenRequest.self, from: data) else {
            logger.error("decode payload failed")
            return nil
        }
        logger.info(
            "decode requestID=\(request.requestID, privacy: .public) terminal=\(request.terminalID, privacy: .public) mode=\(request.mode.rawValue, privacy: .public) count=\(request.paths.count)"
        )
        return request
    }
}
