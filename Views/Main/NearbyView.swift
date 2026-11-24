import SwiftUI

/// Tela "Próximos" — Descoberta de Pessoas Próximas e Grupos Públicos por Geolocalização
struct NearbyView: View {
    @EnvironmentObject var store: JuntoStore

    enum NearbySegment: String, CaseIterable {
        case people = "Pessoas próximas"
        case groups = "Grupos públicos"
    }

    @State private var selectedSegment: NearbySegment = .people
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

    /// Grupos públicos visíveis:
    /// 1. `isPublic == true`
    /// 2. `!isFull`: ao preencher as vagas (até 100), não aparece para entrarem; saiu um fica disponível novamente!
    /// 3. `Date() <= publicUntilDate`: não pode ter expirado o prazo definido pelo admin
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
            // Cabeçalho nativo iOS
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Próximos")
                        .font(.inter(24, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(JuntoColors.primary)
                        Text("São Paulo • 5 km")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
                }

                // Seletor segmentado nativo e fluido
                HStack(spacing: 4) {
                    ForEach(NearbySegment.allCases, id: \.self) { seg in
                        let active = selectedSegment == seg
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                selectedSegment = seg
                            }
                        } label: {
                            Text(seg.rawValue)
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(active ? JuntoColors.textMain : JuntoColors.textMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(active ? Color.white : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .shadow(color: active ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                        }
                    }
                }
                .padding(3)
                .background(JuntoColors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Campo de busca fluido
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)

                TextField(
                    selectedSegment == .people ? "Buscar pessoas por nome, bairro ou interesse..." : "Buscar grupos públicos por nome ou categoria...",
                    text: $searchText
                )
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
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            // Conteúdo principal
            ScrollView(showsIndicators: false) {
                if selectedSegment == .people {
                    peopleSection
                } else {
                    groupsSection
                }
                Spacer().frame(height: 120)
            }
        }
        .sheet(item: $selectedGroupForDetail) { group in
            PublicGroupDetailSheet(group: group)
                .environmentObject(store)
        }
        .sheet(item: $selectedUserForProfile) { person in
            NearbyUserProfileSheet(person: person)
                .environmentObject(store)
        }
    }

    // MARK: - Seção 1: Pessoas Próximas
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if filteredNearbyPeople.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(JuntoColors.textLight)
                        .padding(.top, 40)

                    Text("Ninguém encontrado por perto")
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Tente buscar por outro nome ou ajuste o filtro.")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredNearbyPeople) { person in
                        nearbyPersonRow(person)
                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
    }

    private func nearbyPersonRow(_ person: NearbyUserItem) -> some View {
        HStack(spacing: 12) {
            Button {
                selectedUserForProfile = person
            } label: {
                GeometricAvatarView(seed: person.username, displayName: person.name, size: 48)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(person.name)
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    // Selo de verificado: Roxo para Mensal, Dourado para Anual
                    VerifiedBadgeView(type: person.proPlanType, size: 14)
                }

                HStack(spacing: 6) {
                    Text("@\(person.username)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text("•")
                        .font(.inter(10, weight: .regular))
                        .foregroundColor(JuntoColors.textLight)

                    Text("\(person.neighborhood) (\(person.distanceText))")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }

            Spacer(minLength: 8)

            // Botão "+ Adicionar" / "Enviado" (toque desfaz o convite)
            Button {
                withAnimation {
                    store.addNearbyUserAsFriend(userItem: person)
                }
            } label: {
                if person.isInvited {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Enviado")
                            .font(.inter(12, weight: .medium))
                    }
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Adicionar")
                            .font(.inter(12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(JuntoColors.primary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Seção 2: Grupos Públicos
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Nota informativa limpa estilo Apple
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
                    .padding(.top, 1)

                Text("Grupos públicos têm limite de até 100 pessoas e as cotas são recalculadas dinamicamente a cada novo membro. Ao atingir o limite, o grupo deixa de aparecer até abrir vaga.")
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if activePublicGroups.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(JuntoColors.textLight)
                        .padding(.top, 36)

                    Text("Nenhum grupo público disponível")
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Grupos cheios ou expirados saem automaticamente da lista. Se alguém sair, voltam a ficar disponíveis.")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(group.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(group.title)
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .lineLimit(1)

                        Spacer()

                        Text(group.category)
                            .font(.inter(11, weight: .medium))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                                .foregroundColor(JuntoColors.textMuted)
                            Text("\(group.participants.count)/\(group.maxParticipants) pessoas")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }

                        Text("•")
                            .font(.inter(10, weight: .regular))
                            .foregroundColor(JuntoColors.textLight)

                        Text("\(remaining) vaga\(remaining == 1 ? "" : "s") restante\(remaining == 1 ? "" : "s")")
                            .font(.inter(12, weight: .medium))
                            .foregroundColor(remaining <= 3 ? JuntoColors.orangeSave : JuntoColors.pixGreen)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(JuntoColors.textLight)
                        Text("Fica no ar até \(formatDate(group.publicUntilDate))")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.textLight)
                    }
                }
            }

            Divider()

            // Linha financeira com cota recalculada dinamicamente
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cota estimada por pessoa")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    if group.potMode == .monthly {
                        Text("\(JuntoStore.formatBRL(quota))/mês (\(group.totalMonths) meses)")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    } else {
                        Text(JuntoStore.formatBRL(quota))
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }

                    Text("Recalcula automaticamente a cada entrada")
                        .font(.inter(10, weight: .regular))
                        .foregroundColor(JuntoColors.textLight)
                }

                Spacer()

                if isAlreadyMember {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(JuntoColors.pixGreen)
                        Text("Participando")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
                } else {
                    Button {
                        withAnimation {
                            store.joinPublicGroup(groupId: group.id)
                        }
                    } label: {
                        Text("Entrar no grupo")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(JuntoColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(JuntoColors.border, lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd 'de' MMM"
        return f.string(from: date)
    }
}

// MARK: - Modal de Perfil de Usuário Próximo
struct NearbyUserProfileSheet: View {
    let person: NearbyUserItem
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 32, height: 32)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            GeometricAvatarView(seed: person.username, displayName: person.name, size: 72)

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
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                JuntoPillButton(title: "Adicionar aos amigos", icon: "person.badge.plus") {
                    store.addNearbyUserAsFriend(userItem: person)
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .presentationDetents([.fraction(0.42)])
    }
}

// MARK: - Modal de Detalhe de Grupo Público
struct PublicGroupDetailSheet: View {
    let group: RoleGroup
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 32, height: 32)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            Image(group.coverImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 4) {
                Text(group.title)
                    .font(.inter(18, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Text("\(group.category) • Limite de \(group.maxParticipants) pessoas")
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
                    Text("Cota recalculada")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Spacer()
                    Text(JuntoStore.formatBRL(group.dynamicQuotaPerPerson))
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.primary)
                }
            }
            .padding(14)
            .background(JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            JuntoPillButton(title: "Entrar no grupo", icon: "arrow.right.circle") {
                store.joinPublicGroup(groupId: group.id)
                dismiss()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .presentationDetents([.fraction(0.55)])
    }
}
