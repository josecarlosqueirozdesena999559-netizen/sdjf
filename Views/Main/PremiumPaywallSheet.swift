import SwiftUI

struct PremiumPaywallSheet: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("checkmark.seal.fill", "Selo de Perfil Verificado", "Destaque sua conta com o selo verificado na tela inicial, na descoberta e no seu perfil."),
        ("eye.trianglebadge.exclamationmark.fill", "Mensagens de Visualização Única", "Envie mensagens ilimitadas que desaparecem após serem abertas uma única vez."),
        ("waveform", "Áudios de Visualização Única", "Grave e envie mensagens de voz que só podem ser ouvidas uma vez pelo destinatário."),
        ("pencil.line", "Editar Mensagens Enviadas", "Corrija ou atualize o conteúdo de qualquer mensagem mesmo após o envio."),
        ("arrow.uturn.backward.circle.fill", "Excluir Mensagens para Todos", "Apague mensagens específicas da conversa tanto para você quanto para o destinatário."),
        ("xmark.bin.fill", "Limpar Conversa para Todos", "Remova todo o histórico da conversa nos dois dispositivos com um toque."),
        ("hourglass.circle.fill", "Auto-exclusão ao Ler e Sair", "Mensagens de segurança que se autodestroem após serem lidas ao fechar o chat."),
        ("shield.lefthalf.filled", "Proteção Escura Anti-Print", "Bloqueio com tela escura contra capturas e gravações de tela nas conversas.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: AppTheme.Colors.primaryRed.opacity(0.3), radius: 14, x: 0, y: 6)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text("Mytch Premium")
                            .font(AppTheme.Typography.largeTitle())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        Text(subscriptionService.monthlyProduct?.displayPrice ?? "R$ 19,90 / mês")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 10) {
                        ForEach(benefits, id: \.title) { item in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 42, height: 42)
                                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.18), radius: 6, x: 0, y: 3)

                                    Image(systemName: item.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Text(item.subtitle)
                                        .font(AppTheme.Typography.caption())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
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
