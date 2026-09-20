import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if isActive {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        } else {
            VStack {
                Spacer()
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
