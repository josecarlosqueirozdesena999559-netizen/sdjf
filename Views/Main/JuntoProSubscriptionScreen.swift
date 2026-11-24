import SwiftUI

/// Tela Limpa do Juntô Pro (R$ 19,90/mês) — Lista direta de recursos com "✓" na cor do sistema, sem capturas de tela ou visual carregado
struct JuntoProSubscriptionScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    enum PlanPeriod: String, CaseIterable {
        case monthly = "Mensal"
        case yearly = "Anual"
    }

    @State private var selectedPeriod: PlanPeriod = .monthly
    @State private var isProcessing = false
    @State private var showCancelConfirm = false

    private let proFeatures: [(title: String, subtitle: String)] = [
        ("Selo de Verificado Exclusivo", "Assinante Mensal recebe o Selo Roxo e o Assinante Anual recebe o Selo Dourado em todas as telas, grupos e conversas."),
        ("Grupos, viagens e rolês ilimitados", "No plano gratuito você tem 1 grupo ativo. No Pro, crie quantos rolês, viagens e grupos mensais quiser."),
        ("Criar Grupos Públicos", "Organize encontros, piscina no clube ou futebol com limite de até 100 vagas e gestão simplificada."),
        ("Múltiplos administradores por grupo", "Adicione amigos como co-organizadores para ajudar a lançar gastos e confirmar pagamentos."),
        ("Alertas e lembretes prioritários", "Notificações automáticas de prazos de metas e confirmações em tempo real quando participantes pagam.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Topo limpo
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 36, height: 36)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }

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

                    // Seletor Mensal / Anual limpo
                    HStack(spacing: 12) {
                        planCard(
                            title: "Mensal",
                            price: "R$ 19,90",
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
                            price: "R$ 14,90",
                            periodText: "por mês (R$ 178,80/ano)",
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
                        if store.user.isPro {
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

                                Button("Cancelar assinatura") {
                                    showCancelConfirm = true
                                }
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(JuntoColors.danger)
                                .padding(.top, 2)
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
                                    if isProcessing {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Assinar por \(selectedPeriod == .monthly ? "R$ 19,90 / mês" : "R$ 178,80 / ano")")
                                            .font(.inter(16, weight: .medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .disabled(isProcessing)

                            Text("Cancele quando quiser nas configurações da sua conta.")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white.ignoresSafeArea())
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

        let planName = selectedPeriod == .monthly ? "Mensal (R$ 19,90)" : "Anual (R$ 178,80)"
        let planType: ProPlanType = selectedPeriod == .monthly ? .monthly : .yearly

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isProcessing = false
            store.subscribeToPro(plan: planName, planType: planType)
            dismiss()
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
