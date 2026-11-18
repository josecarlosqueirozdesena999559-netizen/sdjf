import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showServerConfig = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    Color(red: 1.0, green: 0.94, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        showServerConfig = true
                    } label: {
                        Image(systemName: "network")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.Colors.white, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Configurar servidor")
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 20) {
                    if let logoName = BrandIdentitySlot.logoImageName {
                        Image(logoName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: AppTheme.Colors.primaryRed.opacity(0.28), radius: 20, x: 0, y: 10)
                    }

                    VStack(spacing: 8) {
                        Text(BrandIdentitySlot.appName ?? "Mytch")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        Text("Conexões reais, simples e do seu jeito.")
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(AppTheme.Colors.textGray)
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

                    SecondaryOutlineButton(title: "Entrar") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .login
                        }
                    }
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
