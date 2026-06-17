import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: DemoViewModel

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    parametersCard
                    verifyButton
                    if let status = vm.statusText { statusPill(status) }
                    resultCard
                    logCard
                }
                .padding()
            }
            if vm.isBusy { overlay }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("VerifyBlind").font(.largeTitle).bold()
            Text("Demo").font(.title3).foregroundColor(.secondary)
        }
    }

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doğrulama Parametreleri").font(.headline)
            Toggle("Yaş Doğrulama (18+)", isOn: $vm.ageOver18)
            Toggle("Kullanıcı Kimliği (user_id)", isOn: $vm.requestUserId)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var verifyButton: some View {
        Button(action: { vm.startVerification() }) {
            Text("VerifyBlind ile Doğrula")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(vm.isBusy)
        .opacity(vm.isBusy ? 0.6 : 1)
    }

    private func statusPill(_ text: String) -> some View {
        Text(text)
            .font(.subheadline).fontWeight(.semibold)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background((vm.isSuccess ? Color.green : Color.red).opacity(0.15))
            .foregroundColor(vm.isSuccess ? .green : .red)
            .cornerRadius(8)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doğrulama Sonucu").font(.headline)
            Text(vm.resultText)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Geliştirici Log").font(.headline)
                Spacer()
                Button("Temizle") { vm.clearLog() }.font(.caption)
            }
            ScrollView {
                Text(vm.logText.isEmpty ? "> Hazır.\n" : vm.logText)
                    .font(.system(.caption2, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            .padding(8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }

    private var overlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("Lütfen bekleyin…\nVerifyBlind ile doğrulama")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}
