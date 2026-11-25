import SwiftUI
import UIKit

/// Fecha o teclado automaticamente ao tocar fora dos campos em qualquer tela, sem bloquear botões ou gestos.
final class GlobalKeyboardDismissInstaller: NSObject, UIGestureRecognizerDelegate {
    static let shared = GlobalKeyboardDismissInstaller()
    private weak var installedWindow: UIWindow?

    func installIfNeeded() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            return
        }
        guard installedWindow !== window else { return }
        installedWindow = window

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tap.cancelsTouchesInView = false
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func handleBackgroundTap() {
        installedWindow?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView || current is UIControl {
                return false
            }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

final class JuntoAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        ChatSoundManager.shared.preload()
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
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        GlobalKeyboardDismissInstaller.shared.installIfNeeded()
                    }
                }
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
