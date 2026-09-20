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
                
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    // Background Image with the Achou logo and illustrations
                    Image("splash_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30 * scale) { // Exact gap from the image
                        NavigationLink(destination: LoginView()) {
                            Text("Iniciar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 140 * scale) // Exact height of the drawn shape
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Cadastro")
                                .font(.headline)
                                .foregroundColor(Theme.primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 140 * scale) // Exact height of the drawn shape
                        
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Esqueceu a senha?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    // The center of the entire button group in the image is roughly at y=1700
                    .position(x: geo.size.width / 2, y: topOffset + (1700 * scale))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
