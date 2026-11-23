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
                case .registerFlow:
                    RegisterFlowView()
                case .welcomeSlides:
                    WelcomeSlidesView()
                case .getStarted:
                    GetStartedView()
                case .main:
                    MainTabView()
                }
            }
            .transition(.opacity)

            if let message = store.toastMessage {
                HStack(spacing: 8) {
                    toastIconView(store.toastIcon)
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

    @ViewBuilder
    private func toastIconView(_ iconName: String) -> some View {
        switch iconName {
        case "checkmark", "checkmark.circle", "checkmark.circle.fill":
            JuntoIcon(kind: .checkmark, size: 14, color: .white, weight: 2.2)
        case "doc.on.doc":
            JuntoIcon(kind: .receipt, size: 14, color: .white, weight: 1.8)
        case "camera":
            JuntoIcon(kind: .camera, size: 14, color: .white, weight: 1.8)
        case "sparkles", "sparkle":
            JuntoIcon(kind: .sparkle, size: 14, color: .white, weight: 1.8)
        default:
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
        }
    }
}
