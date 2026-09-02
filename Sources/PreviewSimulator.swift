import Foundation

/// Self-contained (UIKit-free) logic for the local EXAMPLE preview. No network, no SDK, no main app.
/// Produces the same result shape `DemoViewModel.applyResult` renders from a real verification.
enum PreviewSimulator {
    static let exampleNonce = "example-nonce"

    static func buildExampleResult(ageOver18: Bool, requestUserId: Bool) -> [String: Any] {
        var result: [String: Any] = [:]
        if requestUserId { result["user_id"] = "example-user-id-token" }
        var validations: [String: Any] = [:]
        if ageOver18 { validations["age"] = "18+" }
        if !validations.isEmpty { result["validations"] = validations }
        result["nsbd_id"] = "example"
        result["doc_id"] = "example"
        return result
    }
}
