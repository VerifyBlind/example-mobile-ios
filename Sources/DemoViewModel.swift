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
    @Published var previewEnabled = false
    @Published var buttonKey = "btn_verify"
    @Published var statusIsExample = false
    /// [Tamam] butonlu hata diyaloğu (nil → gizli). Bağlantı sorunu sessizce log kartına
    /// yazılmak yerine kullanıcıya açıkça söylenir.
    @Published var alert: DemoAlert?

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

    /// Launch-time gate fetch. Any failure → previewEnabled stays false (real flow).
    func loadConfig() async {
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let enabled = await AppConfigClient.isPreviewEnabled(
            apiBaseUrl: DemoConfig.verifyblindApiURL, appVersion: version
        )
        previewEnabled = enabled
        buttonKey = enabled ? "btn_preview" : "btn_verify"
    }

    // MARK: - Eylemler

    func startVerification() {
        guard !isBusy else { return }
        if previewEnabled { runPreview(); return }
        statusIsExample = false
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
                    reportFailure(e, technical: L("err_start", e.message))
                }
            } catch {
                isBusy = false
                appendLog("❌ \(error.localizedDescription)")
                reportFailure(error, technical: error.localizedDescription)
            }
        }
    }

    /// Local, self-contained EXAMPLE flow. No SDK, no network, no main app.
    private func runPreview() {
        isBusy = true
        overlayKey = "overlay_opening"
        statusText = nil
        resultText = L("result_initial")
        appendLog("━━━━━━━━━━━━━━━━")
        appendLog(L("log_start"))
        appendLog(L("log_preview_marker"))

        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            appendLog(L("log_opening"))
            try? await Task.sleep(nanoseconds: 600_000_000)
            appendLog(L("log_request_created", PreviewSimulator.exampleNonce))
            appendLog(L("log_complete_in_app"))
            try? await Task.sleep(nanoseconds: 600_000_000)
            appendLog(L("log_polling"))
            try? await Task.sleep(nanoseconds: 800_000_000)

            let example = PreviewSimulator.buildExampleResult(
                ageOver18: ageOver18, requestUserId: requestUserId
            )
            applyExampleResult(example)
            isBusy = false
        }
    }

    private func applyExampleResult(_ result: [String: Any]) {
        applyResult(result)              // reuse the exact real renderer
        statusText = L("status_example") // then override the badge to EXAMPLE
        statusIsSuccess = true
        statusIsExample = true
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
                    reportFailure(e, technical: L("err_start", e.message))
                }
                activeNonce = nil
                return
            } catch {
                appendLog("❌ \(error.localizedDescription)")
                reportFailure(error, technical: error.localizedDescription)
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
        statusIsExample = false
    }

    /// Hatayı kullanıcıya gösterir: bağlantı sorunuysa kanonik "internetini kontrol et" metni +
    /// [Tamam] diyaloğu, değilse geliştiriciye dönük teknik metin (bu bir entegrasyon örneği).
    ///
    /// Neden: ham hata metni ekrana basıldığında kullanıcı internetsizken sistemin teknik
    /// satırını ya da `Partner backend'e ulaşılamadı: …` gibi sunucu adı içeren bir metni
    /// görüyordu — anlaşılmaz olmasının yanında servis çökmüş izlenimi veriyordu.
    private func reportFailure(_ error: Error, technical: String) {
        if Self.isConnectionProblem(error) {
            showError(L("err_no_connection"))
            alert = DemoAlert(title: L("err_no_connection_title"), message: L("err_no_connection"))
        } else {
            showError(technical)
            alert = DemoAlert(title: L("err_title"), message: technical)
        }
    }

    /// HTTP cevabı hiç alınamadı mı (DNS/TCP/TLS/timeout)? SDK bunu `networkError` ile bildirir;
    /// doğrudan yakalanan hatalarda taşıma hataları `URLError`/`NSURLErrorDomain` altındadır.
    /// SDK hatayı sarmaladığı için `underlyingError` de taranır.
    static func isConnectionProblem(_ error: Error, depth: Int = 0) -> Bool {
        guard depth < 5 else { return false }
        if let e = error as? VerifyBlindError {
            if e.code == .networkError || e.code == .ipFetchFailed { return true }
            if let underlying = e.underlyingError {
                return isConnectionProblem(underlying, depth: depth + 1)
            }
            return false
        }
        if error is URLError { return true }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain || ns.domain == NSPOSIXErrorDomain { return true }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            return isConnectionProblem(underlying, depth: depth + 1)
        }
        return false
    }

    private func showError(_ message: String) {
        resultText = L("result_error_block", message)
        statusText = L("status_error")
        statusIsSuccess = false
        statusIsExample = false
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

/// SwiftUI `.alert(_:isPresented:presenting:)` için kimlikli hata kutusu.
struct DemoAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
