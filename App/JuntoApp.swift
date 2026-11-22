import SwiftUI

@main
struct JuntoApp: App {
    @StateObject private var store = JuntoStore()

    var body: some Scene {
        WindowGroup {
            JuntoRootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct JuntoRootView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch store.route {
                case .welcomeAuth:
                    WelcomeAuthView()
                case .login:
                    LoginView()
                case .registerStep1:
                    RegisterStep1View()
                case .registerStep2:
                    RegisterStep2View()
                case .welcomeSlides:
                    WelcomeSlidesView()
                case .main:
                    MainTabView()
                }
            }
            .transition(.opacity)

            if let message = store.toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: store.toastIcon)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)
                    Text(message)
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(JuntoColors.darkButton)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}
