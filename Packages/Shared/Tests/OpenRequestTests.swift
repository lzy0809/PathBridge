import Foundation
import XCTest
@testable import PathBridgeShared

final class OpenRequestTests: XCTestCase {
    func test_decodeLegacyPayloadWithoutRequestID_generatesRequestID() throws {
        let json = """
        {
          \"paths\": [\"/tmp\"],
          \"terminalID\": \"warp\",
          \"mode\": \"newWindow\",
          \"commandTemplate\": null
        }
        """

        let request = try JSONDecoder().decode(OpenRequest.self, from: Data(json.utf8))

        XCTAssertFalse(request.requestID.isEmpty)
        XCTAssertEqual(request.terminalID, "warp")
    }

    func test_roundTrip_preservesRequestID() throws {
        let request = OpenRequest(
            paths: ["/tmp"],
            terminalID: "kaku",
            mode: .newTab,
            commandTemplate: nil,
            requestID: "req-123"
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(OpenRequest.self, from: encoded)

        XCTAssertEqual(decoded.requestID, "req-123")
        XCTAssertEqual(decoded.mode, .newTab)
    }
}

