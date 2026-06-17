import Foundation
import VerifyBlind

/// SDK orkestrasyonu + ön plan polling + geliştirici log.
/// example-mobile-android `MainActivity` mantığının SwiftUI karşılığı.
@MainActor
final class DemoViewModel: ObservableObject {

    // UI durumu
    @Published var ageOver18 = true
    @Published var requestUserId = true
    @Published var isBusy = false
    @Published var statusText: String?
    @Published var isSuccess = false
    @Published var resultText = "// Doğrulama bekleniyor…"
    @Published var logText = ""

    private let sdk = VerifyBlindSDK(config: VerifyBlindConfig(
        partnerBackendUrl: DemoConfig.partnerBackendURL,
        generateEndpoint: DemoConfig.generateEndpoint,
        verifyblindApiUrl: DemoConfig.verifyblindApiURL
    ))

    private var activeNonce: String?
    private var pollTask: Task<Void, Never>?

    // MARK: - Eylemler

    func startVerification() {
        guard !isBusy else { return }
        isBusy = true
        isSuccess = false
        statusText = nil
        resultText = "// Doğrulama bekleniyor…"
        appendLog("startAuthentication() başlatıldı")

        let validations = currentValidations()
        if let v = validations { appendLog("Validations: \(v)") }

        Task {
            do {
                appendLog("VerifyBlind açılıyor…")
                let result = try await sdk.startAuthentication(validations: validations)
                activeNonce = result.nonce
                appendLog("İstek oluşturuldu. Nonce: \(result.nonce)")
                appendLog("VerifyBlind'de tamamla; uygulamaya dönünce sonuç sorgulanır.")
                // Polling, uygulama ön plana dönünce resumePolling() ile başlar.
            } catch let e as VerifyBlindError {
                isBusy = false
                if e.code == .userCancelled { showCancelled(e) } else { showError(e.message) }
            } catch {
                isBusy = false
                showError(error.localizedDescription)
            }
        }
    }

    /// scenePhase `.active` olunca çağrılır (ön plan garantisi).
    func resumePolling() {
        guard let nonce = activeNonce, pollTask == nil else { return }
        isBusy = true
        pollTask = Task { await poll(nonce: nonce) }
    }

    /// scenePhase `.background` olunca çağrılır.
    func cancelPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func clearLog() { logText = "" }

    // MARK: - Polling

    private func poll(nonce: String) async {
        appendLog("Sonuç bekleniyor (polling)…")
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
                if e.code == .userCancelled { showCancelled(e) } else { showError(e.message) }
                activeNonce = nil
                return
            } catch {
                showError(error.localizedDescription)
                activeNonce = nil
                return
            }
            if count % 10 == 0 { appendLog("… bekleniyor (\(count)s)") }
        }
        if !Task.isCancelled {
            appendLog("Zaman aşımı. Uygulamaya tekrar dönünce sorgu sürer.")
        }
    }

    // MARK: - Sonuç / durum

    private func currentValidations() -> [String: Any]? {
        var v: [String: Any] = [:]
        if ageOver18 { v["age"] = "18+" }
        if requestUserId { v["user_id"] = true }
        return v.isEmpty ? nil : v
    }

    private func applyResult(_ result: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
           let s = String(data: data, encoding: .utf8) {
            resultText = s
        } else {
            resultText = String(describing: result)
        }
        isSuccess = true
        statusText = "● Başarılı"
        appendLog("Sonuç alındı ve gösterildi.")
    }

    private func showCancelled(_ e: VerifyBlindError) {
        let detail: String
        switch e.cancelReason {
        case "no_card_registered": detail = "Kullanıcının VerifyBlind uygulamasında kayıtlı kimlik kartı yok."
        case "user_declined":      detail = "Kullanıcı veri paylaşımına izin vermedi."
        case "fingerprint_failed": detail = "Biyometrik doğrulama başarısız."
        case "session_expired":    detail = "Mobil oturum süresi doldu. Tekrar deneyin."
        default:                   detail = "Kullanıcı kimlik doğrulamayı iptal etti."
        }
        resultText = "// iptal\n// \(detail)"
        isSuccess = false
        statusText = "● İptal"
        appendLog("İptal: \(e.cancelReason ?? "user_cancelled") — \(detail)")
    }

    private func showError(_ message: String) {
        resultText = "// hata: \(message)"
        isSuccess = false
        statusText = "● Hata"
        appendLog("❌ \(message)")
    }

    private func appendLog(_ message: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        logText += "[\(f.string(from: Date()))] \(message)\n"
    }
}
