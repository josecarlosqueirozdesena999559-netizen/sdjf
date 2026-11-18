import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: DiscoverViewModel
    @State private var likeBounce: Bool = false
    @State private var showHeartBurst: Bool = false
    @State private var heartBurstOffset: CGFloat = 0
    @State private var heartBurstOpacity: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.primaryRed)
                } else if viewModel.candidates.isEmpty {
                    emptyCandidatesView
                } else {
                    ForEach(Array(viewModel.candidates.prefix(2).enumerated().reversed()), id: \.element.id) { index, profile in
                        SwipeableProfileCard(
                            profile: profile,
                            isTopCard: index == 0,
                            programmaticSwipe: viewModel.programmaticSwipe,
                            onDecision: { decision in
                                viewModel.programmaticSwipe = nil
                                viewModel.handleDecision(decision, for: profile, appState: appState)
                            },
                            onInfoTap: {
                                viewModel.selectedProfileForDetail = profile
                            }
                        )
                        .scaleEffect(index == 0 ? 1.0 : 0.96)
                        .offset(y: index == 0 ? 0 : 10)
                        .allowsHitTesting(index == 0)
                    }
                }

                if showHeartBurst {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 76, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.4), radius: 16, x: 0, y: 6)
                        .offset(y: heartBurstOffset)
                        .opacity(heartBurstOpacity)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)

            interactionButtons
                .padding(.bottom, 6)
        }
        .sheet(item: $viewModel.selectedProfileForDetail) { profile in
            ProfileDetailSheet(profile: profile)
        }
    }

    private var interactionButtons: some View {
        HStack(spacing: 24) {
            Button {
                viewModel.actOnTopCard(.reject, appState: appState)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color(hex: "E9ECF2").opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                    Image(systemName: "xmark")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color(hex: "43464E"))
                }
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.candidates.isEmpty)
            .accessibilityLabel("Rejeitar")

            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                    likeBounce = true
                }
                showHeartBurst = true
                heartBurstOffset = 20
                heartBurstOpacity = 1.0
                withAnimation(.easeOut(duration: 0.5)) {
                    heartBurstOffset = -90
                    heartBurstOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    likeBounce = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
                    showHeartBurst = false
                }
                viewModel.actOnTopCard(.like, appState: appState)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.white)
                }
                .frame(width: 72, height: 72)
                .shadow(color: AppTheme.Colors.primaryRed.opacity(0.36), radius: 14, x: 0, y: 7)
                .scaleEffect(likeBounce ? 1.12 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.candidates.isEmpty)
            .accessibilityLabel("Curtir")

            Button {
                viewModel.actOnTopCard(.highlight, appState: appState)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color(hex: "E9ECF2").opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                    Image(systemName: "star.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(hex: "43464E"))
                }
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.candidates.isEmpty)
            .accessibilityLabel("Destacar")
        }
        .opacity(viewModel.candidates.isEmpty ? 0.45 : 1.0)
    }

    private var emptyCandidatesView: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppTheme.Colors.textGray)

            Text("Não há mais perfis por enquanto")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.darkGray)

            Text("Ajuste os filtros ou recarregue para ver novas pessoas.")
                .font(AppTheme.Typography.subheadline())
                .foregroundStyle(AppTheme.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task {
                    await viewModel.loadCandidates()
                }
            } label: {
                Text("Recarregar perfis")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primaryRed, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(cornerRadius: AppTheme.Radius.card)
    }
}

struct ProfileDetailSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PhotoGalleryView(photos: profile.photos, enableSwipeGesture: true)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("\(profile.fullName), \(profile.age)")
                                .font(AppTheme.Typography.largeTitle())
                                .foregroundStyle(AppTheme.Colors.darkGray)

                            if profile.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 13))
                            Text("A cerca de \(profile.distanceKm) km • \(profile.city)")
                                .font(AppTheme.Typography.subheadline())
                        }
                        .foregroundStyle(AppTheme.Colors.textGray)

                        if !profile.bio.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sobre")
                                    .font(AppTheme.Typography.headline())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                                Text(profile.bio)
                                    .font(AppTheme.Typography.body())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                            }
                            .padding(.top, 4)
                        }

                        if !profile.interests.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Interesses")
                                    .font(AppTheme.Typography.headline())
                                    .foregroundStyle(AppTheme.Colors.darkGray)

                                FlowLayout(spacing: 8) {
                                    ForEach(profile.interests) { interest in
                                        InterestChip(interest: interest, isSelected: true)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(profile.firstName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }
}

struct FiltersSheet: View {
    @State private var draftFilter: DiscoveryFilter
    let onApply: (DiscoveryFilter) -> Void
    @Environment(\.dismiss) private var dismiss

    init(currentFilter: DiscoveryFilter, onApply: @escaping (DiscoveryFilter) -> Void) {
        _draftFilter = State(initialValue: currentFilter)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Distância máxima") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Até \(Int(draftFilter.maxDistanceKm)) km")
                                .font(AppTheme.Typography.headline())
                            Spacer()
                        }
                        Slider(value: $draftFilter.maxDistanceKm, in: 2...100, step: 1)
                            .tint(AppTheme.Colors.primaryRed)
                    }
                }

                Section("Faixa etária") {
                    Stepper("Idade mínima: \(draftFilter.minAge)", value: $draftFilter.minAge, in: 18...draftFilter.maxAge)
                    Stepper("Idade máxima: \(draftFilter.maxAge)", value: $draftFilter.maxAge, in: draftFilter.minAge...80)
                }

                Section("Preferências") {
                    Toggle("Apenas perfis verificados", isOn: $draftFilter.onlyVerified)
                        .tint(AppTheme.Colors.primaryRed)
                    Toggle("Apenas online agora", isOn: $draftFilter.onlyOnline)
                        .tint(AppTheme.Colors.primaryRed)
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.textGray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") {
                        onApply(draftFilter)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }
}

struct MatchOverlayView: View {
    let profile: UserProfile
    let onSendMessage: () -> Void
    let onKeepDiscovering: () -> Void
    @State private var appeared = false
    @State private var heartPulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.48 : 0.0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: appeared)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primaryRed.opacity(0.14))
                        .frame(width: 96, height: 96)
                        .scaleEffect(heartPulse ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: heartPulse)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .scaleEffect(heartPulse ? 1.08 : 0.96)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: heartPulse)
                }

                Text("Vocês combinaram!")
                    .font(AppTheme.Typography.title())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                Text("Você e \(profile.firstName) demonstraram interesse mútuo.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textGray)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Enviar mensagem", action: onSendMessage)

                SecondaryOutlineButton(title: "Continuar descobrindo", action: onKeepDiscovering)
            }
            .padding(24)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 28)
            .scaleEffect(appeared ? 1.0 : 0.78)
            .opacity(appeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.38, dampingFraction: 0.74), value: appeared)
        }
        .onAppear {
            appeared = true
            heartPulse = true
        }
    }
}
