import SwiftUI

/// Cadastro moderno: 1 campo por tela (5 passos limpos e rápidos, sem campo de moeda BRL)
struct RegisterFlowView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var step: Int = 1
    private let totalSteps = 5

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
                    stepTitle("Qual é o seu e-mail?", subtitle: "Usaremos para proteger sua conta e enviar recibos.")
                    CleanOutlineInput(
                        label: "Endereço de e-mail",
                        placeholder: "ex: jose.carlos@gmail.com",
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
                            TextField("ex: jose.carlos", text: $store.draftUsername)
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
                        placeholder: "ex: José Carlos Queiroz",
                        text: $store.draftFullName
                    )

                default:
                    stepTitle("Qual é o seu telefone?", subtitle: "Facilita encontrar amigos e receber alertas de Pix.")
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Telefone")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        HStack(spacing: 10) {
                            Menu {
                                ForEach(CountryOption.all) { country in
                                    Button {
                                        store.draftCountry = country
                                    } label: {
                                        Text("\(country.flag) \(country.name) (\(country.dialCode))")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(store.draftCountry.flag)
                                        .font(.system(size: 19))
                                    Text(store.draftCountry.dialCode)
                                        .font(.inter(15, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(JuntoColors.inputBorder, lineWidth: 1)
                                )
                            }

                            TextField("(84) 98834-1068", text: $store.draftPhone)
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

        default:
            guard store.draftPhone.filter({ $0.isNumber }).count >= 10 else {
                store.showToast("Digite um telefone válido com DDD.", icon: "phone")
                return
            }
            store.completeRegistration()
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
