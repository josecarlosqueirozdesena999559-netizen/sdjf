import SwiftUI
import PhotosUI

/// Cadastro passo a passo (1 input por tela):
/// 1. Nome completo -> 2. Idade -> 3. Telefone (valida se já tem cadastro) -> 4. Código OTP -> 5. Chave Pix (CPF/Telefone/E-mail/Aleatória com formatação e validação real) -> 6. Foto opcional -> Início
struct RegisterFlowView: View {
    @EnvironmentObject var store: JuntoStore

    enum RegisterStep: Int, CaseIterable {
        case fullName = 1
        case age = 2
        case phone = 3
        case otp = 4
        case pixKey = 5
        case photo = 6
    }

    @State private var step: RegisterStep = .fullName
    @State private var fullNameText: String = ""
    @State private var ageText: String = ""
    @State private var phoneText: String = ""
    @State private var otpCode: String = ""
    @State private var selectedPixKind: PixKeyKind = .cpf
    @State private var pixKeyText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var avatarData: Data? = nil

    @State private var isLoading: Bool = false
    @State private var phoneAlreadyRegistered: Bool = false
    @State private var phoneErrorText: String? = nil
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

    private var isPhoneValid: Bool {
        PixKeyValidator.isValidBrPhone(cleanDigits)
    }

    private var pixValidation: PixValidationResult {
        PixKeyValidator.validate(pixKeyText, kind: selectedPixKind)
    }

    private var pixKeyboardType: UIKeyboardType {
        switch selectedPixKind {
        case .cpf, .phone: return .numberPad
        case .email: return .emailAddress
        case .random: return .asciiCapable
        }
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

                Spacer().frame(width: 24)
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

                    // TELA 3: Telefone (WhatsApp — valida formato BR e se já existe cadastro)
                    case .phone:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Qual é o seu WhatsApp?")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Verificamos seu número e enviamos um código de 6 dígitos para validar sua conta.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        CleanOutlineInput(
                            label: "Número de telefone",
                            placeholder: "(11) 99999-9999",
                            text: $phoneText,
                            keyboardType: .phonePad,
                            leadingPrefix: "+55"
                        )
                        .onChange(of: phoneText) { _, newValue in
                            phoneAlreadyRegistered = false
                            phoneErrorText = nil
                            let formatted = PixKeyValidator.formatBrPhone(newValue)
                            if formatted != phoneText { phoneText = formatted }
                        }

                        if !phoneText.isEmpty && cleanDigits.count >= 10 && !isPhoneValid {
                            Text("Informe um número brasileiro válido com DDD e 9º dígito.")
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(JuntoColors.danger)
                        } else if let err = phoneErrorText {
                            Text(err)
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(phoneAlreadyRegistered ? JuntoColors.orangeSave : JuntoColors.danger)
                        }

                        if phoneAlreadyRegistered {
                            JuntoPillButton(title: "Ir para Entrar", color: JuntoColors.primary) {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    store.route = .login
                                }
                            }
                        } else {
                            JuntoPillButton(
                                title: isLoading ? "Verificando..." : "Avançar",
                                color: isPhoneValid ? JuntoColors.primary : JuntoColors.border
                            ) {
                                sendOTP()
                            }
                            .disabled(!isPhoneValid || isLoading)
                        }

                    // TELA 4: Código do WhatsApp
                    case .otp:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Código de verificação")
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
                                Button("Reenviar código") {
                                    sendOTP()
                                }
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)

                    // TELA 5: Chave Pix (CPF, Telefone, E-mail ou Aleatória com formatação e validação real)
                    case .pixKey:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                PixOfficialIcon(size: 24, color: Color(hex: "#32BCAD"))
                                Text("Sua Chave Pix")
                                    .font(.inter(26, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                            }
                            Text("Cadastre sua chave Pix para receber dos seus amigos nos grupos. Você pode alterar depois no perfil.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 20)

                        // Seletor limpo do tipo de chave Pix
                        HStack(spacing: 8) {
                            ForEach(PixKeyKind.allCases) { kind in
                                let active = selectedPixKind == kind
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        selectedPixKind = kind
                                        pixKeyText = ""
                                    }
                                } label: {
                                    Text(kind.rawValue)
                                        .font(.inter(12, weight: active ? .semibold : .regular))
                                        .foregroundColor(active ? .white : JuntoColors.textMain)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            CleanOutlineInput(
                                label: "Chave Pix (\(selectedPixKind.rawValue))",
                                placeholder: selectedPixKind.placeholder,
                                text: $pixKeyText,
                                keyboardType: pixKeyboardType,
                                leadingPrefix: selectedPixKind == .phone ? "+55" : nil
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onChange(of: pixKeyText) { _, newValue in
                                let formatted = PixKeyValidator.formatLive(newValue, kind: selectedPixKind)
                                if formatted != pixKeyText { pixKeyText = formatted }
                            }

                            if selectedPixKind == .phone && pixKeyText.isEmpty && !phoneText.isEmpty {
                                Button {
                                    pixKeyText = PixKeyValidator.formatBrPhone(phoneText)
                                } label: {
                                    Text("Usar meu telefone (+55 \(phoneText))")
                                        .font(.inter(13, weight: .semibold))
                                        .foregroundColor(JuntoColors.primary)
                                }
                                .padding(.top, 2)
                            }

                            if let err = pixValidation.errorMessage {
                                Text(err)
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.danger)
                            } else if pixValidation.isValid {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Chave \(selectedPixKind.rawValue) válida")
                                        .font(.inter(12, weight: .medium))
                                }
                                .foregroundColor(JuntoColors.pixGreen)
                            } else {
                                Text(selectedPixKind.helperText)
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }

                        JuntoPillButton(
                            title: isLoading ? "Salvando..." : "Avançar",
                            color: pixValidation.isValid ? JuntoColors.primary : JuntoColors.border
                        ) {
                            savePixKeyAndContinue()
                        }
                        .disabled(!pixValidation.isValid || isLoading)

                    // TELA 6: Foto opcional + Nome abaixo + Avançar para o Início
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
            case .pixKey:
                step = .otp
            case .photo:
                break
            }
        }
    }

    private func sendOTP() {
        guard isPhoneValid, !isLoading else { return }
        isLoading = true
        phoneAlreadyRegistered = false
        phoneErrorText = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            let result = await JuntoBackendService.shared.requestWhatsAppOTP(phone: cleanDigits, mode: "register")
            isLoading = false
            if result.ok {
                startResendCountdown()
                store.showToast("Código enviado para seu WhatsApp!", icon: "paperplane.fill")
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .otp
                }
            } else if result.isExistingUser {
                phoneAlreadyRegistered = true
                phoneErrorText = result.errorMessage ?? "Este número já possui cadastro no Juntô. Toque em Entrar."
            } else {
                phoneErrorText = result.errorMessage ?? "Não foi possível enviar o código. Verifique sua conexão."
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
                    step = .pixKey
                }
            } else if let err = outcome.errorMessage {
                otpCode = ""
                store.showToast(err, icon: "exclamationmark.circle")
            }
        }
    }

    private func savePixKeyAndContinue() {
        guard pixValidation.isValid, !isLoading else { return }
        isLoading = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let validatedKey = pixValidation.formatted
        store.user.pixKey = validatedKey
        store.saveUserSession()

        Task {
            _ = await JuntoBackendService.shared.updateProfile(pixKey: validatedKey)
            isLoading = false
            withAnimation(.easeInOut(duration: 0.22)) {
                step = .photo
            }
        }
    }

    private func finishRegistrationAndEnterApp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let data = avatarData {
            store.user.avatarData = data
        }
        store.user.fullName = cleanFullName
        if pixValidation.isValid {
            store.user.pixKey = pixValidation.formatted
        }
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
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter { $0.isNumber }.prefix(6))
                    if digits != code { code = digits }
                    if digits.count == 6 {
                        onComplete?()
                    }
                }

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let char = digitAt(index)
                    let isCurrent = index == code.count && isFocused
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isCurrent ? JuntoColors.primary : (char.isEmpty ? JuntoColors.border : JuntoColors.primary.opacity(0.55)),
                                        lineWidth: isCurrent ? 1.8 : 1.0
                                    )
                            )
                        Text(char)
                            .font(.inter(22, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func digitAt(_ index: Int) -> String {
        guard index < code.count else { return "" }
        let idx = code.index(code.startIndex, offsetBy: index)
        return String(code[idx])
    }
}
