import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Theme.background.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Image("splash_top")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width)
                        
                        Spacer(minLength: 16)
                        
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
                        
                        Spacer(minLength: 16)
                        
                        Image("splash_bottom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .ignoresSafeArea()
        }
    }
}
