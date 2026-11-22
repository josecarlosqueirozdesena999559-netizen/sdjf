import SwiftUI

struct RegisterStep2View: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") {
                    withAnimation { store.route = .registerStep1 }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Seus dados")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.top, 22)

                    CleanOutlineInput(
                        label: "Nome completo",
                        placeholder: "Ex: José Carlos",
                        text: $store.draftFullName
                    )

                    // Bandeira do Brasil + código + número
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

                            TextField("(11) 98765-4321", text: $store.draftPhone)
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

                    // Moeda padrão: apenas BRL (estilo picker pill cinza claro igual ao modelo)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Moeda padrão")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        HStack {
                            Text("🇧🇷  BRL (Real Brasileiro)")
                                .font(.inter(15, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Image(systemName: "lock")
                                .font(.system(size: 12))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(JuntoColors.surfaceSubtle)
                        .overlay(
                            Capsule().stroke(JuntoColors.border, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }

                    JuntoPillButton(title: "Concluir", color: JuntoColors.primary) {
                        store.completeRegistration()
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white.ignoresSafeArea())
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
