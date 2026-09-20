import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image with the Achou logo and illustrations
                Image("splash_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
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
                    .padding(.bottom, 60)
                }
            }
        }
    }
}
