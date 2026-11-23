import SwiftUI

/// Tela Oficial de Assinatura do Juntô Pro (R$ 19,90/mês)
/// Destaques: Pagamentos Automáticos Mercado Pago, Bot Oficial WhatsApp, Alertas Inteligentes, Planos de Economia com IA
struct JuntoProSubscriptionScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    enum PlanPeriod: String, CaseIterable {
        case monthly = "Mensal"
        case yearly = "Anual (-25%)"
    }

    @State private var selectedPeriod: PlanPeriod = .monthly
    @State private var isProcessing = false
    @State private var showCancelConfirm = false

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Barra de navegação do topo
                HStack {
                    Button { dismiss() } label: {
                        JuntoIcon(kind: .close, size: 14, color: JuntoColors.textMain, weight: 2.0)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    }

                    Spacer()

                    Text("Juntô Pro")
                        .font(.inter(16, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)

                    Spacer()

                    // Espaçador para centralizar o título
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Hero com Coroa e Emblema
                        VStack(spacing: 10) {
                            JuntoProBadgeIcon(size: 72)
                                .shadow(color: JuntoColors.accent.opacity(0.35), radius: 16, y: 6)

                            VStack(spacing: 4) {
                                Text("Eleve suas contas a outro nível")
                                    .font(.inter(22, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                    .multilineTextAlignment(.center)

                                Text("Automatize cobranças via Mercado Pago, registre despesas pelo WhatsApp e economize até 30% com nossa IA.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)

                        // Seletor de Planos: Mensal vs Anual
                        HStack(spacing: 12) {
                            planCard(
                                title: "Mensal",
                                price: "R$ 19,90",
                                periodText: "por mês",
                                note: "Sem fidelidade, cancele quando quiser",
                                isSelected: selectedPeriod == .monthly,
                                badgeText: nil
                            ) {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    selectedPeriod = .monthly
                                }
                            }

                            planCard(
                                title: "Anual",
                                price: "R$ 14,90",
                                periodText: "por mês • R$ 178,80/ano",
                                note: "Economize 25% no ano todo",
                                isSelected: selectedPeriod == .yearly,
                                badgeText: "Mais escolhido"
                            ) {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    selectedPeriod = .yearly
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Preview Interativo: Bot Oficial do WhatsApp
                        whatsappDemoCard
                            .padding(.horizontal, 20)

                        // Grade Completa dos 6 Benefícios Exclusivos
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tudo o que o Juntô Pro oferece:")
                                .font(.inter(16, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                benefitRow(
                                    icon: .wallet,
                                    iconColor: Color(hex: "#009EE3"),
                                    title: "Pagamentos Automáticos (Mercado Pago)",
                                    description: "Cobranças Pix com baixa instantânea automática. Seus amigos pagam e o saldo é quitado na hora sem precisar mandar comprovante.",
                                    tag: "Pix Instantâneo"
                                )

                                benefitRow(
                                    icon: .swipeReply,
                                    iconColor: JuntoColors.pixGreen,
                                    title: "API Oficial do WhatsApp para Despesas",
                                    description: "Mande texto, áudio de voz ou foto da comanda direto no WhatsApp do Juntô. A IA extrai o valor e lança na divisão do grupo.",
                                    tag: "Robô WhatsApp"
                                )

                                benefitRow(
                                    icon: .alertSpend,
                                    iconColor: JuntoColors.accent,
                                    title: "Alertas Inteligentes & Anti-Calote",
                                    description: "Avisos antes de estourar o orçamento do rolê, detecção de gastos duplicados e lembretes automáticos gentis para quem esqueceu de pagar.",
                                    tag: "Previsão IA"
                                )

                                benefitRow(
                                    icon: .sparkle,
                                    iconColor: Color(hex: "#7C3AED"),
                                    title: "Planos de Economia com IA Inteligente",
                                    description: "Diagnóstico financeiro pessoal e do grupo. Nossa IA analisa desperdícios e calcula metas reais para economizar até 30% nas viagens.",
                                    tag: "Consultoria IA"
                                )

                                benefitRow(
                                    icon: .camera,
                                    iconColor: Color(hex: "#2563EB"),
                                    title: "Scanner de Comandas com Visão Ilimitado",
                                    description: "Tire foto da comanda do bar ou cupom fiscal e divida item a item automaticamente, sem limite de leitura.",
                                    tag: "Ilimitado"
                                )

                                benefitRow(
                                    icon: .docText,
                                    iconColor: Color(hex: "#059669"),
                                    title: "Relatórios Profissionais em PDF e Excel",
                                    description: "Gere prestações de contas completas em PDF com gráficos e recibos anexados para enviar por e-mail ou WhatsApp.",
                                    tag: "Exportação"
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        // Status do Usuário / Botão de Ação
                        VStack(spacing: 12) {
                            if store.user.isPro {
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        JuntoIcon(kind: .crown, size: 18, color: JuntoColors.accent)
                                        Text("Você é assinante Juntô Pro ativo")
                                            .font(.inter(15, weight: .semibold))
                                            .foregroundColor(JuntoColors.primary)
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
                                    .padding(.top, 4)
                                }
                                .padding(18)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.accent.opacity(0.5), lineWidth: 1.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                Button {
                                    subscribeAction()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isProcessing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            JuntoIcon(kind: .crown, size: 18, color: JuntoColors.accent)
                                            Text("Assinar por \(selectedPeriod == .monthly ? "R$ 19,90 / mês" : "R$ 178,80 / ano")")
                                                .font(.inter(16, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        LinearGradient(
                                            colors: [JuntoColors.primary, Color(hex: "#1F2937")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: JuntoColors.primary.opacity(0.3), radius: 10, y: 4)
                                }
                                .disabled(isProcessing)

                                Text("Cobrança segura via App Store / Apple Pay • Cancele a qualquer momento nas opções da sua conta.")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textLight)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .confirmationDialog(
            "Deseja realmente cancelar o Juntô Pro?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Confirmar cancelamento", role: .destructive) {
                store.cancelPro()
            }
            Button("Voltar", role: .cancel) {}
        } message: {
            Text("Você perderá acesso aos pagamentos automáticos do Mercado Pago, bot do WhatsApp e alertas inteligentes ao final do período.")
        }
    }

    private func subscribeAction() {
        isProcessing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isProcessing = false
            store.subscribeToPro(plan: selectedPeriod.rawValue)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            dismiss()
        }
    }

    // MARK: - Card de Plano
    private func planCard(
        title: String,
        price: String,
        periodText: String,
        note: String,
        isSelected: Bool,
        badgeText: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)

                    Spacer()

                    if let badge = badgeText {
                        Text(badge)
                            .font(.inter(9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(JuntoColors.accent)
                            .clipShape(Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(price)
                        .font(.inter(22, weight: .bold))
                        .foregroundColor(JuntoColors.primary)
                    Text(periodText)
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Text(note)
                    .font(.inter(11, weight: .regular))
                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textLight)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 2.0 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: isSelected ? JuntoColors.primary.opacity(0.12) : Color.clear, radius: 8, y: 3)
        }
    }

    // MARK: - Card Ilustrativo do Bot WhatsApp
    private var whatsappDemoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "#25D366"))
                    .frame(width: 24, height: 24)
                    .overlay(
                        JuntoIcon(kind: .swipeReply, size: 12, color: .white, weight: 2.2)
                    )

                Text("Bot Oficial do WhatsApp Juntô")
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Text("EXCLUSIVO PRO")
                    .font(.inter(9, weight: .bold))
                    .foregroundColor(Color(hex: "#25D366"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#25D366").opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                // Mensagem do Usuário
                HStack {
                    Spacer()
                    Text("Gastei R$ 135 no mercado do churrasco com @pedro e @camila")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(hex: "#005C4B"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Resposta da IA do Juntô
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🤖 Juntô IA")
                            .font(.inter(11, weight: .bold))
                            .foregroundColor(JuntoColors.accent)
                        Text("✅ Despesa de R$ 135,00 lançada no grupo 'Churrasco de Sábado'! Cota de R$ 45,00 calculada para cada um com chave Pix pronta.")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .padding(10)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(hex: "#EFEAE2"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Linha de Benefício
    private func benefitRow(
        icon: JuntoIconKind,
        iconColor: Color,
        title: String,
        description: String,
        tag: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            JuntoIcon(kind: icon, size: 20, color: iconColor, weight: 1.8)
                .frame(width: 38, height: 38)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)

                    Spacer()

                    Text(tag)
                        .font(.inter(9, weight: .semibold))
                        .foregroundColor(iconColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
