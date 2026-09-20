import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                // Graphics Layer - Top
                VStack {
                    Image("splash_top")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width)
                    
                    Spacer()
                }
                .ignoresSafeArea() // Anchors to the absolute top
                
                // Graphics Layer - Bottom
                VStack {
                    Spacer()
                    
                    Image("splash_bottom")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width)
                }
                .ignoresSafeArea() // Anchors to the absolute bottom
                
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
                    // Wave height is exactly 30% of screen width (154/512). We add 20pts of gap.
                    .padding(.bottom, UIScreen.main.bounds.width * 0.30 + 20)
                }
                .ignoresSafeArea() // Use absolute bounds so the math is perfect across all iPhones
            }
        }
    }
}
