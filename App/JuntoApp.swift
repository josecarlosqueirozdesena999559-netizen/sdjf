import SwiftUI
import UIKit

final class JuntoAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task { @MainActor in
            JuntoNotificationManager.shared.apnsDeviceToken = tokenHex
            await JuntoBackendService.shared.registerDeviceToken(tokenHex)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Silencioso no Simulador ou sem entitlement APNs; push remoto ativa automaticamente quando assinado com APNs
    }
}

@main
struct JuntoApp: App {
    @UIApplicationDelegateAdaptor(JuntoAppDelegate.self) var appDelegate
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
        .onAppear {
            JuntoNotificationManager.shared.requestAuthorization()
            LocationManager.shared.requestAuthorization()
        }
    }
}
