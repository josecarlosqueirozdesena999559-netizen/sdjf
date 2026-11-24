import SwiftUI

/// Tela "Próximos" — Pessoas próximas em carrossel horizontal superior e grupos públicos em lista inferior
struct NearbyView: View {
    @EnvironmentObject var store: JuntoStore
    @StateObject private var locationManager = LocationManager.shared

    @State private var searchText: String = ""
    @State private var selectedGroupForDetail: RoleGroup? = nil
    @State private var selectedUserForProfile: NearbyUserItem? = nil

    private var filteredNearbyPeople: [NearbyUserItem] {
        if searchText.isEmpty {
            return store.nearbyUsers
        }
        let clean = searchText.lowercased()
        return store.nearbyUsers.filter {
            $0.name.lowercased().contains(clean) ||
            $0.username.lowercased().contains(clean) ||
            $0.neighborhood.lowercased().contains(clean)
        }
    }

    private var activePublicGroups: [RoleGroup] {
        let list = store.groups.filter { $0.isPublicActive }
        if searchText.isEmpty {
            return list
        }
        let clean = searchText.lowercased()
        return list.filter {
            $0.title.lowercased().contains(clean) ||
            $0.category.lowercased().contains(clean) ||
            $0.locationText.lowercased().contains(clean)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho nativo com geolocalização real
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Próximos")
                        .font(.inter(24, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Spacer()

                    // Indicador de localização real
                    Button {
                        locationManager.requestAuthorization()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                                .foregroundColor(JuntoColors.primary)
                            Text(locationManager.displayLocationText.isEmpty || locationManager.displayLocationText == "Localizando..." ? "Próximo a você • 5 km" : "\(locationManager.currentCity) • 5 km")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Capsule())
                    }
                }

                // Campo de busca fluido unificado
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(JuntoColors.textLight)

                    TextField("Buscar pessoas ou grupos por nome ou região...", text: $searchText)
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(JuntoColors.textLight)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(JuntoColors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            // Conteúdo integrado: Pessoas em cima (carrossel horizontal) e Grupos embaixo (lista)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // SEÇÃO 1: Pessoas Próximas (Carrossel Horizontal)
                    peopleHorizontalSection

                    Divider().padding(.horizontal, 20).opacity(0.5)

                    // SEÇÃO 2: Grupos Públicos por Perto (Lista Vertical)
                    groupsVerticalSection

                    Spacer().frame(height: 120)
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
        .sheet(item: $selectedGroupForDetail) { group in
            PublicGroupDetailSheet(group: group)
                .environmentObject(store)
                .presentationDetents([.fraction(0.52)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .sheet(item: $selectedUserForProfile) { person in
            NearbyUserProfileSheet(person: person)
                .environmentObject(store)
                .presentationDetents([.fraction(0.44)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }

    // MARK: - Seção Superior: Pessoas Próximas Rolando ao Lado
    private var peopleHorizontalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pessoas próximas")
                    .font(.inter(16, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Text("\(filteredNearbyPeople.count)")
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            if filteredNearbyPeople.isEmpty {
                Text("Nenhuma pessoa encontrada por perto")
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredNearbyPeople) { person in
                            nearbyPersonCard(person)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // Card vertical de cada pessoa próxima no carrossel
    private func nearbyPersonCard(_ person: NearbyUserItem) -> some View {
        VStack(spacing: 8) {
            Button {
                selectedUserForProfile = person
            } label: {
                GeometricAvatarView(seed: person.username, displayName: person.name, size: 54)
            }

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(person.name)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)
                    VerifiedBadgeView(type: person.proPlanType, size: 12)
                }

                Text("@\(person.username)")
                    .font(.inter(11, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .lineLimit(1)

                Text(person.distanceText)
                    .font(.inter(11, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 4)

            // Botão Adicionar / Enviado (toque desfaz o convite)
            Button {
                withAnimation {
                    store.addNearbyUserAsFriend(userItem: person)
                }
            } label: {
                if person.isInvited {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Enviado")
                            .font(.inter(11, weight: .medium))
                    }
                    .foregroundColor(JuntoColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Adicionar")
                            .font(.inter(11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(JuntoColors.primary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .frame(width: 140, height: 180)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JuntoColors.border.opacity(0.8), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Seção Inferior: Grupos Públicos em Lista
    private var groupsVerticalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Grupos públicos por perto")
                    .font(.inter(16, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Text("\(activePublicGroups.count)")
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            if activePublicGroups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(JuntoColors.textLight)
                        .padding(.top, 16)

                    Text("Nenhum grupo público na sua região")
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Crie seu próprio grupo para dividir despesas!")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 12) {
                    ForEach(activePublicGroups) { group in
                        publicGroupCard(group)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func publicGroupCard(_ group: RoleGroup) -> some View {
        let isAlreadyMember = group.participants.contains { $0.username.lowercased() == store.user.username.lowercased() }
        let quota = group.dynamicQuotaPerPerson
        let remaining = group.remainingSlots

        return Button {
            selectedGroupForDetail = group
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Group {
                        if let data = group.coverImageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg).resizable().scaledToFill()
                        } else {
                            Image(group.coverImageName).resizable().scaledToFill()
                        }
                    }
                    .frame(width: 52, height: 52)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.title)
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(group.category)
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)

                            Text("•")
                                .font(.inter(10, weight: .regular))
                                .foregroundColor(JuntoColors.textLight)

                            Text(group.locationText)
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                    }

                    Spacer()

                    // Preço da cota por pessoa
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(JuntoStore.formatBRL(quota))
                            .font(.inter(14, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)

                        Text("por pessoa")
                            .font(.inter(10, weight: .regular))
                            .foregroundColor(JuntoColors.textLight)
                    }
                }

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 11))
                            .foregroundColor(JuntoColors.textMuted)
                        Text("\(group.participants.count) membros • \(remaining) vagas livres")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    Spacer()

                    if isAlreadyMember {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Você está dentro")
                                .font(.inter(11, weight: .medium))
                        }
                        .foregroundColor(JuntoColors.pixGreen)
                    } else {
                        HStack(spacing: 4) {
                            Text("Entrar")
                                .font(.inter(12, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(JuntoColors.primary)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(JuntoColors.border.opacity(0.8), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modal Nativo de Perfil de Usuário Próximo (SEM estilo glass, 100% nativo iOS)
struct NearbyUserProfileSheet: View {
    let person: NearbyUserItem
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                // Topo limpo com botão fechar
                HStack {
                    Text("Perfil")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .frame(width: 32, height: 32)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                GeometricAvatarView(seed: person.username, displayName: person.name, size: 68)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(person.name)
                            .font(.inter(18, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        VerifiedBadgeView(type: person.proPlanType, size: 16)
                    }

                    Text("@\(person.username)")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text("\(person.neighborhood) • Aprox. \(person.distanceText) de você")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .padding(.top, 2)
                }

                Spacer()

                if person.isInvited {
                    Button {
                        withAnimation {
                            store.addNearbyUserAsFriend(userItem: person)
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Convite enviado • Toque para cancelar")
                        }
                        .font(.inter(13, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    JuntoPillButton(title: "Adicionar aos amigos", icon: "person.badge.plus") {
                        store.addNearbyUserAsFriend(userItem: person)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Modal Nativo de Detalhes de Grupo Público (SEM textos explicativos poluídos)
struct PublicGroupDetailSheet: View {
    let group: RoleGroup
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Grupo Público")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .frame(width: 32, height: 32)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Capa ampla do grupo (sem cortes)
                Group {
                    if let data = group.coverImageData, let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(group.coverImageName)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 3) {
                    Text(group.title)
                        .font(.inter(18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("\(group.category) • \(group.locationText)")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Vagas preenchidas")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Spacer()
                        Text("\(group.participants.count) de \(group.maxParticipants)")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }

                    HStack {
                        Text("Cota por pessoa")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Spacer()
                        Text(JuntoStore.formatBRL(group.dynamicQuotaPerPerson))
                            .font(.inter(14, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                    }
                }
                .padding(14)
                .background(JuntoColors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer()

                let isAlreadyMember = group.participants.contains { $0.username.lowercased() == store.user.username.lowercased() }
                if isAlreadyMember {
                    Text("Você já participa deste grupo")
                        .font(.inter(13, weight: .medium))
                        .foregroundColor(JuntoColors.pixGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(JuntoColors.pixGreenLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    JuntoPillButton(title: "Entrar no grupo", icon: "arrow.right.circle") {
                        store.joinPublicGroup(groupId: group.id)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
