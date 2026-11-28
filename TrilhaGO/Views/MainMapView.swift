import SwiftUI

struct MainMapView: View {
    @ObservedObject var store: TrilhaGameStore
    @State private var showSportDrawer = false

    var body: some View {
        ZStack {
            Mapbox3DMapView(store: store) { tappedStore in
                store.chestModalStore = tappedStore
            }

            VStack(spacing: 10) {
                // HUD Superior
                topHudBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Alerta Anti-Cheat
                if store.isMockLocationBlocked || store.isSpeedBlocked {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                        Text(store.isMockLocationBlocked
                             ? "Fake GPS / Mock Location bloqueado."
                             : "Velocidade acima do limite permitido.")
                            .font(TrilhaFont.body(12.5, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.92))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Vitrine Animada de Proximidade (<= 40m)
                if let showcase = store.activeShowcaseStore {
                    ProximityShowcaseCard(
                        storeLocation: showcase,
                        distanceMeters: store.activeShowcaseDistance,
                        onOpenChest: { store.chestModalStore = showcase },
                        onDismiss: { store.dismissShowcase() }
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Painel ao Vivo do Modo Esporte
                if store.isWorkoutActive {
                    LiveSportPanelView(store: store)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showSportDrawer {
                    SportSelectorCard(store: store) { mode in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showSportDrawer = false
                            store.startWorkout(mode: mode)
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Barra Inferior com ícones flat
                bottomDockBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
        .sheet(item: $store.chestModalStore) { modalStore in
            ChestOpeningModalView(store: store, targetStore: modalStore)
        }
        .sheet(item: $store.latestWorkoutSummary) { summary in
            WorkoutSummaryView(summary: summary)
        }
        .sheet(isPresented: $store.showBackpack) {
            BackpackView(store: store)
        }
        .sheet(isPresented: $store.showRanking) {
            RankingView(store: store)
        }
        .sheet(isPresented: $store.showSettings) {
            SettingsView(store: store)
        }
        .sheet(isPresented: $store.showMerchantPanel) {
            MerchantPanelView(store: store)
        }
    }

    private var topHudBar: some View {
        HStack(spacing: 10) {
            // Chaves
            HStack(spacing: 6) {
                Image("icon_key_flat")
                    .resizable().scaledToFit().frame(width: 22, height: 22)
                Text("\(store.keysCount)")
                    .font(TrilhaFont.metric(16))
                    .foregroundStyle(TrilhaColors.darkText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TrilhaColors.pureWhite)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)

            // Territórios / XP
            HStack(spacing: 6) {
                Image("obj_territory_shield")
                    .resizable().scaledToFit().frame(width: 22, height: 22)
                Text("\(store.xp) XP")
                    .font(TrilhaFont.metric(14))
                    .foregroundStyle(TrilhaColors.darkText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TrilhaColors.pureWhite)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)

            Spacer()

            // Botão rápido de passo simulado (para testar 500m / vitrine no simulador)
            Button {
                store.simulateStep(meters: 125)
            } label: {
                HStack(spacing: 4) {
                    Image("icon_location")
                        .resizable().scaledToFit().frame(width: 18, height: 18)
                    Text("+125m")
                        .font(TrilhaFont.metric(12))
                        .foregroundStyle(TrilhaColors.darkText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(TrilhaColors.pureWhite)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
            }
        }
    }

    private var bottomDockBar: some View {
        HStack(spacing: 10) {
            dockButton(icon: "icon_backpack", label: "Mochila") { store.showBackpack = true }
            dockButton(icon: "icon_ranking", label: "Ranking") { store.showRanking = true }

            // Botão central Esporte
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    if store.isWorkoutActive {
                        store.finishWorkout()
                    } else {
                        showSportDrawer.toggle()
                    }
                }
            } label: {
                VStack(spacing: 3) {
                    Image(store.isWorkoutActive ? store.selectedSportMode.iconName : "icon_run")
                        .resizable().scaledToFit().frame(width: 28, height: 28)
                    Text(store.isWorkoutActive ? "PARAR" : "ESPORTE")
                        .font(TrilhaFont.title(10))
                        .foregroundStyle(TrilhaColors.pureWhite)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(store.isWorkoutActive ? Color.red : TrilhaColors.emerald)
                .clipShape(Capsule())
                .shadow(color: TrilhaColors.emerald.opacity(0.28), radius: 8, y: 4)
            }

            dockButton(icon: "icon_store", label: "Lojista") { store.showMerchantPanel = true }
            dockButton(icon: "icon_settings", label: "Ajustes") { store.showSettings = true }
        }
        .padding(8)
        .background(TrilhaColors.pureWhite.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
    }

    private func dockButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(icon)
                    .resizable().scaledToFit().frame(width: 24, height: 24)
                Text(label)
                    .font(TrilhaFont.body(10, weight: .semibold))
                    .foregroundStyle(TrilhaColors.darkText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

private struct ProximityShowcaseCard: View {
    let storeLocation: StoreLocation
    let distanceMeters: Double
    let onOpenChest: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(storeLocation.hasPremiumChest && storeLocation.premiumAvailableToday ? "obj_chest_premium" : "obj_chest_common")
                .resizable().scaledToFit().frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(storeLocation.name)
                        .font(TrilhaFont.title(14))
                        .foregroundStyle(TrilhaColors.darkText)
                    if storeLocation.hasPremiumChest && storeLocation.premiumAvailableToday {
                        Text("PREMIUM")
                            .font(TrilhaFont.title(9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TrilhaColors.goldPremium)
                            .foregroundStyle(TrilhaColors.darkText)
                            .clipShape(Capsule())
                    }
                }
                Text("\(Int(distanceMeters)) m • \(storeLocation.promoTitle)")
                    .font(TrilhaFont.body(12))
                    .foregroundStyle(TrilhaColors.mutedText)
            }

            Spacer()

            Button("ABRIR") { onOpenChest() }
                .font(TrilhaFont.title(11))
                .foregroundStyle(TrilhaColors.pureWhite)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(TrilhaColors.emerald)
                .clipShape(Capsule())

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(TrilhaColors.mutedText)
            }
        }
        .padding(12)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 12, y: 5)
    }
}

private struct SportSelectorCard: View {
    @ObservedObject var store: TrilhaGameStore
    let onStart: (SportMode) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("MODO ESPORTE (1,5x CHAVES/XP)")
                    .font(TrilhaFont.title(13))
                    .foregroundStyle(TrilhaColors.darkText)
                Spacer()
            }
            HStack(spacing: 10) {
                ForEach(SportMode.allCases) { mode in
                    Button {
                        onStart(mode)
                    } label: {
                        VStack(spacing: 6) {
                            Image(mode.iconName)
                                .resizable().scaledToFit().frame(width: 34, height: 34)
                            Text(mode.title)
                                .font(TrilhaFont.body(12, weight: .semibold))
                                .foregroundStyle(TrilhaColors.darkText)
                            Text("até \(Int(mode.maxSpeedKmh)) km/h")
                                .font(TrilhaFont.body(10))
                                .foregroundStyle(TrilhaColors.mutedText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TrilhaColors.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TrilhaColors.border, lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
    }
}

private struct LiveSportPanelView: View {
    @ObservedObject var store: TrilhaGameStore

    private var formattedTime: String {
        let m = store.workoutSeconds / 60
        let s = store.workoutSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var kmText: String {
        String(format: "%.2f", store.workoutDistanceMeters / 1000.0)
    }

    private var kcal: Int {
        Int((store.workoutDistanceMeters / 1000.0) * store.selectedSportMode.kcalPerKm)
    }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Image("icon_timer").resizable().scaledToFit().frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 0) {
                    Text(formattedTime).font(TrilhaFont.metric(18)).foregroundStyle(TrilhaColors.darkText)
                    Text("MINUTOS").font(TrilhaFont.body(9)).foregroundStyle(TrilhaColors.mutedText)
                }
            }
            Spacer()
            VStack(alignment: .center, spacing: 0) {
                Text("\(kmText) km").font(TrilhaFont.metric(18)).foregroundStyle(TrilhaColors.emerald)
                Text("DISTÂNCIA").font(TrilhaFont.body(9)).foregroundStyle(TrilhaColors.mutedText)
            }
            Spacer()
            HStack(spacing: 6) {
                Image("icon_calories").resizable().scaledToFit().frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(kcal)").font(TrilhaFont.metric(18)).foregroundStyle(TrilhaColors.darkText)
                    Text("KCAL").font(TrilhaFont.body(9)).foregroundStyle(TrilhaColors.mutedText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
    }
}
