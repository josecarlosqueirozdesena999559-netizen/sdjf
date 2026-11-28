import SwiftUI

struct ChestOpeningModalView: View {
    @ObservedObject var store: TrilhaGameStore
    let targetStore: StoreLocation
    @Environment(\.dismiss) private var dismiss

    @State private var dwellProgress: Double = 0
    @State private var challengeTaps: Int = 0
    @State private var isClaiming = false
    @State private var result: ChestClaimResponse?
    @State private var dwellTimer: Timer?

    private var distanceMeters: Double {
        store.distanceTo(store: targetStore)
    }

    private var isWithinRange: Bool {
        distanceMeters <= 40.0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(targetStore.hasPremiumChest && targetStore.premiumAvailableToday ? "obj_chest_premium" : "obj_chest_common")
                    .resizable().scaledToFit().frame(width: 96, height: 96)
                    .padding(.top, 10)

                Text(targetStore.name)
                    .font(TrilhaFont.title(22))
                    .foregroundStyle(TrilhaColors.darkText)

                Text(targetStore.hasPremiumChest && targetStore.premiumAvailableToday
                     ? "Baú Dourado 1/dia • Janela \(targetStore.premiumWindowLabel)"
                     : "Baú Comum (70%) e Raro (25%)")
                    .font(TrilhaFont.body(13))
                    .foregroundStyle(TrilhaColors.mutedText)

                if let res = result {
                    resultCard(res)
                } else {
                    challengeCard
                }

                Spacer()
            }
            .padding(20)
            .background(TrilhaColors.surfaceGray.ignoresSafeArea())
            .navigationTitle("Abrir Baú")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .onAppear {
            startDwellTimer()
        }
        .onDisappear {
            dwellTimer?.invalidate()
        }
    }

    private var challengeCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Distância até a loja:")
                    .font(TrilhaFont.body(13))
                    .foregroundStyle(TrilhaColors.mutedText)
                Spacer()
                Text("\(Int(distanceMeters)) m")
                    .font(TrilhaFont.metric(16))
                    .foregroundStyle(isWithinRange ? TrilhaColors.emerald : Color.red)
            }

            if !isWithinRange {
                Text("Aproxime-se a até 40 m da loja para destravar este baú.")
                    .font(TrilhaFont.body(13))
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Permanência na área (~15s): \(Int(dwellProgress * 100))%")
                        .font(TrilhaFont.body(12, weight: .semibold))
                        .foregroundStyle(TrilhaColors.darkText)
                    ProgressView(value: dwellProgress)
                        .tint(TrilhaColors.emerald)
                }

                Divider()

                Text("Mini-desafio rápido: toque 3x no escudo!")
                    .font(TrilhaFont.body(13, weight: .semibold))
                    .foregroundStyle(TrilhaColors.darkText)

                Button {
                    if challengeTaps < 3 { challengeTaps += 1 }
                } label: {
                    HStack(spacing: 10) {
                        Image("obj_territory_shield").resizable().scaledToFit().frame(width: 34, height: 34)
                        Text("\(challengeTaps) / 3 TOQUES")
                            .font(TrilhaFont.title(14))
                            .foregroundStyle(TrilhaColors.darkText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(TrilhaColors.surfaceGray)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(TrilhaColors.emerald, lineWidth: 2))
                }
            }

            EmeraldPillButton(
                title: isClaiming ? "ABRINDO..." : "USAR 1 CHAVE E ABRIR",
                isDisabled: !isWithinRange || dwellProgress < 1.0 || challengeTaps < 3 || store.keysCount < 1 || isClaiming
            ) {
                Task {
                    isClaiming = true
                    result = await store.claimChest(for: targetStore)
                    isClaiming = false
                }
            }
        }
        .padding(18)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func resultCard(_ res: ChestClaimResponse) -> some View {
        VStack(spacing: 14) {
            if res.ok {
                let rarity = res.rarity ?? .common
                Image(rarity.assetName)
                    .resizable().scaledToFit().frame(width: 72, height: 72)
                Text(rarity.title.uppercased())
                    .font(TrilhaFont.title(16))
                    .foregroundStyle(rarity == .premium ? TrilhaColors.goldPremium : TrilhaColors.emerald)
                Text(res.rewardTitle ?? "Prêmio conquistado!")
                    .font(TrilhaFont.title(18))
                    .foregroundStyle(TrilhaColors.darkText)
                    .multilineTextAlignment(.center)
                if let token = res.qrToken {
                    Text("QR Code salvo na Mochila: \(token)")
                        .font(TrilhaFont.body(12))
                        .foregroundStyle(TrilhaColors.mutedText)
                }
                EmeraldPillButton(title: "VER NA MOCHILA") {
                    dismiss()
                    store.showBackpack = true
                }
            } else {
                Text(res.error ?? "Não foi possível abrir o baú.")
                    .font(TrilhaFont.body(14))
                    .foregroundStyle(Color.red)
            }
        }
        .padding(20)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func startDwellTimer() {
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task { @MainActor in
                guard isWithinRange else { return }
                if dwellProgress < 1.0 {
                    dwellProgress = min(1.0, dwellProgress + 0.08) // ~3.8s rápido para UX fluida (15s cap no backend)
                }
            }
        }
    }
}
