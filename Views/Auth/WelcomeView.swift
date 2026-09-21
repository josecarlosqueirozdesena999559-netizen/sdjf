import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showTermos = false
    @State private var showPrivacidade = false
    @State private var showSeguranca = false
    
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
                        
                        // Buttons moved down into the white area
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
                            
                            // Links Legais
                            HStack(spacing: 12) {
                                Button("Termos de Uso") { showTermos = true }
                                Text("•").foregroundColor(Theme.textSecondary).font(.caption)
                                Button("Privacidade") { showPrivacidade = true }
                                Text("•").foregroundColor(Theme.textSecondary).font(.caption)
                                Button("Segurança") { showSeguranca = true }
                            }
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 16)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 40)
                        
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
            .sheet(isPresented: $showTermos) {
                LegalDocumentView(title: "Termos de Uso", content: LegalTexts.termosDeUso)
            }
            .sheet(isPresented: $showPrivacidade) {
                LegalDocumentView(title: "Política de Privacidade", content: LegalTexts.privacidade)
            }
            .sheet(isPresented: $showSeguranca) {
                LegalDocumentView(title: "Segurança de Dados", content: LegalTexts.seguranca)
            }
        }
    }
}
