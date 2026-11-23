import SwiftUI

/// Cadastro moderno: 1 campo por tela (6 passos incluindo conferência obrigatória da Chave Pix)
struct RegisterFlowView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var step: Int = 1
    @State private var pixKeyType: String = "CPF"
    @State private var pixConfirmed: Bool = false
    private let totalSteps = 6
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
            .padding(.bottom, 26)

            // Conteúdo de 1 campo por tela
            VStack(alignment: .leading, spacing: 20) {
                switch step {
                case 1:
                    stepTitle("Qual é o seu e-mail?", subtitle: "Ele será usado para entrar e proteger sua conta.")
                    CleanOutlineInput(
                        label: "Endereço de e-mail",
                        placeholder: "ex: voce@email.com",
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
                            TextField("ex: maria.oliveira", text: $store.draftUsername)
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
                        placeholder: "ex: Maria Oliveira",
                        text: $store.draftFullName
                    )

                case 5:
                    stepTitle("Qual é o seu telefone?", subtitle: "Facilita encontrar amigos e receber alertas de Pix.")
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Telefone")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        HStack(spacing: 10) {
                            // Somente Brasil (+55 fixo, sem seletor de outros países)
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

                default:
                    stepTitle(
                        "Cadastre sua chave Pix",
                        subtitle: "Confira com atenção: é por essa chave que você receberá os pagamentos e saques automáticos."
                    )

                    // Tipo da chave Pix
                    HStack(spacing: 8) {
                        ForEach(pixTypes, id: \.self) { type in
                            let active = pixKeyType == type
                            Button {
                                pixKeyType = type
                                if type == "E-mail" && store.draftPixKey.isEmpty {
                                    store.draftPixKey = store.draftEmail
                                } else if type == "Celular" && store.draftPixKey.isEmpty {
                                    store.draftPixKey = "+55 \(store.draftPhone)"
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

                    // Aviso visual para conferir a chave Pix
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
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(JuntoColors.warmBg)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                JuntoPillButton(title: step == totalSteps ? "Criar conta" : "Próximo", color: JuntoColors.primary) {
                    handleNext()
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 22)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.inter(24, weight: .regular))
                .foregroundColor(JuntoColors.textMain)
            Text(subtitle)
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
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
            withAnimation(.easeInOut(duration: 0.2)) { step = 6 }

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
        case "E-mail": return "voce@email.com"
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
