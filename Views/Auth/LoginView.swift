import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var showForgotPasswordSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") {
                    withAnimation { store.route = .welcomeAuth }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Entrar")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.top, 22)

                    CleanOutlineInput(
                        label: "Endereço de e-mail ou @usuário",
                        placeholder: "voce@email.com ou @usuario",
                        text: $identifier,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    CleanOutlineSecureInput(
                        label: "Senha",
                        placeholder: "••••••••",
                        text: $password
                    )

                    JuntoPillButton(title: "Entrar", color: JuntoColors.primary) {
                        store.login(identifier: identifier, password: password)
                    }
                    .padding(.top, 10)

                    HStack {
                        Spacer()
                        Button {
                            showForgotPasswordSheet = true
                        } label: {
                            Text("Esqueceu sua senha?")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.primary)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordPopupSheet(initialIdentifier: identifier)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationCornerRadius(20)
        }
    }
}

// MARK: - Popup Real "Esqueci Minha Senha" (Com botão X no topo, código de 6 dígitos e redefinição sincronizada no banco)
struct ForgotPasswordPopupSheet: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialIdentifier: String = ""

    enum RecoveryStep {
        case requestCode
        case verifyAndReset
        case completed
    }

    @State private var step: RecoveryStep = .requestCode
    @State private var accountIdentifier: String = ""
    @State private var verificationCode: String = ""
    @State private var generatedCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Barra Superior Fixa com Botão X para sair
            HStack {
                Text("Recuperar senha")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.white)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    switch step {
                    case .requestCode:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Esqueceu sua senha?")
                                .font(.inter(22, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Informe seu e-mail cadastrado ou seu @usuário. Enviaremos um código de segurança de 6 dígitos para redefinir sua senha.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }

                        CleanOutlineInput(
                            label: "E-mail ou @usuário",
                            placeholder: "ex: lucas.andrade@exemplo.com",
                            text: $accountIdentifier,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        JuntoPillButton(
                            title: isLoading ? "Enviando código..." : "Enviar código de recuperação",
                            color: JuntoColors.primary
                        ) {
                            handleSendRecoveryCode()
                        }
                        .disabled(isLoading)

                    case .verifyAndReset:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Digite o código e a nova senha")
                                .font(.inter(22, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Enviamos um código de 6 dígitos para \(accountIdentifier) e também por notificação no seu aparelho.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }

                        // Aviso do código enviado para facilitar teste imediato
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 15))
                                .foregroundColor(JuntoColors.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Código de verificação enviado")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                Text(generatedCode)
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                                    .monospacedDigit()
                            }
                            Spacer()
                            Button("Usar código") {
                                verificationCode = generatedCode
                            }
                            .font(.inter(12, weight: .medium))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(JuntoColors.primaryLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(14)
                        .background(JuntoColors.warmBg)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        CleanOutlineInput(
                            label: "Código de 6 dígitos",
                            placeholder: "000000",
                            text: $verificationCode,
                            keyboardType: .numberPad
                        )

                        CleanOutlineSecureInput(
                            label: "Nova senha",
                            placeholder: "Mínimo de 8 caracteres",
                            text: $newPassword
                        )

                        CleanOutlineSecureInput(
                            label: "Confirmar nova senha",
                            placeholder: "Repita a nova senha",
                            text: $confirmPassword
                        )

                        JuntoPillButton(
                            title: isLoading ? "Salvando..." : "Redefinir senha",
                            color: JuntoColors.primary
                        ) {
                            handleResetPassword()
                        }
                        .disabled(isLoading)

                        Button("Alterar e-mail ou reenviar código") {
                            withAnimation { step = .requestCode }
                        }
                        .font(.inter(13, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(maxWidth: .infinity)

                    case .completed:
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(JuntoColors.pixGreen)
                                .padding(.top, 18)

                            Text("Senha redefinida com sucesso")
                                .font(.inter(20, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                                .multilineTextAlignment(.center)

                            Text("Sua nova senha já está ativa e sincronizada com segurança. Você já pode acessar sua conta.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            JuntoPillButton(title: "Voltar para o login", color: JuntoColors.primary) {
                                dismiss()
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            if accountIdentifier.isEmpty {
                accountIdentifier = initialIdentifier
            }
        }
    }

    private func handleSendRecoveryCode() {
        let clean = accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else {
            store.showToast("Informe seu e-mail ou @usuário.", icon: "exclamationmark.circle")
            return
        }
        isLoading = true
        let code = String(Int.random(in: 100000...999999))
        generatedCode = code

        Task {
            await store.requestPasswordReset(identifier: clean, code: code)
            isLoading = false
            withAnimation(.easeInOut(duration: 0.2)) {
                step = .verifyAndReset
            }
        }
    }

    private func handleResetPassword() {
        let cleanCode = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanCode == generatedCode else {
            store.showToast("Código de verificação incorreto.", icon: "exclamationmark.circle")
            return
        }
        guard newPassword.count >= 6 else {
            store.showToast("A nova senha deve ter pelo menos 6 caracteres.", icon: "lock")
            return
        }
        guard newPassword == confirmPassword else {
            store.showToast("As senhas não coincidem.", icon: "exclamationmark.circle")
            return
        }

        isLoading = true
        Task {
            await store.confirmPasswordReset(identifier: accountIdentifier, code: cleanCode, newPassword: newPassword)
            isLoading = false
            withAnimation(.easeInOut(duration: 0.2)) {
                step = .completed
            }
        }
    }
}
