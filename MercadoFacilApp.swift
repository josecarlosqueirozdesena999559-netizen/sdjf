import SwiftUI

@main
struct MercadoFacilApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authViewModel)
                .environment(\.locale, .init(identifier: "pt_BR"))
        }
    }
}
