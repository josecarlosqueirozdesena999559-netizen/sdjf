import SwiftUI
import PhotosUI

/// Cadastro passo a passo (1 input por tela):
/// 1. Nome completo -> 2. Idade -> 3. Telefone (WhatsApp) -> 4. Código do WhatsApp -> 5. Foto opcional com nome abaixo -> Início
struct RegisterFlowView: View {
    @EnvironmentObject var store: JuntoStore

    enum RegisterStep: Int, CaseIterable {
        case fullName = 1
        case age = 2
        case phone = 3
        case otp = 4
        case photo = 5
    }

    @State private var step: RegisterStep = .fullName
    @State private var fullNameText: String = ""
    @State private var ageText: String = ""
    @State private var phoneText: String = ""
    @State private var otpCode: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var avatarData: Data? = nil

    @State private var isLoading: Bool = false
    @State private var resendSeconds: Int = 0
    @State private var resendTimer: Timer? = nil

    private var cleanFullName: String {
        fullNameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAge: Int? {
        Int(ageText.filter { $0.isNumber })
    }

    private var isAgeValid: Bool {
        guard let age = parsedAge else { return false }
        return age >= 16 && age <= 120
    }

    private var cleanDigits: String {
        ContactsManager.normalizeBrDigits(phoneText)
    }

    private var progressFraction: CGFloat {
        CGFloat(step.rawValue) / CGFloat(RegisterStep.allCases.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo com botão voltar e barra de progresso limpa
            HStack(spacing: 14) {
                if step != .photo {
                    CircleNavButton(icon: "chevron.left") {
                        goBack()
                    }
                } else {
                    Spacer().frame(width: 40)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(JuntoColors.surfaceSubtle)
                        Capsule()
                            .fill(JuntoColors.primary)
                            .frame(width: geo.size.width * progressFraction)
                            .animation(.easeInOut(duration: 0.25), value: step)
                    }
                }
                .frame(height: 5)

                Text("\(step.rawValue)/5")
                    .font(.inter(12, weight: .semibold))
                    .foregroundColor(JuntoColors.textMuted)
                    .monospacedDigit()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    switch step {
                    // TELA 1: Nome completo
                    case .fullName:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Qual é o seu nome completo?")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Assim seus amigos e grupos vão identificar você no Juntô.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        CleanOutlineInput(
                            label: "Nome completo",
                            placeholder: "Ex: Ana Carolina Silva",
                            text: $fullNameText
                        )

                        JuntoPillButton(
                            title: "Avançar",
                            color: cleanFullName.count >= 2 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                step = .age
                            }
                        }
                        .disabled(cleanFullName.count < 2)

                    // TELA 2: Idade
                    case .age:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Qual é a sua idade?")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Informe sua idade em anos para continuar.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        CleanOutlineInput(
                            label: "Idade",
                            placeholder: "Ex: 24",
                            text: $ageText,
                            keyboardType: .numberPad
                        )
                        .onChange(of: ageText) { _, newValue in
                            let filtered = String(newValue.filter { $0.isNumber }.prefix(3))
                            if filtered != ageText { ageText = filtered }
                        }

                        if !ageText.isEmpty && !isAgeValid {
                            Text("É necessário ter pelo menos 16 anos para usar o Juntô.")
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(JuntoColors.orangeSave)
                        }

                        JuntoPillButton(
                            title: "Avançar",
                            color: isAgeValid ? JuntoColors.primary : JuntoColors.border
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                step = .phone
                            }
                        }
                        .disabled(!isAgeValid)

                    // TELA 3: Telefone (WhatsApp)
                    case .phone:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Qual é o seu WhatsApp?")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Enviaremos um código de 6 dígitos no seu WhatsApp para validar sua conta.")
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
                            let formatted = LoginView.formatLivePhone(newValue)
                            if formatted != phoneText { phoneText = formatted }
                        }

                        JuntoPillButton(
                            title: isLoading ? "Enviando código..." : "Avançar",
                            color: cleanDigits.count >= 10 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            sendOTP()
                        }
                        .disabled(cleanDigits.count < 10 || isLoading)

                    // TELA 4: Código do WhatsApp
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
                            verifyOTPAndAdvance()
                        }
                        .padding(.vertical, 6)

                        JuntoPillButton(
                            title: isLoading ? "Validando..." : "Avançar",
                            color: otpCode.count == 6 ? JuntoColors.primary : JuntoColors.border
                        ) {
                            verifyOTPAndAdvance()
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
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)

                    // TELA 5: Foto opcional (se não escolher, mantém avatar padrão) + Nome abaixo + Avançar para o Início
                    case .photo:
                        VStack(spacing: 24) {
                            VStack(spacing: 6) {
                                Text("Escolha sua foto")
                                    .font(.inter(26, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("Opcional — se preferir, pode continuar com este avatar.")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 24)

                            VStack(spacing: 14) {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    ZStack(alignment: .bottomTrailing) {
                                        GeometricAvatarView(
                                            seed: store.user.username.isEmpty ? cleanFullName : store.user.username,
                                            displayName: cleanFullName,
                                            avatarData: avatarData,
                                            size: 120
                                        )

                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 34, height: 34)
                                            .background(JuntoColors.primary)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                                    }
                                }
                                .onChange(of: selectedPhotoItem) { _, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            avatarData = data
                                        }
                                    }
                                }

                                // Nome do usuário logo abaixo da foto/avatar
                                Text(cleanFullName)
                                    .font(.inter(20, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                    .multilineTextAlignment(.center)

                                if avatarData != nil {
                                    Button("Usar avatar padrão") {
                                        avatarData = nil
                                        selectedPhotoItem = nil
                                    }
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.textMuted)
                                } else {
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        Text("Adicionar foto (opcional)")
                                            .font(.inter(14, weight: .semibold))
                                            .foregroundColor(JuntoColors.primary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)

                            JuntoPillButton(title: "Avançar", color: JuntoColors.primary) {
                                finishRegistrationAndEnterApp()
                            }
                            .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity)
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

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .fullName:
                store.route = .welcomeAuth
            case .age:
                step = .fullName
            case .phone:
                step = .age
            case .otp:
                otpCode = ""
                step = .phone
            case .photo:
                break
            }
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

    private func verifyOTPAndAdvance() {
        guard otpCode.count == 6, !isLoading else { return }
        isLoading = true

        Task {
            let outcome = await store.loginWithWhatsAppOTP(
                phone: cleanDigits,
                code: otpCode,
                fullName: cleanFullName,
                age: parsedAge,
                autoNavigate: false
            )
            isLoading = false
            if outcome.success {
                resendTimer?.invalidate()
                withAnimation(.easeInOut(duration: 0.22)) {
                    step = .photo
                }
            } else if let err = outcome.errorMessage {
                otpCode = ""
                store.showToast(err, icon: "exclamationmark.circle")
            }
        }
    }

    private func finishRegistrationAndEnterApp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let data = avatarData {
            store.user.avatarData = data
        }
        store.user.fullName = cleanFullName
        if let age = parsedAge {
            store.user.age = age
        }
        store.saveUserSession()
        withAnimation(.easeInOut(duration: 0.25)) {
            store.selectedTab = .friends
            store.route = .main
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
