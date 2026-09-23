import SwiftUI
import OneSignalFramework

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        OneSignal.initialize("13a04eb5-9922-4a12-a4f6-fcb2b8d412f2", withLaunchOptions: launchOptions)
        
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        
        return true
    }
}

@main
struct MercadoFacilApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Remove text from back button globally (leaving only the arrow)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authViewModel)
                .environment(\.locale, .init(identifier: "pt_BR"))
                .environment(\.font, .custom("Inter-Regular", size: 16, relativeTo: .body))
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                authViewModel.updatePresence(isOnline: true)
            } else if newPhase == .background {
                authViewModel.updatePresence(isOnline: false)
            }
        }
    }
}
