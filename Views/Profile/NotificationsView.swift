import SwiftUI

struct NotificationsView: View {
    var body: some View {
        List {
            HStack(spacing: 16) {
                Circle()
                    .fill(Theme.lightGreen)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "bell.fill").foregroundColor(Theme.primary))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bem-vindo ao Achou Marketplace!")
                        .font(.headline)
                    Text("Comece a explorar as melhores ofertas agora mesmo.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.vertical, 8)
        }
        .listStyle(PlainListStyle())
        .customBackButton()
        .navigationTitle("Notificações")
    }
}

