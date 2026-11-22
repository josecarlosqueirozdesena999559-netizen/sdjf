import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showNotifications = false

    var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho Fixo Flat (Olá / Que bom te ter + Avatar + Sino)
            HStack(spacing: 12) {
                userAvatarView(size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Olá, \(store.user.firstName)! 👋")
                        .font(.inter(16, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Que bom te ter aqui no Juntô")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Spacer()

                // Sino de Notificações
                Button {
                    showNotifications = true
                    store.markAllNotificationsRead()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(width: 42, height: 42)
                            .background(JuntoColors.bgMain)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(JuntoColors.border, lineWidth: 1)
                            )
                            .cornerRadius(10)

                        if store.unreadNotificationsCount > 0 {
                            Circle()
                                .fill(JuntoColors.danger)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .offset(x: -7, y: 7)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(JuntoColors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(JuntoColors.border),
                alignment: .bottom
            )

            // Conteúdo da Aba Selecionada
            ZStack {
                switch store.selectedTab {
                case .groups:
                    GroupsRoleView()
                case .friends:
                    FriendsView()
                case .activities:
                    ActivitiesView()
                case .account:
                    AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JuntoColors.bgMain)

            // Menu Inferior Flat (Grupos, Amigos, Atividades, Conta)
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.rawValue) { tab in
                    let isSelected = store.selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            store.selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: isSelected ? "\(tab.icon).fill" : tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                .symbolRenderingMode(.hierarchical)
                            Text(tab.title)
                                .font(.inter(11, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(JuntoColors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(JuntoColors.border),
                alignment: .top
            )
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .sheet(item: $store.activePixSheet) { pixData in
            PixSheetView(data: pixData) {
                store.showToast("Código Pix copiado! Pague no seu banco.", icon: "bolt.fill")
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func userAvatarView(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = store.user.avatarData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [JuntoColors.primary, Color(hex: "#7C3AED")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(store.user.avatarEmoji ?? store.user.initials)
                            .font(.inter(size * 0.38, weight: .heavy))
                            .foregroundColor(.white)
                    )
            }

            Circle()
                .fill(JuntoColors.secondary)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 2, y: 2)
        }
    }
}

struct NotificationsSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Notificações")
                    .font(.inter(18, weight: .heavy))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button("Fechar") { dismiss() }
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.primary)
            }
            .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(store.notifications) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20))
                                .foregroundColor(JuntoColors.primary)
                                .frame(width: 38, height: 38)
                                .background(JuntoColors.primaryLight)
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.title)
                                        .font(.inter(13, weight: .bold))
                                        .foregroundColor(JuntoColors.textMain)
                                    Spacer()
                                    Text(item.timeAgo)
                                        .font(.inter(11, weight: .semibold))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                                Text(item.message)
                                    .font(.inter(12))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }
                        .padding(12)
                        .background(JuntoColors.bgMain)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.surface)
    }
}
