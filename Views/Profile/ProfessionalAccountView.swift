import SwiftUI

struct ProfessionalAccountView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "briefcase.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Theme.primary)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Seja um Vendedor Profissional")
                        .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                        
                        .multilineTextAlignment(.center)
                    
                    Text("Aumente suas vendas com ferramentas exclusivas.")
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "star.fill", text: "Mais destaque nos resultados de busca")
                    FeatureRow(icon: "chart.bar.fill", text: "Relatórios e estatísticas avançadas")
                    FeatureRow(icon: "slider.horizontal.3", text: "Maior controle sobre seus anúncios")
                    FeatureRow(icon: "headphones", text: "Suporte prioritário 24/7")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                PrimaryButton(title: "Ativar conta profissional") {
                    // Action
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Conta Profissional")
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .frame(width: 30)
            Text(text)
                .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
        }
    }
}

