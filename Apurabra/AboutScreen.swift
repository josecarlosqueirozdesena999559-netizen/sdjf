import SwiftUI

struct AboutScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { Spacer(); Image("ApurabraLogo").resizable().scaledToFit().frame(width: 104, height: 104).clipShape(RoundedRectangle(cornerRadius: 24)); Spacer() }
                    Text("Resultados eleitorais mais acessíveis").font(.largeTitle.bold())
                    Text("O Apurabra é um projeto independente e sem fins lucrativos, criado para ajudar as pessoas a acompanhar e compreender os resultados das Eleições 2026.").font(.title3).foregroundStyle(.secondary)
                    AboutCard(number: "01", title: "Nosso objetivo", text: "Apresentar candidaturas e resultados eleitorais de maneira clara, organizada e fácil de consultar.")
                    AboutCard(number: "02", title: "Dados reais", text: "As informações exibidas são obtidas de arquivos públicos disponibilizados pelo Tribunal Superior Eleitoral.")
                    AboutCard(number: "03", title: "Projeto independente", text: "Este aplicativo não pertence ao TSE, a partidos, coligações ou candidaturas. Não realiza campanha nem indica voto.")
                    Link("Instagram @apurabra", destination: URL(string: "https://www.instagram.com/apurabra/")!).font(.headline)
                    Link("Portal de Dados Abertos do TSE", destination: URL(string: "https://dadosabertos.tse.jus.br/")!)
                    Divider()
                    Text("© 2026 Apurabra. Este não é um aplicativo oficial do TSE.").font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("Sobre").navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AboutCard: View {
    let number: String, title: String, text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number).font(.caption.bold()).foregroundStyle(AppTheme.purple)
            Text(title).font(.title3.bold())
            Text(text).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(AppTheme.palePurple, in: RoundedRectangle(cornerRadius: 16))
    }
}