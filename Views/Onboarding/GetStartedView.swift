import SwiftUI

/// Tela "Vamos começar!" pós-slides (igual aos 00:08 do vídeo enviado)
struct GetStartedView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            Color(hex: "#F4F8FF").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 54)

                // Ícone celebrativo minimalista
                Image(systemName: "party.popper")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(JuntoColors.primary)
                    .padding(.bottom, 22)

                Text("Vamos começar")
                    .font(.inter(28, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .padding(.bottom, 10)

                Text("O que você gostaria de fazer primeiro?")
                    .font(.inter(17, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        store.startApp(openingGroupCategory: "Viagem")
                    } label: {
                        HStack(spacing: 10) {
                            Text("✈️")
                            Text("Criar uma viagem ou rolê")
                                .font(.inter(15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(JuntoColors.primary)
                        .cornerRadius(10)
                    }

                    Button {
                        store.startApp(openingGroupCategory: "Casa")
                    } label: {
                        HStack(spacing: 10) {
                            Text("🏠")
                            Text("Organizar contas de casa")
                                .font(.inter(15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(JuntoColors.primary)
                        .cornerRadius(10)
                    }

                    Button {
                        store.startApp(openingGroupCategory: nil)
                    } label: {
                        Text("Pular configuração por enquanto")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.top, 10)
                    }
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 26)
        }
    }
}
