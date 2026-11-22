import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showNotifications = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Conteúdo da aba ativa
            Group {
                switch store.selectedTab {
                case .friends:
                    FriendsView(onOpenNotifications: {
                        showNotifications = true
                        store.markAllNotificationsRead()
                    })
                case .groups:
                    GroupsRoleView()
                case .activities:
                    ActivitiesView()
                case .account:
                    AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())

            // Camada flutuante inferior: Botão "Adicionar despesa" + Tab Bar Pílula Vidro
            VStack(alignment: .trailing, spacing: 14) {
                // Botão flutuante verde pílula (exibido em Amigos, Grupos e Atividade, como no modelo)
                if store.selectedTab != .account {
                    Button {
                        store.showAddExpenseSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .font(.system(size: 16, weight: .regular))
                            Text("Adicionar despesa")
                                .font(.inter(15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(JuntoColors.primary)
                        .clipShape(Capsule())
                        .shadow(color: JuntoColors.primary.opacity(0.28), radius: 10, x: 0, y: 4)
                    }
                    .padding(.trailing, 18)
                }

                // Tab Bar Flutuante Estilo iOS Liquid Glass (Exatamente como nas screenshots)
                HStack(spacing: 2) {
                    ForEach(MainTab.allCases, id: \.rawValue) { tab in
                        let isSelected = store.selectedTab == tab
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                store.selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 3) {
                                if tab == .account {
                                    GeometricAvatarView(avatarData: store.user.avatarData, size: 22)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? JuntoColors.textMain : Color.clear, lineWidth: 1.2)
                                                .padding(-2)
                                        )
                                } else {
                                    Image(systemName: tabIconName(tab, selected: isSelected))
                                        .font(.system(size: 19, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                }

                                Text(tab.title)
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(hex: "#EAECEF") : Color.clear)
                            )
                        }
                    }
                }
                .padding(5)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.75))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.07), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $store.showAddExpenseSheet) {
            AddExpenseSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .sheet(item: $store.activePixSheet) { pixData in
            PixSheetView(data: pixData) {
                store.showToast("Código Pix copiado.", icon: "doc.on.doc")
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func tabIconName(_ tab: MainTab, selected: Bool) -> String {
        switch tab {
        case .friends: return selected ? "person.fill" : "person"
        case .groups: return selected ? "person.2.fill" : "person.2"
        case .activities: return selected ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle"
        case .account: return "person.crop.circle"
        }
    }
}

struct AddExpenseSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String = ""
    @State private var amountText: String = ""
    @State private var selectedGroupTitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Adicionar despesa")
                    .font(.inter(17, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    let numeric = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    store.addQuickExpense(description: descriptionText, amount: numeric, groupTitle: selectedGroupTitle)
                    dismiss()
                }
            }
            .padding(.top, 16)

            CleanOutlineInput(label: "Descrição", placeholder: "Ex: Jantar, Uber, Mercado", text: $descriptionText)

            CleanOutlineInput(
                label: "Valor (BRL)",
                placeholder: "0,00",
                text: $amountText,
                keyboardType: .decimalPad,
                leadingPrefix: "R$"
            )

            if !store.groups.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Grupo (opcional)")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.groups) { g in
                                let active = selectedGroupTitle == g.title
                                Button {
                                    selectedGroupTitle = active ? "" : g.title
                                } label: {
                                    Text(g.title)
                                        .font(.inter(13, weight: .regular))
                                        .foregroundColor(active ? .white : JuntoColors.textMain)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

struct NotificationsSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Notificações")
                    .font(.inter(20, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button("Fechar") { dismiss() }
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
            }
            .padding(.top, 20)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(store.notifications) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(JuntoColors.primary)
                                .frame(width: 34, height: 34)
                                .background(JuntoColors.primaryLight)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.title)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Spacer()
                                    Text(item.timeAgo)
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                                Text(item.message)
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }
                        .padding(.vertical, 12)
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}
