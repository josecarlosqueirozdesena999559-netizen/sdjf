import SwiftUI

struct GroupsRoleView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showCreateGroup = false
    @State private var selectedGroup: RoleGroup? = nil
    @State private var searchText = ""
    @State private var showSearch = false

    private var filteredGroups: [RoleGroup] {
        if searchText.isEmpty { return store.groups }
        return store.groups.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo limpo: Lupa à esquerda, pílula "Criar grupo" à direita
            HStack {
                CircleNavButton(icon: "magnifyingglass") {
                    withAnimation { showSearch.toggle() }
                }
                Spacer()
                Button {
                    showCreateGroup = true
                } label: {
                    Text("Criar grupo")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .overlay(Capsule().stroke(JuntoColors.border.opacity(0.6), lineWidth: 0.6))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 14)

            Divider().opacity(0.5)

            if showSearch {
                CleanOutlineInput(label: "", placeholder: "Buscar grupo", text: $searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Grupos")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 12)

                    ForEach(filteredGroups) { group in
                        Button {
                            selectedGroup = group
                        } label: {
                            HStack(spacing: 14) {
                                Image(group.coverImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 58, height: 58)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.title)
                                        .font(.inter(16, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)

                                    if group.hasCollectivePot {
                                        Text("Pote Coletivo: \(JuntoStore.formatBRL(group.potBalance))")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.primary)
                                    } else {
                                        Text(group.category)
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    if group.myShare > 0 {
                                        Text("Sua parte: \(JuntoStore.formatBRL(group.myShare))")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.orangeSave)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }

                        Divider().padding(.leading, 92)
                    }
                }
                .padding(.bottom, 140)
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showCreateGroup) {
            CreateGroupScreen(initialType: store.openCreateGroupWithCategory ?? "Viagem")
                .environmentObject(store)
                .onDisappear {
                    store.openCreateGroupWithCategory = nil
                }
        }
        .onAppear {
            if store.openCreateGroupWithCategory != nil {
                showCreateGroup = true
            }
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailSheet(group: group)
                .environmentObject(store)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Tela "Criar um grupo" EXATAMENTE igual à screenshot 18.25.26
struct CreateGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialType: String = "Viagem"
    @State private var groupName: String = ""
    @State private var selectedType: String = "Viagem"
    @State private var enableCollectivePot: Bool = true

    private let types: [(name: String, icon: String)] = [
        ("Viagem", "airplane"),
        ("Casa", "house"),
        ("Casal", "heart"),
        ("Outros", "list.bullet.rectangle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: X circular branco | "Criar um grupo" | ✓ circular verde esmeralda
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Criar um grupo")
                    .font(.inter(17, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    store.createNewGroup(title: groupName, category: selectedType, hasPot: enableCollectivePot)
                    dismiss()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)

            // Caixa tracejada de foto + Campo "Nome do grupo" com linha inferior verde esmeralda
            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(JuntoColors.surfaceSubtle)
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundColor(JuntoColors.textLight)
                    )
                    .overlay(
                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome do grupo")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    TextField("", text: $groupName)
                        .font(.inter(16, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)

                    Rectangle()
                        .fill(JuntoColors.primary)
                        .frame(height: 1.5)
                }
            }
            .padding(.horizontal, 20)

            // Seção Tipo (4 cards quadrados brancos limpos com ícones finos)
            VStack(alignment: .leading, spacing: 14) {
                Text("Tipo")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                HStack(spacing: 10) {
                    ForEach(types, id: \.name) { item in
                        let isSelected = selectedType == item.name
                        Button {
                            selectedType = item.name
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                                Text(item.name)
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 82)
                            .background(isSelected ? JuntoColors.primaryLight.opacity(0.55) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 1.3 : 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)

            // Nosso Diferencial integrado com a mesma leveza minimalista
            Toggle(isOn: $enableCollectivePot) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ativar Pote Coletivo (Pix)")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Reúna o saldo antes do rolê e devolva a sobra por Pix.")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .tint(JuntoColors.primary)
            .padding(.horizontal, 20)
            .padding(.top, 28)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            selectedType = initialType
        }
    }
}

// MARK: - Detalhe do Grupo (Pote Coletivo + Comanda IA + Pix)
struct GroupDetailSheet: View {
    @EnvironmentObject var store: JuntoStore
    @State var group: RoleGroup
    @Environment(\.dismiss) private var dismiss

    private var selectedTotal: Double {
        group.comandaItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    CircleNavButton(icon: "xmark") { dismiss() }
                    Spacer()
                    Text(group.title)
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.top, 16)

                Image(group.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                if group.hasCollectivePot {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Pote Coletivo")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Text(JuntoStore.formatBRL(group.potBalance))
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.primary)
                        }

                        HStack(spacing: 10) {
                            JuntoPillButton(title: "Recarregar Pix", color: JuntoColors.primary) {
                                dismiss()
                                store.openPixPayment(title: "Pote • \(group.title)", recipient: "Pote Juntô", amount: 50.00)
                            }
                            Button("Devolver sobra") {
                                store.refundPotRemainder(for: group.id)
                                dismiss()
                            }
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(JuntoColors.primaryLight)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    .background(JuntoColors.surfaceSubtle)
                    .cornerRadius(14)
                }

                if !group.comandaItems.isEmpty {
                    Text("Comanda Inteligente (selecione o que consumiu)")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    VStack(spacing: 0) {
                        ForEach($group.comandaItems) { $item in
                            Button {
                                item.isSelected.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 19, weight: .regular))
                                        .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.inter(14, weight: .regular))
                                            .foregroundColor(JuntoColors.textMain)
                                        Text(item.detail)
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                    Spacer()
                                    Text(JuntoStore.formatBRL(item.price))
                                        .font(.inter(14, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                }
                                .padding(.vertical, 12)
                            }
                            Divider()
                        }
                    }

                    JuntoPillButton(title: "Pagar \(JuntoStore.formatBRL(selectedTotal)) via Pix", color: JuntoColors.primary) {
                        dismiss()
                        store.openPixPayment(title: group.title, recipient: group.title, amount: selectedTotal)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white)
    }
}
