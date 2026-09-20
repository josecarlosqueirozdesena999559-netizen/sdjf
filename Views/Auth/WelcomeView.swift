import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Graphic (anchored to top)
                    Image("splash_top")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                    
                    Spacer()
                    
                    // Buttons (in the middle white space)
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
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Bottom Wave (anchored to bottom)
                    Image("splash_bottom")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}
