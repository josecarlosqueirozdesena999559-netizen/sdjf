import SwiftUI

/// Tela limpa pós-cadastro: apenas Olá, Conta criada e botão Ir ao início
struct GetStartedView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack(alignment: .bottomTrailing) {
                        GeometricAvatarView(seed: store.user.username, displayName: store.user.fullName, size: 96)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(JuntoColors.pixGreen)
                            .background(Circle().fill(Color.white).padding(2))
                    }

                    VStack(spacing: 6) {
                        Text("Olá, \(store.user.firstName)")
                            .font(.inter(26, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Conta criada")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }

                Spacer()

                JuntoPillButton(title: "Ir ao início", color: JuntoColors.primary) {
                    store.startApp(openingGroupCategory: nil)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 34)
            }
        }
    }
}
