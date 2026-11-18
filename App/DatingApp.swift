import SwiftUI
import CoreText

@main
struct DatingApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.registerCustomFonts()
    }

    private static func registerCustomFonts() {
        let fontNames = [
            "PlusJakartaSans-Regular",
            "PlusJakartaSans-SemiBold",
            "PlusJakartaSans-Bold",
            "PlusJakartaSans-ExtraBold"
        ]
        for name in fontNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.route {
                case .welcome:
                    WelcomeView()
                case .login:
                    LoginView(authService: appState.services.authService)
                case .onboarding:
                    OnboardingContainerView(
                        services: appState.services,
                        permissionService: appState.permissionService
                    )
                case .main:
                    MainContainerView(
                        discoveryService: appState.services.discoveryService
                    )
                }
            }
            .environmentObject(appState)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background, .inactive:
                    appState.socketClient.disconnect()
                case .active:
                    if appState.route == .main {
                        appState.socketClient.connect()
                        Task {
                            await appState.loadSocialData()
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
