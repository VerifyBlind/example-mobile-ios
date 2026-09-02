import Foundation

/// Demo yapılandırması. Bu değerler GİZLİ DEĞİLDİR (genel test ortamı URL'leri).
/// Kendi partner backend'inle denemek için `partnerBackendURL`'i değiştir.
enum DemoConfig {
    /// Partner backend proxy base URL'si (X-API-Key ile VerifyBlind relay'e proxy yapar).
    static let partnerBackendURL = "https://test.verifyblind.com/api"

    /// Partner backend üzerindeki işlem-başlatma uç noktası (base'e eklenir → .../api/generate).
    static let generateEndpoint = "generate"

    /// VerifyBlind relay (sonuç polling için: GET /api/pop/result/{nonce}).
    static let verifyblindApiURL = "https://api.verifyblind.com"

    /// VerifyBlind Universal Link base (Android VERIFYBLIND_APP_LINK_BASE ile aynı).
    static let appLinkBase = "https://app.verifyblind.com/request"

    /// VerifyBlind'ın doğrulama bitince bu uygulamayı öne getirmek için açacağı geri-dönüş deeplink'i.
    /// Şema (verifyblinddemo) Info.plist'te kayıtlı ve partner-portal'daki "app return scheme" ile eşleşmeli.
    /// example-mobile-android ile AYNI şema (aynı test partner'ı → tek portal kaydı ikisini de doğrular).
    static let returnUrl = "verifyblinddemo://callback"
}
