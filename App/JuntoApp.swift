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
                case .login:
                    LoginView()
                case .registerStep1:
                    RegisterStep1View()
                case .registerStep2:
                    RegisterStep2View()
                case .welcome:
                    WelcomeSlidesView()
                case .main:
                    MainTabView()
                }
            }
            .transition(.opacity)

            // Banner Toast Global
            if let message = store.toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: store.toastIcon)
                        .foregroundColor(JuntoColors.secondary)
                    Text(message)
                        .font(.inter(13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(JuntoColors.textMain)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .padding(.top, 12)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}
