import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showTermos = false
    @State private var showPrivacidade = false
    @State private var showSeguranca = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo / Ícone central
                    VStack(spacing: 12) {
                        Image("achei_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 72)
                        
                        Text("Compre e venda perto de você")
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, 60)
                    
                    Spacer()
                    
                    // Botões
                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("Iniciar")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(30)
                        }
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Cadastro")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
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
                                .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                                
                                .foregroundColor(Theme.primary)
                        }
                        .padding(.top, 8)
                        
                        // Links Legais
                        HStack(spacing: 8) {
                            Button("Termos de Uso") { showTermos = true }
                            Text("•").foregroundColor(Theme.textSecondary).font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                            Button("Privacidade") { showPrivacidade = true }
                            Text("•").foregroundColor(Theme.textSecondary).font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                            Button("Segurança") { showSeguranca = true }
                        }
                        .font(.custom("Inter-Medium", size: 11, relativeTo: .caption2))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
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
