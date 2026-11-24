import SwiftUI

/// Tela Limpa do Juntô Pro (R$ 19,90/mês) — Lista direta de recursos com "✓" na cor do sistema, sem capturas de tela ou visual carregado
struct JuntoProSubscriptionScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    enum PlanPeriod: String, CaseIterable {
        case monthly = "Mensal"
        case yearly = "Anual"
    }

    @StateObject private var storeKit = JuntoStoreKitManager.shared
    @State private var selectedPeriod: PlanPeriod = .monthly
    @State private var isProcessing = false
    @State private var showCancelConfirm = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false

    private let proFeatures: [(title: String, subtitle: String)] = [
        ("Relatórios e Fechamentos em PDF", "Exporte seus gastos mensais ou o extrato oficial de qualquer grupo em PDF pronto para enviar no WhatsApp."),
        ("Cobrança Pix em 1 toque no WhatsApp", "Gere automaticamente a lista de quem falta pagar com os valores e sua chave Pix para cobrar sem constrangimento."),
        ("Insights Inteligentes de Gastos", "Veja sua maior categoria do mês, média por pagamento e taxa de quitação em tempo real."),
        ("Divisão Padrão Personalizada", "Escolha como ratear despesas automaticamente por grupo: igualitária, proporcional ao consumo ou cota fixa."),
        ("Grupos ilimitados e múltiplos admins", "Crie quantos grupos, viagens e potes mensais quiser e adicione co-organizadores."),
        ("Selo de Verificado Exclusivo", "Assinante Mensal recebe o Selo Roxo e o Assinante Anual recebe o Selo Dourado em todas as conversas e grupos.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Topo limpo (apenas X sem fundo)
            HStack {
                PopupCloseButton { dismiss() }

                Spacer()

                Text("Juntô Pro")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Cabeçalho minimalista focado em rolês, viagens e lazer entre amigos
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mais praticidade para seus rolês e viagens")
                            .font(.inter(22, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Crie grupos ilimitados com seus amigos, organize metas mensais e decida tudo pelo bate-papo.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    .padding(.top, 4)

                    // Seletor Mensal / Anual limpo (preços reais do StoreKit 2 quando disponíveis)
                    HStack(spacing: 12) {
                        planCard(
                            title: "Mensal",
                            price: storeKit.monthlyProduct?.displayPrice ?? "R$ 19,90",
                            periodText: "por mês",
                            badgeType: .monthly,
                            badgeLabel: "Selo Roxo",
                            isSelected: selectedPeriod == .monthly
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPeriod = .monthly
                            }
                        }

                        planCard(
                            title: "Anual",
                            price: storeKit.yearlyProduct?.displayPrice ?? "R$ 178,80",
                            periodText: "por ano (economize 25%)",
                            badgeType: .yearly,
                            badgeLabel: "Selo Dourado",
                            isSelected: selectedPeriod == .yearly
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPeriod = .yearly
                            }
                        }
                    }

                    // Lista limpa de funções com "✓" na cor do sistema
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Incluído no plano")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMuted)

                        VStack(spacing: 0) {
                            ForEach(Array(proFeatures.enumerated()), id: \.offset) { index, feature in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(JuntoColors.primary)
                                        .frame(width: 20, height: 22)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(feature.title)
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)

                                        Text(feature.subtitle)
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 14)

                                if index < proFeatures.count - 1 {
                                    Divider()
                                        .padding(.leading, 34)
                                }
                            }
                        }
                    }

                    // Ação de assinatura
                    VStack(spacing: 12) {
                        if store.user.isPro && !store.isProRenewalDue {
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    VerifiedBadgeView(type: store.user.proPlanType, size: 18)
                                    Text("Plano Juntô Pro ativo (\(store.user.proPlanType.displayName))")
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                }

                                if let expires = store.user.proExpiresDateText {
                                    Text(expires)
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button {
                                subscribeAction()
                            } label: {
                                HStack(spacing: 8) {
                                    if isProcessing || storeKit.isPurchasing {
                                        ProgressView().tint(.white)
                                    } else {
                                        let priceLabel = selectedPeriod == .monthly
                                            ? "\(storeKit.monthlyProduct?.displayPrice ?? "R$ 19,90") / mês"
                                            : "\(storeKit.yearlyProduct?.displayPrice ?? "R$ 178,80") / ano"
                                        Text(store.isProRenewalDue ? "Renovar por \(priceLabel)" : "Assinar por \(priceLabel)")
                                            .font(.inter(16, weight: .medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .disabled(isProcessing || storeKit.isPurchasing)

                            Button {
                                restoreAction()
                            } label: {
                                Text("Restaurar compras")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                                    .padding(.vertical, 6)
                            }
                            .disabled(isProcessing || storeKit.isPurchasing)

                            Text("Assinatura com renovação automática pela App Store. Cancele a qualquer momento em Ajustes > Conta Apple > Assinaturas.")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            HStack(spacing: 14) {
                                Button("Termos de Uso") { showTermsSheet = true }
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.textMuted)
                                Text("·").foregroundColor(JuntoColors.textLight)
                                Button("Política de Privacidade") { showPrivacySheet = true }
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .task {
            await storeKit.loadProducts()
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsOfUsePopupSheet()
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyPopupSheet()
        }
        .confirmationDialog(
            "Deseja cancelar o Juntô Pro?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Confirmar cancelamento", role: .destructive) {
                store.cancelPro()
            }
            Button("Voltar", role: .cancel) {}
        }
    }

    private func subscribeAction() {
        isProcessing = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let planType: ProPlanType = selectedPeriod == .monthly ? .monthly : .yearly

        Task {
            let outcome = await storeKit.purchase(planType: planType, username: store.user.username)
            isProcessing = false
            if outcome.success {
                store.subscribeToPro(
                    plan: outcome.planName ?? (planType == .yearly ? "Anual (R$ 178,80)" : "Mensal (R$ 19,90)"),
                    planType: planType
                )
                if let exp = outcome.expiresDateText {
                    store.user.proExpiresDateText = exp
                }
                dismiss()
            } else if let err = outcome.errorMessage {
                store.showToast(err, icon: "exclamationmark.triangle")
            }
        }
    }

    private func restoreAction() {
        isProcessing = true
        Task {
            let result = await storeKit.restorePurchases(username: store.user.username)
            isProcessing = false
            if result.restored {
                store.subscribeToPro(
                    plan: result.planName ?? "Juntô Pro",
                    planType: result.planType
                )
                if let exp = result.expiresDateText {
                    store.user.proExpiresDateText = exp
                }
                store.showToast("Assinatura restaurada com sucesso!", icon: "checkmark.seal.fill")
                dismiss()
            } else {
                store.showToast("Nenhuma assinatura ativa encontrada na sua Conta Apple.", icon: "info.circle")
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        periodText: String,
        badgeType: ProPlanType,
        badgeLabel: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textLight)
                }

                Text(price)
                    .font(.inter(20, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Text(periodText)
                    .font(.inter(11, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    VerifiedBadgeView(type: badgeType, size: 13)
                    Text(badgeLabel)
                        .font(.inter(11, weight: .medium))
                        .foregroundColor(badgeType == .yearly ? Color(hex: "#D97706") : Color(hex: "#7C3AED"))
                }
                .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 1.5 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
