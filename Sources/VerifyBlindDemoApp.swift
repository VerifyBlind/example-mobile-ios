import SwiftUI

/// VerifyBlind Demo — SDK tüketici örnek uygulaması (example-mobile-android iOS karşılığı).
///
/// Akış: "VerifyBlind ile Doğrula" → SDK ephemeral keypair üretir, partner backend'den nonce
/// alır, VerifyBlind uygulamasını Universal Link ile açar. Kullanıcı doğrulamayı tamamlayıp
/// geri döndüğünde (scenePhase .active) sonuç poll edilir.
@main
struct VerifyBlindDemoApp: App {

    @StateObject private var vm = DemoViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
                // VerifyBlind geri döndü (verifyblinddemo://callback?nonce=..&status=..) → uygulama öne
                // geldi; poll'u sürdür (Android handleIncomingIntent paritesi). scenePhase .active da
                // tetikler; bu ek güvence. resumePolling idempotent (aktif nonce yoksa no-op).
                .onOpenURL { _ in vm.resumePolling() }
        }
        // Poll YALNIZCA ön planda (Android örneğindeki onResume/onPause mantığı).
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:     vm.resumePolling()
            case .background: vm.cancelPolling()
            default:          break
            }
        }
    }
}
