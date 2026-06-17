# VerifyBlind Demo (iOS)

VerifyBlind iOS SDK'sını (`sdk-ios`) tüketen örnek uygulama — `example-mobile-android`'in iOS
karşılığı. SwiftUI, iOS 16+. **Cihaz attestation'ı (App Attest) YOKTUR** (bilinçli: VerifyBlind'in
zero-knowledge güvenliğinin parçası değil).

- Bundle ID: `com.verifyblind.example` (Android örnekle aynı)
- Mağaza/görünen ad: **VerifyBlind Demo**
- SDK: `https://github.com/VerifyBlind/sdk-ios` (SwiftPM, `from: 2.1.0`)
- Proje XcodeGen ile üretilir (`project.yml`); imzasız derleme + TestFlight CI'da yapılır.

## Akış
1. "VerifyBlind ile Doğrula" → SDK ephemeral RSA keypair üretir, partner backend'den `nonce` alır.
2. SDK VerifyBlind uygulamasını Universal Link ile açar (`app.verifyblind.com/request?...`).
3. Kullanıcı doğrulamayı VerifyBlind'de tamamlar; bu demo'ya geri dönünce sonuç poll edilir
   (`scenePhase .active`), şifreli yanıt lokalde çözülür.

## Mac'in yok → her şey GitHub'da derlenir
- **Her push'ta** `build` job'u (secret'sız) uygulamanın derlendiğini iOS Simulator'da doğrular.
- **`testflight` job'u** secret'lar eklenince TestFlight'a yükler; eklenmeden önce sessizce atlanır.

---

## SENİN YAPMAN GEREKENLER (TestFlight için, tek seferlik)

Aşağıdakiler olmadan da `build` job'u çalışır (derleme doğrulanır). TestFlight'a build atmak ve
iPhone'unda denemek için gerekenler:

### 1) App ID kaydet — Apple Developer
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**
2. **App IDs** → **App** → Continue
3. Description: `VerifyBlind Demo`, Bundle ID: **Explicit** → `com.verifyblind.example`
4. **Capabilities: hiçbirini işaretleme** (push/App Attest/associated domains GEREKMEZ)
5. Continue → Register

### 2) App Store Connect'te uygulama kaydı aç
1. https://appstoreconnect.apple.com → **Apps** → **+** → **New App**
2. Platform: iOS · Name: `VerifyBlind Demo` (mağaza adı global benzersiz olmalı; doluysa örn.
   `VerifyBlind Demo TR`) · Primary Language: Turkish · Bundle ID: `com.verifyblind.example` · SKU: `verifyblind-demo`
3. Oluştur. **App'in "Apple ID" numarasını not al** (App Information sayfasında, ~10 haneli) → bu `APP_STORE_APP_ID`.

### 3) GitHub secret'larını ekle
`https://github.com/VerifyBlind/example-mobile-ios` → **Settings → Secrets and variables → Actions → New repository secret**.
Aşağıdakilerden **yalnızca `APP_STORE_APP_ID` yeni**; gerisi ana iOS uygulamasının (VerifyBlind-iOS)
secret'larıyla **birebir aynı değerlerdir** (aynı App Store Connect API anahtarı + dağıtım sertifikası):

| Secret | Değer |
|--------|-------|
| `APP_STORE_APP_ID` | **(2. adımdaki YENİ app'in Apple ID'si)** |
| `APP_STORE_CONNECT_ISSUER_ID` | ana app ile aynı |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | ana app ile aynı |
| `APP_STORE_CONNECT_PRIVATE_KEY` | ana app ile aynı (.p8 içeriği) |
| `CERTIFICATE_PRIVATE_KEY` | ana app ile aynı |
| `APPLE_TEAM_ID` | ana app ile aynı (`7DYSGPXTNK`) |

> Sertifika/profil otomatik: CI `app-store-connect fetch-signing-files --create` ile App ID'yi
> (yoksa) ve provisioning profile'ı kendisi oluşturur. 1. adımı atlasan bile `--create` deneyebilir,
> ama App Store Connect app kaydı (2. adım) ve `APP_STORE_APP_ID` zorunludur.

### 4) Kendini internal tester yap
App Store Connect → uygulaman → **TestFlight** → Internal Testing → kendi Apple ID'ni ekle.
Upload sonrası iPhone'da **TestFlight** uygulamasından build gelir.

---

## Demo'nun gerçekten çalışması için (altyapı — örnek uygulamadan bağımsız)
SDK, VerifyBlind uygulamasını **Universal Link** ile açar. Bunun cihazda VerifyBlind app'ini
açabilmesi için:
- `app.verifyblind.com/.well-known/apple-app-site-association` yayında olmalı (`<TeamID>.app.verifyblind.ios` + `/request` path),
- VerifyBlind iOS app'i `applinks:app.verifyblind.com` Associated Domains ile bu linki karşılamalı.

Bunlar yoksa `startAuthentication` Safari'ye düşer ve akış cihazda tamamlanamaz.

## Yapılandırma
Test ortamı URL'leri `Sources/DemoConfig.swift` içinde (gizli değil). Kendi partner backend'inle
denemek için `partnerBackendURL`'i değiştir.
