import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                // Calculate scale to match .scaledToFill() behavior
                let scale = max(geo.size.width / 1000, geo.size.height / 2000)
                let renderedHeight = 2000 * scale
                let topOffset = (geo.size.height - renderedHeight) / 2
                
                // Position the buttons exactly in the middle of the white space (y=1650 in the 2000px image)
                let buttonCenterY = topOffset + (1650 * scale)
                
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    // Background Image with the Achou logo and illustrations
                    Image("splash_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    
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
                    .position(x: geo.size.width / 2, y: buttonCenterY)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
