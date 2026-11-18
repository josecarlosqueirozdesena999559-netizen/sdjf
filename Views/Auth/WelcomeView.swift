import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showServerConfig = false

    var body: some View {
        ZStack {
            AnimatedAuthBackground()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        showServerConfig = true
                    } label: {
                        Image(systemName: "network")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Configurar servidor")
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 18) {
                    if let logoName = BrandIdentitySlot.logoImageName {
                        Image(logoName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 108, height: 108)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(.white.opacity(0.28), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 12)
                    }

                    VStack(spacing: 8) {
                        Text(BrandIdentitySlot.appName ?? "Mytch")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Conexões reais, simples e do seu jeito.")
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Criar conta") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .onboarding
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .login
                        }
                    } label: {
                        Text("Entrar")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showServerConfig) {
            ServerConfigSheet()
        }
    }
}

private struct ServerConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlText: String = NetworkConfig.customURL ?? NetworkConfig.defaultURL
    @State private var statusMessage: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                MinimalTextField(
                    label: "URL do Servidor (HTTPS)",
                    placeholder: "https://....trycloudflare.com",
                    text: $urlText,
                    keyboardType: .URL,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )

                Text("URL atual: \(NetworkConfig.baseURL.absoluteString)")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)

                if let statusMessage {
                    Text(statusMessage)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                }

                PrimaryButton(title: "Salvar e Testar", isLoading: isTesting) {
                    NetworkConfig.customURL = urlText
                    Task {
                        await testHealth()
                    }
                }

                SecondaryOutlineButton(title: "Restaurar padrão") {
                    NetworkConfig.customURL = nil
                    urlText = NetworkConfig.defaultURL
                    statusMessage = "Restaurado para \(NetworkConfig.defaultURL)"
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.background)
            .navigationTitle("Servidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }

    private func testHealth() async {
        isTesting = true
        statusMessage = "Testando conexão..."
        guard let url = URL(string: "/health", relativeTo: NetworkConfig.baseURL) else {
            statusMessage = "URL inválida."
            isTesting = false
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            statusMessage = "Status \(code): \(body)"
        } catch {
            statusMessage = "Falha: \(error.localizedDescription)"
        }
        isTesting = false
    }
}
