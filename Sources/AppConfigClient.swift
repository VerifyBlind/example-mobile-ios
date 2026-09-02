import Foundation

/// Fetches GET /api/public/app-config and decides whether the local EXAMPLE preview is enabled for
/// this build. Best-effort: any failure / empty value / version mismatch → false (real flow).
enum AppConfigClient {
    static func isPreviewEnabled(apiBaseUrl: String, appVersion: String) async -> Bool {
        let base = apiBaseUrl.hasSuffix("/") ? String(apiBaseUrl.dropLast()) : apiBaseUrl
        guard let url = URL(string: base + "/api/public/app-config") else { return false }
        var req = URLRequest(url: url)
        req.timeoutInterval = 5
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return false }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
            let previewVersion = (json["preview_version_example_ios"] as? String) ?? ""
            return !previewVersion.isEmpty && previewVersion == appVersion
        } catch {
            return false
        }
    }
}
