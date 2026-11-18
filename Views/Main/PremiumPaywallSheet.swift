import SwiftUI

struct PremiumPaywallSheet: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("checkmark.seal.fill", "Selo Verificado no Perfil e Início", "Destaque-se na descoberta e no seu perfil."),
        ("1.circle.fill", "Mensagens e Áudios Únicos Ilimitados", "Envie textos e áudios com visualização única."),
        ("pencil", "Editar e Excluir para Todos", "Edite ou apague qualquer mensagem enviada."),
        ("trash.fill", "Limpar Conversa para Todos", "Remova o histórico completo dos dois lados."),
        ("timer", "Auto-exclusão ao Sair", "Mensagens lidas somem ao fechar a conversa."),
        ("eye.slash.fill", "Proteção Escura Anti-Print", "Tela escura contra capturas e gravações.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 68)
                                .shadow(color: AppTheme.Colors.primaryRed.opacity(0.3), radius: 14, x: 0, y: 6)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text("Plano Premium")
                            .font(AppTheme.Typography.largeTitle())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        Text(subscriptionService.monthlyProduct?.displayPrice ?? "R$ 19,90 / mês")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        ForEach(benefits, id: \.title) { item in
                            HStack(spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                                    .frame(width: 40, height: 40)
                                    .background(AppTheme.Colors.primaryRed.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Text(item.subtitle)
                                        .font(AppTheme.Typography.caption())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                        }
                    }

                    if let error = subscriptionService.errorMessage {
                        Text(error)
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(
                        title: appState.isPremium ? "Assinatura Ativa" : "Assinar por R$ 19,90/mês",
                        isEnabled: !appState.isPremium,
                        isLoading: subscriptionService.isPurchasing
                    ) {
                        Task {
                            await subscriptionService.purchaseMonthly(appState: appState)
                            if appState.isPremium {
                                dismiss()
                            }
                        }
                    }

                    SecondaryOutlineButton(title: "Restaurar compras") {
                        Task {
                            await subscriptionService.restorePurchases(appState: appState)
                            if appState.isPremium {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.chipUnselected, in: Circle())
                    }
                }
            }
        }
    }
}
