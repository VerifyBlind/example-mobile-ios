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
}
