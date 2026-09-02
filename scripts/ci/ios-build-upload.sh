#!/usr/bin/env bash
# example-mobile-ios — imzalı build + TestFlight upload (GitHub Actions, macOS).
# Tüm secret'lar workflow tarafından env: ile enjekte edilir.
# VerifyBlind.iOS/scripts/ci/ios-build-upload.sh'in sade (Sentry/Dropbox/attestation'sız) sürümü.
set -euo pipefail

XCODE_SCHEME="VerifyBlindDemo"
XCODE_PROJECT="VerifyBlindDemo.xcodeproj"
BUNDLE_ID="${BUNDLE_ID:-com.verifyblind.example}"

# ── 1. Build numarası: TestFlight'taki son +1 ────────────────────────────────
echo "=== Build number ==="
LATEST=$(app-store-connect get-latest-testflight-build-number "$APP_STORE_APP_ID" \
  --issuer-id "$APP_STORE_CONNECT_ISSUER_ID" \
  --key-id "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --private-key "@env:APP_STORE_CONNECT_PRIVATE_KEY" 2>/dev/null || echo 0)
BUILD_NUMBER=$(( ${LATEST:-0} + 1 ))
echo "TestFlight latest=${LATEST:-0} → yeni build=$BUILD_NUMBER"

# ── 2. xcconfig (APPLE_TEAM_ID + build number) ───────────────────────────────
echo "=== xcconfig ==="
mkdir -p Config
cat > Config/Release.xcconfig <<EOF
APPLE_TEAM_ID = ${APPLE_TEAM_ID}
IOS_BUNDLE_ID = ${BUNDLE_ID}
BUILD_NUMBER = ${BUILD_NUMBER}
EOF

# ── 3. Xcode projesini üret ──────────────────────────────────────────────────
echo "=== XcodeGen ==="
xcodegen generate

# ── 4. SPM bağımlılıklarını çöz ──────────────────────────────────────────────
echo "=== Resolve SPM ==="
xcodebuild -resolvePackageDependencies -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME"

# ── 5. Keychain + dağıtım sertifikası + provisioning profile ─────────────────
echo "=== Signing ==="
keychain initialize
app-store-connect fetch-signing-files "$BUNDLE_ID" \
  --type IOS_APP_STORE \
  --issuer-id "$APP_STORE_CONNECT_ISSUER_ID" \
  --key-id "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --private-key "@env:APP_STORE_CONNECT_PRIVATE_KEY" \
  --certificate-key "@env:CERTIFICATE_PRIVATE_KEY" \
  --create
keychain add-certificates
xcode-project use-profiles

# ── 6. IPA derle ─────────────────────────────────────────────────────────────
echo "=== Build IPA ==="
xcode-project build-ipa --project "$XCODE_PROJECT" --scheme "$XCODE_SCHEME" --config Release

# ── 7. TestFlight'a yükle ────────────────────────────────────────────────────
echo "=== TestFlight upload ==="
# Apple altyapısı upload SONRASI adımlarda zaman zaman geçici hata verip exit≠0 yapar; IPA
# aslında yüklenmiş olur ("UPLOAD SUCCEEDED"). O durumda build YEŞİL sayılır (ana app ile aynı gotcha).
PUBLISH_LOG="$(mktemp)"
set +e
app-store-connect publish \
  --path "build/ios/ipa/*.ipa" \
  --testflight \
  --key-id "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --issuer-id "$APP_STORE_CONNECT_ISSUER_ID" \
  --private-key "@env:APP_STORE_CONNECT_PRIVATE_KEY" \
  --expire-build-submitted-for-review 2>&1 | tee "$PUBLISH_LOG"
PUBLISH_RC=${PIPESTATUS[0]}
set -e
if [ "$PUBLISH_RC" -ne 0 ]; then
  if grep -q "UPLOAD SUCCEEDED" "$PUBLISH_LOG"; then
    echo "⚠️  publish exit=$PUBLISH_RC ama IPA yüklendi (UPLOAD SUCCEEDED) — Apple geçici post-adım hatası, YEŞİL."
  else
    echo "❌ publish başarısız (UPLOAD SUCCEEDED yok)."
    exit "$PUBLISH_RC"
  fi
fi
