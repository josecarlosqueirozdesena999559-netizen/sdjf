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
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authViewModel)
                .environment(\.locale, .init(identifier: "pt_BR"))
        }
    }
}
