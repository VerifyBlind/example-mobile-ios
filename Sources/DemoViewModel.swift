import Foundation
import UIKit
import VerifyBlind

/// SDK orkestrasyonu + ön plan polling + geliştirici log.
/// example-mobile-android `MainActivity` mantığının/mesajlarının SwiftUI karşılığı (birebir).
@MainActor
final class DemoViewModel: ObservableObject {

    // UI durumu
    @Published var ageOver18 = true
    @Published var requestUserId = true
    @Published var isBusy = false
    @Published var statusText: String?       // pill metni (nil → gizli)
    @Published var statusIsSuccess = true     // pill rengi
    @Published var resultText = L("result_initial")
    @Published var logText = ""
    @Published var overlayKey = "overlay_opening"
    @Published var toastText: String?

    private let sdk = VerifyBlindSDK(config: VerifyBlindConfig(
        partnerBackendUrl: DemoConfig.partnerBackendURL,
        generateEndpoint: DemoConfig.generateEndpoint,
        verifyblindAppLinkBase: DemoConfig.appLinkBase,
        verifyblindApiUrl: DemoConfig.verifyblindApiURL
    ))

    private var activeNonce: String?
    private var pollTask: Task<Void, Never>?

    init() {
        // Android: XML default log_initial + onCreate'te log_ready / log_env
        logText = L("log_initial")
        appendLog(L("log_ready"))
        appendLog(L("log_env", "PRODUCTION"))
    }

    // MARK: - Eylemler

    func startVerification() {
        guard !isBusy else { return }
        let validations = currentValidations()

        isBusy = true
        overlayKey = "overlay_opening"
        statusText = nil
        resultText = L("result_initial")
        appendLog("━━━━━━━━━━━━━━━━")
        appendLog(L("log_start"))
        if let v = validations { appendLog(L("log_validations", "\(v)")) }

        Task {
            do {
                appendLog(L("log_opening"))
                let result = try await sdk.startAuthentication(validations: validations,
                                                               returnUrl: DemoConfig.returnUrl)
                activeNonce = result.nonce
                appendLog(L("log_request_created", result.nonce))
                appendLog(L("log_complete_in_app"))
                // Polling, uygulama ön plana dönünce resumePolling() ile başlar.
            } catch let e as VerifyBlindError {
                isBusy = false
                if e.code == .userCancelled {
                    showCancelled(e)
                } else {
                    appendLog("❌ [\(e.code.rawValue)] \(e.message)")
                    showError(L("err_start", e.message))
                }
            } catch {
                isBusy = false
                appendLog("❌ \(error.localizedDescription)")
                showError(error.localizedDescription)
            }
        }
    }

    /// scenePhase `.active` → ön planda poll (Android onResume paritesi).
    func resumePolling() {
        guard let nonce = activeNonce, pollTask == nil else { return }
        isBusy = true
        overlayKey = "overlay_waiting"
        pollTask = Task { await poll(nonce: nonce) }
    }

    /// scenePhase `.background` → poll'u durdur (Android onPause paritesi).
    func cancelPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Kullanıcı beklemeyi keser (VerifyBlind'da vazgeçti / akış yarıda kaldı). Polling'i durdurur,
    /// aktif nonce'u bırakır ve UI'yı sıfırlar → hemen yeni istek gönderilebilir (Item 3c parite).
    func cancelAndReset() {
        pollTask?.cancel()
        pollTask = nil
        activeNonce = nil
        isBusy = false
        statusText = nil
        appendLog(L("log_polling_cancelled"))
    }

    func clearLog() { logText = L("log_cleared") }

    func copyResult() {
        UIPasteboard.general.string = resultText
        showToast(L("toast_copied"))
    }

    func copyLog() {
        UIPasteboard.general.string = logText
        showToast(L("toast_log_copied"))
    }

    private func showToast(_ text: String) {
        toastText = text
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            toastText = nil
        }
    }

    // MARK: - Polling

    private func poll(nonce: String) async {
        appendLog(L("log_polling"))
        var count = 0
        defer {
            isBusy = false
            pollTask = nil
        }
        while count < 60 && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }
            count += 1
            do {
                if let result = try await sdk.checkVerificationResult(nonce: nonce) {
                    applyResult(result)
                    activeNonce = nil
                    return
                }
            } catch let e as VerifyBlindError {
                if e.code == .userCancelled {
                    showCancelled(e)
                } else {
                    appendLog("❌ [\(e.code.rawValue)] \(e.message)")
                    showError(L("err_start", e.message))
                }
                activeNonce = nil
                return
            } catch {
                appendLog("❌ \(error.localizedDescription)")
                showError(error.localizedDescription)
                activeNonce = nil
                return
            }
            if count % 10 == 0 { appendLog(L("log_waiting_secs", "\(count)")) }
        }
        if !Task.isCancelled { appendLog(L("log_timeout")) }
    }

    // MARK: - Sonuç / durum (Android applyResult/showCancelled/showError paritesi)

    private func currentValidations() -> [String: Any]? {
        var v: [String: Any] = [:]
        if ageOver18 { v["age"] = "18+" }
        if requestUserId { v["user_id"] = true }
        return v.isEmpty ? nil : v
    }

    private func applyResult(_ result: [String: Any]) {
        var pairs: [(String, String)] = []
        if let uid = result["user_id"] as? String { pairs.append(("user_id", uid)) }
        if let validations = result["validations"] as? [String: Any] {
            for (k, v) in validations { pairs.append((k, formatVal(v))) }
        }
        if let nsbd = result["nsbd_id"] { pairs.append(("nsbd_id", "\(nsbd)")) }
        if let doc = result["doc_id"] { pairs.append(("doc_id", "\(doc)")) }
        let reserved: Set<String> = ["user_id", "nsbd_id", "doc_id", "nonce", "validations"]
        for (k, v) in result where !reserved.contains(k) { pairs.append((k, formatVal(v))) }

        resultText = jsonString(pairs)
        statusText = L("status_success")
        statusIsSuccess = true
        appendLog(L("log_result_applied"))
    }

    private func showCancelled(_ e: VerifyBlindError) {
        let title: String, detail: String
        switch e.cancelReason {
        case "no_card_registered": title = L("cancel_no_card_title");      detail = L("cancel_no_card_detail")
        case "user_declined":      title = L("cancel_declined_title");     detail = L("cancel_declined_detail")
        case "fingerprint_failed": title = L("cancel_fingerprint_title");  detail = L("cancel_fingerprint_detail")
        case "session_expired":    title = L("cancel_session_title");      detail = L("cancel_session_detail")
        default:                   title = L("cancel_generic_title");      detail = L("cancel_generic_detail")
        }
        appendLog(L("log_cancel", title, e.cancelReason ?? "user_cancelled"))
        resultText = L("result_cancelled_block", title, detail)
        statusText = "● \(title)"
        statusIsSuccess = false
    }

    private func showError(_ message: String) {
        resultText = L("result_error_block", message)
        statusText = L("status_error")
        statusIsSuccess = false
    }

    // MARK: - Yardımcılar

    private func formatVal(_ v: Any) -> String {
        if let b = v as? Bool { return b ? L("value_yes") : L("value_no") }
        return "\(v)"
    }

    private func jsonString(_ pairs: [(String, String)]) -> String {
        if pairs.isEmpty { return "{}" }
        let body = pairs.map { "  \"\(escape($0.0))\": \"\(escape($0.1))\"" }.joined(separator: ",\n")
        return "{\n\(body)\n}"
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func appendLog(_ message: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        logText += "[\(f.string(from: Date()))] \(message)\n"
    }
}
