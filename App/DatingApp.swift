import SwiftUI

@main
struct DatingApp: App {
    @StateObject private var appState = AppState()

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
            .preferredColorScheme(.light)
        }
    }
}
