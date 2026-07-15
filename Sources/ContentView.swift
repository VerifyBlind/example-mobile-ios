import SwiftUI

/// example-mobile-android `activity_main.xml` tasarımının birebir SwiftUI karşılığı.
struct ContentView: View {
    @ObservedObject var vm: DemoViewModel

    var body: some View {
        ZStack {
            Theme.bgDark.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    parametersCard.padding(.top, 0)
                    verifyButton
                    resultCard
                    logCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }

            if vm.isBusy { overlay }
            if let toast = vm.toastText { toastView(toast) }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Header (sola yaslı)
    private var header: some View {
        HStack(spacing: 14) {
            Image("Logo")
                .resizable()
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("Verify").foregroundColor(Theme.textPrimary)
                    Text("Blind").foregroundColor(Theme.blue400)
                }
                .font(.system(size: 27, weight: .bold))
                Text(L("subtitle_test_app"))
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 30)
    }

    // MARK: Doğrulama Parametreleri
    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.textSecondary)
                Text(L("section_parameters"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.bottom, 18)

            paramRow(
                icon: AnyView(
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.accentCyan)
                        .frame(width: 30, height: 30)
                ),
                title: L("param_userid_title"),
                desc: L("param_userid_desc"),
                isOn: $vm.requestUserId
            )

            Rectangle().fill(Theme.cardStroke).frame(height: 1).padding(.vertical, 14)

            paramRow(
                icon: AnyView(ageBadge),
                title: L("param_age_title"),
                desc: L("param_age_desc"),
                isOn: $vm.ageOver18
            )
        }
        .card()
    }

    private func paramRow(icon: AnyView, title: String, desc: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.textPrimary)
                Text(desc).font(.system(size: 12)).foregroundColor(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn).labelsHidden().tint(Theme.primary)
        }
    }

    private var ageBadge: some View {
        Text("18+")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.blue400)
            .frame(width: 34, height: 34)
            .background(Theme.primary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Doğrula butonu
    private var verifyButton: some View {
        Button(action: { vm.startVerification() }) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill").font(.system(size: 20))
                Text(L("btn_verify")).font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundColor(Theme.onPrimary)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(vm.isBusy)
        .opacity(vm.isBusy ? 0.6 : 1)
        .padding(.top, 20)
    }

    // MARK: Doğrulama Sonucu
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("section_result"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                if let s = vm.statusText {
                    Text(s)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(vm.statusIsSuccess ? Theme.successText : Theme.errorText)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(vm.statusIsSuccess ? Theme.successBg : Theme.errorBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.bottom, 12)

            ZStack(alignment: .topTrailing) {
                Text(vm.resultText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .padding(.trailing, 28)
                    .background(Theme.codeBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button(action: { vm.copyResult() }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                }
            }
        }
        .card()
        .padding(.top, 20)
    }

    // MARK: Geliştirici Log
    private var logCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("section_log"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { vm.clearLog() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash").font(.system(size: 14))
                        Text(L("btn_clear")).font(.system(size: 13))
                    }
                    .foregroundColor(Theme.blue400)
                }
                Button(action: { vm.copyLog() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc").font(.system(size: 14))
                        Text(L("btn_copy")).font(.system(size: 13))
                    }
                    .foregroundColor(Theme.blue400)
                }
                .padding(.leading, 8)
            }
            .padding(.bottom, 12)

            ScrollView {
                Text(vm.logText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 150, maxHeight: 240)
            .padding(14)
            .background(Theme.codeBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .card()
        .padding(.top, 20)
    }

    // MARK: Overlay
    private var overlay: some View {
        ZStack {
            Theme.bgDark.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView().scaleEffect(1.6).tint(Theme.primary)
                Text(L(vm.overlayKey))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                // Beklemeyi kesip sıfırdan istek gönderebilmek için (VerifyBlind'da vazgeçildi / akış yarıda kaldı).
                Button(action: { vm.cancelAndReset() }) {
                    Text(L("overlay_cancel"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.blue400)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 36).padding(.vertical, 30)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: Toast
    private func toastView(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
                .padding(.bottom, 44)
        }
    }
}

// MARK: - Kart stili (surface + stroke + radius, Android MaterialCardView paritesi)
private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke, lineWidth: 1))
    }
}
private extension View {
    func card() -> some View { modifier(CardModifier()) }
}
