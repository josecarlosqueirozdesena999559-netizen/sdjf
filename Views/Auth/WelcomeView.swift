import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                // Graphics Layer (Ignores Safe Area completely to touch the very edges)
                VStack(spacing: 0) {
                    Image("splash_top")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Image("splash_bottom")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea() // Fixes white margin below the bottom wave and at the top!
                
                // Buttons Layer (Respects Safe Area)
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("Iniciar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(30)
                        }
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Cadastro")
                                .font(.headline)
                                .foregroundColor(Theme.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Theme.primary, lineWidth: 2)
                                )
                        }
                        
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Esqueceu a senha?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    // Push buttons above the bottom wave dynamically based on screen width
                    .padding(.bottom, UIScreen.main.bounds.width * 0.35)
                }
            }
        }
    }
}
