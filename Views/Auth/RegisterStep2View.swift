import SwiftUI

struct RegisterStep2View: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            AnimatedRoleBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Header Passo 2
                    HStack {
                        Button {
                            withAnimation { store.route = .registerStep1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                                .cornerRadius(10)
                        }

                        Spacer()

                        Text("Passo 2 de 2")
                            .font(.inter(12, weight: .bold))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(JuntoColors.primaryLight)
                            .cornerRadius(8)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quase lá!\nFinalize seu perfil.")
                            .font(.inter(26, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Informe seu nome e número para receber os reembolsos do rolê via Pix.")
                            .font(.inter(14))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // Card Claro Flat
                    VStack(spacing: 16) {
                        FlatInputField(
                            label: "Nome completo",
                            placeholder: "Ex: Lucas Ferreira Silva",
                            text: $store.draftFullName
                        )

                        // País + Bandeira do Brasil + DDI + Telefone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("País e Telefone")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)

                            HStack(spacing: 8) {
                                Menu {
                                    ForEach(CountryOption.all) { country in
                                        Button {
                                            store.draftCountry = country
                                        } label: {
                                            Text("\(country.flag) \(country.name) (\(country.dialCode))")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(store.draftCountry.flag)
                                            .font(.system(size: 20))
                                        Text(store.draftCountry.dialCode)
                                            .font(.inter(14, weight: .bold))
                                            .foregroundColor(JuntoColors.textMain)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 48)
                                    .background(JuntoColors.bgMain)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(JuntoColors.border, lineWidth: 1.2)
                                    )
                                    .cornerRadius(8)
                                }

                                TextField("(11) 98765-4321", text: $store.draftPhone)
                                    .font(.inter(14, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .keyboardType(.phonePad)
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(JuntoColors.bgMain)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(JuntoColors.border, lineWidth: 1.2)
                                    )
                                    .cornerRadius(8)
                                    .onChange(of: store.draftPhone) { _, newValue in
                                        store.draftPhone = formatBrazilianPhone(newValue)
                                    }
                            }
                        }

                        // Moeda Fixa: Apenas BRL
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Moeda do aplicativo")
                                    .font(.inter(12, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMuted)
                                Text("Divisões exclusivas em Real")
                                    .font(.inter(11))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Text("🇧🇷")
                                Text("BRL (R$)")
                                    .font(.inter(13, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(JuntoColors.border, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .padding(14)
                        .background(JuntoColors.surfaceSubtle)
                        .cornerRadius(10)

                        JuntoPrimaryButton(title: "Concluir Cadastro", icon: "checkmark") {
                            store.completeRegistration()
                        }
                        .padding(.top, 6)
                    }
                    .padding(22)
                    .background(JuntoColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(JuntoColors.border, lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
    }

    private func formatBrazilianPhone(_ raw: String) -> String {
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
