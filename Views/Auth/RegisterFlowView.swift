import SwiftUI

/// Cadastro moderno e responsivo: 1 campo por tela (7 passos incluindo código de 6 dígitos via WhatsApp em quadrados estilo WhatsApp e conferência da Chave Pix)
struct RegisterFlowView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var step: Int = 1
    @State private var whatsappCode: String = ""
    @State private var resendSeconds: Int = 0
    @State private var resendTimer: Timer? = nil
    @State private var pixKeyType: String = "CPF"
    @State private var pixConfirmed: Bool = false

    private let totalSteps = 7
    private let pixTypes = ["CPF", "Celular", "E-mail", "Aleatória"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: botão voltar circular + barra de progresso minimalista
            HStack(spacing: 14) {
                CircleNavButton(icon: "chevron.left") {
                    if step > 1 {
                        withAnimation(.easeInOut(duration: 0.2)) { step -= 1 }
                    } else {
                        withAnimation { store.route = .welcomeAuth }
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(JuntoColors.surfaceSubtle)
                            .frame(height: 5)
                        Capsule()
                            .fill(JuntoColors.primary)
                            .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps), height: 5)
                            .animation(.easeInOut(duration: 0.25), value: step)
                    }
                }
                .frame(height: 5)

                Text("\(step)/\(totalSteps)")
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 20)

            // Conteúdo responsivo para qualquer tamanho de tela
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    switch step {
                    case 1:
                        stepTitle("Qual é o seu e-mail?", subtitle: "Ele será usado para entrar e proteger sua conta.")
                        CleanOutlineInput(
                            label: "Endereço de e-mail",
                            placeholder: "email@provedor.com",
                            text: $store.draftEmail,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                    case 2:
                        stepTitle("Escolha seu @usuário", subtitle: "Seus amigos vão te encontrar apenas usando esse nome.")
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text("Nome de usuário")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                usernameStatusLabel
                            }

                            HStack(spacing: 4) {
                                Text("@")
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                TextField("ana123", text: $store.draftUsername)
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: store.draftUsername) { _, newValue in
                                        store.checkUsername(newValue)
                                    }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(usernameBorderColor, lineWidth: 1.2)
                            )
                        }

                    case 3:
                        stepTitle("Crie sua senha", subtitle: "Escolha uma senha segura com pelo menos 8 caracteres.")
                        CleanOutlineSecureInput(
                            label: "Senha",
                            placeholder: "••••••••",
                            text: $store.draftPassword,
                            helperText: "Mínimo de 8 caracteres"
                        )

                    case 4:
                        stepTitle("Como você se chama?", subtitle: "Esse nome aparecerá para seus amigos nos grupos.")
                        CleanOutlineInput(
                            label: "Nome completo",
                            placeholder: "Ana Silva",
                            text: $store.draftFullName
                        )

                    case 5:
                        stepTitle("Qual é o seu telefone?", subtitle: "Enviaremos um código de 6 dígitos via WhatsApp para confirmar seu número.")
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Telefone (WhatsApp)")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)

                            HStack(spacing: 10) {
                                HStack(spacing: 6) {
                                    Text("🇧🇷")
                                        .font(.system(size: 19))
                                    Text("+55")
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(JuntoColors.surfaceSubtle)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(JuntoColors.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 11))

                                TextField("(11) 91234-5678", text: $store.draftPhone)
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                    .keyboardType(.phonePad)
                                    .padding(.horizontal, 14)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(JuntoColors.inputBorder, lineWidth: 1)
                                    )
                                    .onChange(of: store.draftPhone) { _, newValue in
                                        store.draftPhone = formatPhone(newValue)
                                    }
                            }
                        }

                    case 6:
                        // Tela única de código de 6 dígitos via WhatsApp com os 6 quadrados estilo WhatsApp
                        stepTitle(
                            "Código enviado via WhatsApp",
                            subtitle: "Digite o código de 6 dígitos enviado para o WhatsApp +55 \(store.draftPhone)."
                        )

                        WhatsAppSixDigitOTPView(code: $whatsappCode) {
                            // Avança automaticamente ao completar os 6 dígitos
                            if whatsappCode.count == 6 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                        .padding(.top, 4)

                        HStack {
                            if resendSeconds > 0 {
                                Text("Reenviar código via WhatsApp em \(resendSeconds)s")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .monospacedDigit()
                            } else {
                                Button {
                                    startResendCooldown()
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    store.showToast("Novo código enviado via WhatsApp.", icon: "message")
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Reenviar código via WhatsApp")
                                            .font(.inter(13, weight: .medium))
                                    }
                                    .foregroundColor(JuntoColors.primary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 4)

                    default:
                        stepTitle(
                            "Cadastre sua chave Pix",
                            subtitle: "Confira com atenção: é por essa chave que você receberá os pagamentos dos seus grupos e rolês."
                        )

                        HStack(spacing: 8) {
                            ForEach(pixTypes, id: \.self) { type in
                                let active = pixKeyType == type
                                Button {
                                    if pixKeyType != type {
                                        pixKeyType = type
                                        store.draftPixKey = ""
                                        pixConfirmed = false
                                    }
                                } label: {
                                    Text(type)
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(active ? .white : JuntoColors.textMain)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        CleanOutlineInput(
                            label: "Sua chave Pix (\(pixKeyType))",
                            placeholder: pixPlaceholder,
                            text: $store.draftPixKey,
                            keyboardType: pixKeyType == "E-mail" ? .emailAddress : .default,
                            autocapitalization: .never
                        )
                        .onChange(of: store.draftPixKey) { _, _ in
                            pixConfirmed = false
                        }

                        if !store.draftPixKey.trimmingCharacters(in: .whitespaces).isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(JuntoColors.accent)
                                    Text("Confira sua chave antes de concluir:")
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                }

                                Text(store.draftPixKey)
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)

                                Button {
                                    pixConfirmed.toggle()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: pixConfirmed ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 18))
                                            .foregroundColor(pixConfirmed ? JuntoColors.pixGreen : JuntoColors.textMuted)
                                        Text("Conferi minha chave Pix e ela está correta")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMain)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    JuntoPillButton(title: step == totalSteps ? "Criar conta" : "Próximo", color: JuntoColors.primary) {
                        handleNext()
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.white.ignoresSafeArea())
        .onDisappear {
            resendTimer?.invalidate()
        }
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.inter(24, weight: .regular))
                .foregroundColor(JuntoColors.textMain)
            Text(subtitle)
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func startResendCooldown() {
        resendTimer?.invalidate()
        resendSeconds = 30
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendSeconds > 0 {
                resendSeconds -= 1
            } else {
                resendTimer?.invalidate()
            }
        }
    }

    private func handleNext() {
        switch step {
        case 1:
            let email = store.draftEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            guard email.contains("@"), email.contains(".") else {
                store.showToast("Digite um endereço de e-mail válido.", icon: "envelope")
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 2 }

        case 2:
            let clean = store.draftUsername.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard clean.count >= 3, store.usernameState != .unavailable else {
                store.showToast("Escolha um @usuário disponível.", icon: "at")
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 3 }

        case 3:
            guard store.draftPassword.count >= 8 else {
                store.showToast("A senha precisa ter no mínimo 8 caracteres.", icon: "lock")
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 4 }

        case 4:
            guard store.draftFullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
                store.showToast("Informe seu nome completo.", icon: "person")
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 5 }

        case 5:
            guard store.draftPhone.filter({ $0.isNumber }).count >= 10 else {
                store.showToast("Digite um telefone válido com DDD.", icon: "phone")
                return
            }
            whatsappCode = ""
            startResendCooldown()
            withAnimation(.easeInOut(duration: 0.2)) { step = 6 }

        case 6:
            let digitsOnly = whatsappCode.filter { $0.isNumber }
            guard digitsOnly.count == 6 else {
                store.showToast("Digite os 6 dígitos do código enviado via WhatsApp.", icon: "number")
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 7 }

        default:
            let cleanPix = store.draftPixKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanPix.count >= 5 else {
                store.showToast("Informe sua chave Pix para receber pagamentos.", icon: "qrcode")
                return
            }
            guard pixConfirmed else {
                store.showToast("Confirme que sua chave Pix está correta.", icon: "checkmark.square")
                return
            }
            store.completeRegistration()
        }
    }

    private var pixPlaceholder: String {
        switch pixKeyType {
        case "CPF": return "000.000.000-00"
        case "Celular": return "+55 (11) 91234-5678"
        case "E-mail": return "email@provedor.com"
        default: return "Cole sua chave aleatória"
        }
    }

    private var usernameBorderColor: Color {
        switch store.usernameState {
        case .available: return JuntoColors.pixGreen
        case .unavailable: return JuntoColors.danger
        default: return JuntoColors.inputBorder
        }
    }

    @ViewBuilder
    private var usernameStatusLabel: some View {
        switch store.usernameState {
        case .idle: EmptyView()
        case .tooShort:
            Text("Mínimo 3 letras")
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
        case .checking:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.65)
                Text("Verificando...")
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
        case .available:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                Text("Disponível")
            }
            .font(.inter(12, weight: .medium))
            .foregroundColor(JuntoColors.pixGreen)
        case .unavailable:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle")
                Text("Indisponível")
            }
            .font(.inter(12, weight: .medium))
            .foregroundColor(JuntoColors.danger)
        }
    }

    private func formatPhone(_ raw: String) -> String {
        let digits = String(raw.filter { $0.isNumber }.prefix(11))
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i == 0 { result.append("(") }
            if i == 2 { result.append(") ") }
            if i == 7 { result.append("-") }
            result.append(ch)
        }
        return result
    }
}

// MARK: - Componente de 6 Quadrados de Código Estilo WhatsApp (Responsivo para qualquer tamanho de tela)
struct WhatsAppSixDigitOTPView: View {
    @Binding var code: String
    var onComplete: (() -> Void)? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Campo numérico invisível para captura nativa do teclado e preenchimento automático de código (OTP)
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                    if filtered != code {
                        code = filtered
                    }
                    if filtered.count == 6 {
                        onComplete?()
                    }
                }

            // 6 quadrados responsivos estilo WhatsApp
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    let charStr = digitAt(index)
                    let isCurrent = isFocused && (code.count == index || (code.count == 6 && index == 5))
                    let isFilled = !charStr.isEmpty

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isCurrent ? JuntoColors.primary : (isFilled ? JuntoColors.primary.opacity(0.45) : JuntoColors.inputBorder),
                                        lineWidth: isCurrent ? 1.8 : 1.0
                                    )
                            )

                        if isFilled {
                            Text(charStr)
                                .font(.inter(22, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .transition(.scale.combined(with: .opacity))
                        } else if isCurrent {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(JuntoColors.primary)
                                .frame(width: 2, height: 22)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFocused = true
            }
        }
    }

    private func digitAt(_ index: Int) -> String {
        let digits = Array(code)
        guard index < digits.count else { return "" }
        return String(digits[index])
    }
}
