import SwiftUI

/// Login limpo (1 input por tela): Tela 1 = Número do WhatsApp -> Tela 2 = Código do WhatsApp -> Início
struct LoginView: View {
    @EnvironmentObject var store: JuntoStore

    enum LoginStep {
        case phone
        case otp
    }

    @State private var step: LoginStep = .phone
    @State private var phoneText: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var accountNotFound: Bool = false
    @State private var resendSeconds: Int = 0
    @State private var resendTimer: Timer? = nil

    private var cleanDigits: String {
        ContactsManager.normalizeBrDigits(phoneText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo com voltar e progresso (2 passos)
            HStack(spacing: 14) {
                CircleNavButton(icon: "chevron.left") {
                    if step == .otp {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            otpCode = ""
                            accountNotFound = false
                            step = .phone
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.route = .welcomeAuth
                        }
                    }
                }

                GeometryReader { geo in
                    let pct: CGFloat = step == .phone ? 0.5 : 1.0
                    ZStack(alignment: .leading) {
                        Capsule().fill(JuntoColors.surfaceSubtle)
                        Capsule()
                            .fill(JuntoColors.primary)
                            .frame(width: geo.size.width * pct)
                            .animation(.easeInOut(duration: 0.25), value: step)
                    }
                }
                .frame(height: 5)

                Spacer().frame(width: 24)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    switch step {
                    case .phone:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entrar com WhatsApp")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Informe seu número cadastrado. Enviaremos um código de 6 dígitos no seu WhatsApp.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        CleanOutlineInput(
                            label: "Número do WhatsApp",
                            placeholder: "(11) 99999-9999",
                            text: $phoneText,
                            keyboardType: .phonePad,
                            leadingPrefix: "+55"
                        )
                        .onChange(of: phoneText) { _, newValue in
                            accountNotFound = false
                            let formatted = Self.formatLivePhone(newValue)
                            if formatted != phoneText { phoneText = formatted }
                        }

                        JuntoPillButton(
                            title: isLoading ? "Enviando código..." : "Avançar",
                            color: cleanDigits.count >= 10 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            sendOTP()
                        }
                        .disabled(cleanDigits.count < 10 || isLoading)

                    case .otp:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Código do WhatsApp")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Digite o código de 6 dígitos enviado para +55 \(phoneText).")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        WhatsAppSixDigitOTPView(code: $otpCode) {
                            verifyOTPAndEnter()
                        }
                        .padding(.vertical, 6)

                        if accountNotFound {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nenhuma conta encontrada para este número. Faça seu cadastro para começar.")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.orangeSave)

                                JuntoPillButton(title: "Ir para cadastro", color: JuntoColors.primary) {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        store.route = .registerFlow
                                    }
                                }
                            }
                        } else {
                            JuntoPillButton(
                                title: isLoading ? "Entrando..." : "Entrar",
                                color: otpCode.count == 6 ? JuntoColors.primary : JuntoColors.border
                            ) {
                                verifyOTPAndEnter()
                            }
                            .disabled(otpCode.count < 6 || isLoading)
                        }

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
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
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
        accountNotFound = false
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
            let outcome = await store.loginWithWhatsAppOTP(phone: cleanDigits, code: otpCode, autoNavigate: true)
            isLoading = false
            if outcome.success {
                resendTimer?.invalidate()
            } else if outcome.needsProfile {
                withAnimation(.easeInOut(duration: 0.2)) {
                    accountNotFound = true
                }
            } else if let err = outcome.errorMessage {
                otpCode = ""
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

    static func formatLivePhone(_ raw: String) -> String {
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
