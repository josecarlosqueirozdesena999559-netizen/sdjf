import SwiftUI

@main
struct TrilhaGOApp: App {
    @StateObject private var store = TrilhaGameStore()

    var body: some Scene {
        WindowGroup {
            Group {
                switch store.stage {
                case .splash:
                    SplashWelcomeView(store: store)
                case .avatarSetup:
                    AvatarTeamSetupView(store: store)
                case .mainMap:
                    MainMapView(store: store)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
