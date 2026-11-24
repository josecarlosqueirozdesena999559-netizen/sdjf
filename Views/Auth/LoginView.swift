import SwiftUI

/// Entrada e Cadastro 100% via WhatsApp + Código OTP de 6 dígitos (sem nome de usuário e sem senha)
struct LoginView: View {
    @EnvironmentObject var store: JuntoStore

    enum WhatsAppAuthStep {
        case phone
        case otp
        case profile
    }

    @State private var step: WhatsAppAuthStep = .phone
    @State private var phoneText: String = ""
    @State private var otpCode: String = ""
    @State private var fullNameText: String = ""
    @State private var pixKeyText: String = ""
    @State private var isLoading: Bool = false
    @State private var resendSeconds: Int = 0
    @State private var resendTimer: Timer? = nil

    private var cleanDigits: String {
        ContactsManager.normalizeBrDigits(phoneText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") {
                    switch step {
                    case .phone:
                        withAnimation { store.route = .welcomeAuth }
                    case .otp:
                        withAnimation {
                            otpCode = ""
                            step = .phone
                        }
                    case .profile:
                        withAnimation { step = .otp }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    switch step {
                    case .phone:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Entrar com WhatsApp")
                                .font(.inter(24, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Informe seu número. Enviaremos um código de 6 dígitos no seu WhatsApp para confirmar.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 18)

                        CleanOutlineInput(
                            label: "Número do WhatsApp",
                            placeholder: "(11) 99999-9999",
                            text: $phoneText,
                            keyboardType: .phonePad,
                            leadingPrefix: "+55"
                        )
                        .onChange(of: phoneText) { _, newValue in
                            let formatted = formatLivePhone(newValue)
                            if formatted != phoneText { phoneText = formatted }
                        }

                        JuntoPillButton(
                            title: isLoading ? "Enviando código..." : "Enviar código no WhatsApp",
                            color: cleanDigits.count >= 10 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            sendOTP()
                        }
                        .disabled(cleanDigits.count < 10 || isLoading)
                        .padding(.top, 6)

                    case .otp:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Código do WhatsApp")
                                .font(.inter(24, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Digite o código de 6 dígitos enviado para +55 \(phoneText).")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 18)

                        WhatsAppSixDigitOTPView(code: $otpCode) {
                            verifyOTPAndEnter()
                        }
                        .padding(.vertical, 6)

                        JuntoPillButton(
                            title: isLoading ? "Confirmando..." : "Confirmar código",
                            color: otpCode.count == 6 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            verifyOTPAndEnter()
                        }
                        .disabled(otpCode.count < 6 || isLoading)

                        HStack {
                            Spacer()
                            if resendSeconds > 0 {
                                Text("Reenviar código em \(resendSeconds)s")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .monospacedDigit()
                            } else {
                                Button("Reenviar código no WhatsApp") {
                                    sendOTP()
                                }
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(JuntoColors.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)

                    case .profile:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Como você se chama?")
                                .font(.inter(24, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Seu nome aparecerá para seus contatos e grupos no Juntô.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 18)

                        CleanOutlineInput(
                            label: "Seu nome",
                            placeholder: "Ex: Ana Silva",
                            text: $fullNameText
                        )

                        CleanOutlineInput(
                            label: "Chave Pix (opcional)",
                            placeholder: "CPF, celular ou e-mail",
                            text: $pixKeyText,
                            autocapitalization: .never
                        )

                        JuntoPillButton(
                            title: isLoading ? "Entrando..." : "Começar no Juntô",
                            color: fullNameText.trimmingCharacters(in: .whitespaces).count >= 2 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            completeNewProfile()
                        }
                        .disabled(fullNameText.trimmingCharacters(in: .whitespaces).count < 2 || isLoading)
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onDisappear {
            resendTimer?.invalidate()
            resendTimer = nil
        }
    }

    private func sendOTP() {
        guard cleanDigits.count >= 10, !isLoading else { return }
        isLoading = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            let result = await JuntoBackendService.shared.requestWhatsAppOTP(phone: cleanDigits)
            isLoading = false
            if result.ok {
                startResendCountdown()
                store.showToast("Código enviado para seu WhatsApp!", icon: "paperplane.fill")
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .otp
                }
            } else {
                store.showToast("Não foi possível enviar o código. Verifique sua conexão.", icon: "exclamationmark.triangle")
            }
        }
    }

    private func verifyOTPAndEnter() {
        guard otpCode.count == 6, !isLoading else { return }
        isLoading = true

        Task {
            let outcome = await store.loginWithWhatsAppOTP(phone: cleanDigits, code: otpCode)
            isLoading = false
            if outcome.success {
                resendTimer?.invalidate()
            } else if outcome.needsProfile {
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .profile
                }
            } else if let err = outcome.errorMessage {
                otpCode = ""
                store.showToast(err, icon: "exclamationmark.circle")
            }
        }
    }

    private func completeNewProfile() {
        let cleanName = fullNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.count >= 2, !isLoading else { return }
        isLoading = true

        Task {
            let outcome = await store.loginWithWhatsAppOTP(
                phone: cleanDigits,
                code: otpCode,
                fullName: cleanName,
                pixKey: pixKeyText.isEmpty ? nil : pixKeyText
            )
            isLoading = false
            if !outcome.success, let err = outcome.errorMessage {
                store.showToast(err, icon: "exclamationmark.circle")
            }
        }
    }

    private func startResendCountdown() {
        resendTimer?.invalidate()
        resendSeconds = 45
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if resendSeconds > 0 {
                    resendSeconds -= 1
                } else {
                    resendTimer?.invalidate()
                    resendTimer = nil
                }
            }
        }
    }

    private func formatLivePhone(_ raw: String) -> String {
        let digits = String(raw.filter { $0.isNumber }.prefix(11))
        if digits.count <= 2 { return digits }
        if digits.count <= 7 {
            return "(\(digits.prefix(2))) \(digits.dropFirst(2))"
        }
        let ddd = digits.prefix(2)
        let mid = digits.dropFirst(2).prefix(digits.count == 11 ? 5 : 4)
        let end = digits.dropFirst(digits.count == 11 ? 7 : 6)
        return "(\(ddd)) \(mid)-\(end)"
    }
}
