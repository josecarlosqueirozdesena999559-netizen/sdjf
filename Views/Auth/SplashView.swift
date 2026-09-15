import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if isActive {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        } else {
            VStack {
                Spacer()
                Image(systemName: "bag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Theme.primary)
                Text("MercadoFácil")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
                    .padding(.top, 16)
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
