import SwiftUI

struct AboutScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Resultados eleitorais\nmais acessíveis").font(.largeTitle.bold())
                    
                    Text("O Apurabra é um projeto independente e sem fins lucrativos, criado para ajudar as pessoas a acompanhar e compreender os resultados das Eleições 2026.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                    
                    VStack(spacing: 12) {
                        AboutCard(icon: "target", title: "Nosso objetivo", text: "Apresentar candidaturas e resultados eleitorais de maneira clara, organizada e fácil de consultar.")
                        AboutCard(icon: "doc.text.magnifyingglass", title: "Dados reais", text: "As informações exibidas são obtidas de arquivos públicos disponibilizados pelo Tribunal Superior Eleitoral.")
                        AboutCard(icon: "shield.righthalf.filled", title: "Projeto independente", text: "Este aplicativo não pertence ao TSE, a partidos, coligações ou candidaturas. Não realiza campanha nem indica voto.")
                    }
                    
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://www.instagram.com/apurabra/")!) {
                            Label("Instagram @apurabra", systemImage: "camera.macro")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.palePurple, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(AppTheme.purple)
                                .font(.headline)
                        }
                        Link(destination: URL(string: "https://dadosabertos.tse.jus.br/")!) {
                            Label("Portal de Dados Abertos do TSE", systemImage: "link")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.primary)
                                .font(.headline)
                        }
                    }
                    
                    Divider().padding(.top, 8)
                    Text("© 2026 Apurabra. Este não é um aplicativo oficial do TSE.").font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("Sobre").navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AboutCard: View {
    let icon: String, title: String, text: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.purple)
                .frame(width: 38, height: 38)
                .background(AppTheme.purple.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary).lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.palePurple.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
    }
}