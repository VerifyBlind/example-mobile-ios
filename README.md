# VerifyBlind Demo (iOS)

**[🇹🇷 Türkçe](#türkçe) · [🇬🇧 English](#english)**

---

## Türkçe

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

---

## English

An example app that consumes the VerifyBlind iOS SDK (`sdk-ios`) — the iOS counterpart of
`example-mobile-android`. SwiftUI, iOS 16+. **No device attestation (App Attest)** (intentional: it is
not part of VerifyBlind's zero-knowledge security).

- Bundle ID: `com.verifyblind.example` (same as the Android example)
- Store / display name: **VerifyBlind Demo**
- SDK: `https://github.com/VerifyBlind/sdk-ios` (SwiftPM, `from: 2.1.0`)
- The project is generated with XcodeGen (`project.yml`); an unsigned build + TestFlight happen in CI.

### Flow
1. "Verify with VerifyBlind" → the SDK generates an ephemeral RSA keypair and gets a `nonce` from the partner backend.
2. The SDK opens the VerifyBlind app via a Universal Link (`app.verifyblind.com/request?...`).
3. The user completes verification in VerifyBlind; back in this demo the result is polled
   (`scenePhase .active`) and the encrypted response is decrypted locally.

### No Mac? Everything builds on GitHub
- **On every push** the `build` job (no secrets) verifies the app compiles on the iOS Simulator.
- **The `testflight` job** uploads to TestFlight once secrets are added; before that it's silently skipped.

---

### WHAT YOU NEED TO DO (for TestFlight, one-time)

The `build` job runs without the following (compilation is verified). To push a build to TestFlight and
try it on your iPhone you need:

#### 1) Register an App ID — Apple Developer
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**
2. **App IDs** → **App** → Continue
3. Description: `VerifyBlind Demo`, Bundle ID: **Explicit** → `com.verifyblind.example`
4. **Capabilities: check none** (push/App Attest/associated domains NOT required)
5. Continue → Register

#### 2) Create the app in App Store Connect
1. https://appstoreconnect.apple.com → **Apps** → **+** → **New App**
2. Platform: iOS · Name: `VerifyBlind Demo` (the store name must be globally unique; if taken, e.g.
   `VerifyBlind Demo TR`) · Primary Language: Turkish · Bundle ID: `com.verifyblind.example` · SKU: `verifyblind-demo`
3. Create it. **Note the app's "Apple ID" number** (on the App Information page, ~10 digits) → this is `APP_STORE_APP_ID`.

#### 3) Add the GitHub secrets
`https://github.com/VerifyBlind/example-mobile-ios` → **Settings → Secrets and variables → Actions → New repository secret**.
Of the following **only `APP_STORE_APP_ID` is new**; the rest are **exactly the same values** as the main
iOS app's (VerifyBlind-iOS) secrets (same App Store Connect API key + distribution certificate):

| Secret | Value |
|--------|-------|
| `APP_STORE_APP_ID` | **(the Apple ID of the NEW app from step 2)** |
| `APP_STORE_CONNECT_ISSUER_ID` | same as the main app |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | same as the main app |
| `APP_STORE_CONNECT_PRIVATE_KEY` | same as the main app (.p8 contents) |
| `CERTIFICATE_PRIVATE_KEY` | same as the main app |
| `APPLE_TEAM_ID` | same as the main app |

> Certificate/profile are automatic: CI creates the App ID (if missing) and the provisioning profile
> itself via `app-store-connect fetch-signing-files --create`. Even if you skip step 1 it may try
> `--create`, but the App Store Connect app record (step 2) and `APP_STORE_APP_ID` are mandatory.

#### 4) Make yourself an internal tester
App Store Connect → your app → **TestFlight** → Internal Testing → add your own Apple ID. After upload
the build arrives in the **TestFlight** app on your iPhone.

---

### For the demo to actually work (infrastructure — independent of the example app)
The SDK opens the VerifyBlind app via a **Universal Link**. For that to open VerifyBlind on the device:
- `app.verifyblind.com/.well-known/apple-app-site-association` must be live (`<TeamID>.app.verifyblind.ios` + the `/request` path),
- the VerifyBlind iOS app must claim this link via the `applinks:app.verifyblind.com` Associated Domains.

Without these, `startAuthentication` falls back to Safari and the flow cannot complete on the device.

### Configuration
Test environment URLs live in `Sources/DemoConfig.swift` (not secret). Change `partnerBackendURL` to try
it with your own partner backend.
