import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showNotifications = false
    @State private var homeButtonsCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Conteúdo da aba ativa
            Group {
                switch store.selectedTab {
                case .friends:
                    FriendsView(
                        isButtonsCollapsed: $homeButtonsCollapsed,
                        onOpenNotifications: {
                            showNotifications = true
                            store.markAllNotificationsRead()
                        }
                    )
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

            // Tab Bar Flutuante Estilo iOS Liquid Glass
            VStack(alignment: .trailing, spacing: 12) {
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
                                    GeometricAvatarView(seed: store.user.username, displayName: store.user.fullName, avatarData: store.user.avatarData, size: 22)
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
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $store.showMyExpensesScreen) {
            MyExpensesAnalyticsScreen()
                .environmentObject(store)
        }
        .sheet(item: $store.activePixSheet) { pixData in
            PixSheetView(data: pixData) {
                store.showToast("Código Pix copiado.", icon: "doc.on.doc")
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func tabIconKind(_ tab: MainTab) -> JuntoIconKind {
        switch tab {
        case .friends:    return .tabFriends
        case .groups:     return .tabGroups
        case .activities: return .tabActivity
        case .account:    return .person
        }
    }

    private func tabIconName(_ tab: MainTab, selected: Bool) -> String {
        switch tab {
        case .friends: return selected ? "person.fill" : "person"
        case .groups: return selected ? "person.2.fill" : "person.2"
        case .activities: return selected ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
        case .account: return "person.crop.circle"
        }
    }
}

struct AddExpenseSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategory: String = "Viagem"
    @State private var selectedGroupTitle: String = ""

    private let expenseCategories = ["Viagem", "Churrasco", "Casa", "Bar & Drinks", "Outros"]

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
                    store.addQuickExpense(description: descriptionText, amount: numeric, groupTitle: selectedGroupTitle, category: selectedCategory)
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

            VStack(alignment: .leading, spacing: 7) {
                Text("Categoria")
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(expenseCategories, id: \.self) { cat in
                            let active = selectedCategory == cat
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(active ? .white : JuntoColors.textMain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

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
                        if item.isFriendRequest, let reqUser = item.requestUsername, let reqName = item.requestUserName {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    GeometricAvatarView(seed: reqUser, size: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(reqName)
                                                .font(.inter(14, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(item.timeAgo)
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(JuntoColors.textLight)
                                        }
                                        Text("@\(reqUser) quer ser seu amigo")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .lineLimit(1)
                                    }
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        withAnimation { store.acceptFriendRequest(notificationId: item.id) }
                                    } label: {
                                        Text("Aceitar")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(JuntoColors.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    Button {
                                        withAnimation { store.declineFriendRequest(notificationId: item.id) }
                                    } label: {
                                        Text("Recusar")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(JuntoColors.surfaceSubtle)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding(.leading, 56)
                            }
                            .padding(.vertical, 12)
                        } else {
                            HStack(alignment: .center, spacing: 12) {
                                if let acceptedUser = item.requestUsername {
                                    GeometricAvatarView(seed: acceptedUser, size: 40)
                                } else {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(JuntoColors.primary)
                                        .frame(width: 32, height: 32)
                                }

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
                        }
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            store.markAllNotificationsRead()
        }
    }
}
