import SwiftUI
import PhotosUI

struct MyProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditProfile = false
    @State private var showPremiumPaywall = false

    var body: some View {
        ScrollView {
            if let user = appState.currentUser {
                VStack(alignment: .leading, spacing: 18) {
                    PhotoGalleryView(photos: user.photos, enableSwipeGesture: true)
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("\(user.fullName), \(user.age)")
                                    .font(AppTheme.Typography.title())
                                    .foregroundStyle(AppTheme.Colors.darkGray)

                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color(hex: "3B82F6"))
                                }
                            }

                            Text("@\(user.username)")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }

                        Spacer()

                        Button {
                            showEditProfile = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Editar perfil")
                                    .font(AppTheme.Typography.subheadline())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AppTheme.Colors.primaryRed, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if !user.bio.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sobre você")
                                .font(AppTheme.Typography.headline())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Text(user.bio)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                    }

                    if !user.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Seus interesses")
                                .font(AppTheme.Typography.headline())
                                .foregroundStyle(AppTheme.Colors.darkGray)

                            FlowLayout(spacing: 8) {
                                ForEach(user.interests) { interest in
                                    InterestChip(interest: interest, isSelected: true)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                    }

                    Button {
                        showPremiumPaywall = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: Circle()
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isPremium ? "Assinatura Premium Ativa" : "Seja Premium • R$ 19,90/mês")
                                    .font(AppTheme.Typography.headline())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                                Text(appState.isPremium ? "Selo verificado e recursos de privacidade ativos" : "Selo verificado, visualização única, anti-print e mais")
                                    .font(AppTheme.Typography.caption())
                                    .foregroundStyle(AppTheme.Colors.textGray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: AppTheme.Radius.large, material: .regularMaterial)
                    }
                    .buttonStyle(.plain)

                    SecondaryOutlineButton(title: "Sair da conta", icon: "rectangle.portrait.and.arrow.right") {
                        appState.signOut()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let user = appState.currentUser {
                EditProfileSheet(user: user)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumPaywallSheet()
                .environmentObject(appState)
        }
    }
}

struct EditProfileSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String
    @State private var bio: String
    @State private var selectedInterests: [Interest]
    @State private var lookingFor: [String]
    @State private var photos: [ProfilePhoto]
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init(user: UserProfile) {
        _fullName = State(initialValue: user.fullName)
        _bio = State(initialValue: user.bio)
        _selectedInterests = State(initialValue: user.interests)
        _lookingFor = State(initialValue: user.lookingFor.isEmpty ? ["todos"] : user.lookingFor)
        _photos = State(initialValue: user.photos)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Fotos
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suas fotos")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                if index < photos.count {
                                    ZStack(alignment: .topTrailing) {
                                        PhotoContentView(photo: photos[index])
                                            .frame(height: 120)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                                    .strokeBorder(index == 0 ? AppTheme.Colors.primaryRed : AppTheme.Colors.borderSubtle, lineWidth: index == 0 ? 2 : 1)
                                            )

                                        Button {
                                            photos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 22, height: 22)
                                                .background(Color.black.opacity(0.65), in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(5)
                                    }
                                } else {
                                    PhotosPicker(
                                        selection: $selectedPickerItems,
                                        maxSelectionCount: max(1, 6 - photos.count),
                                        matching: .images
                                    ) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                                .fill(AppTheme.Colors.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                                        .strokeBorder(AppTheme.Colors.borderSubtle, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                                )
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(AppTheme.Colors.primaryRed)
                                        }
                                        .frame(height: 120)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Nome
                    MinimalTextField(
                        label: "Nome",
                        placeholder: "Seu nome",
                        text: $fullName,
                        textContentType: .name,
                        autocapitalization: .words
                    )

                    // Bio
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sobre você")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)

                        TextEditor(text: $bio)
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(height: 120)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                            .onChange(of: bio) { _, val in
                                if val.count > 300 {
                                    bio = String(val.prefix(300))
                                }
                            }

                        HStack {
                            Spacer()
                            Text("\(bio.count)/300")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                    }

                    // Quem gostaria de conhecer
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quem você gostaria de conhecer?")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        FlowLayout(spacing: 8) {
                            ForEach(GenderInterestOption.all) { option in
                                let isSelected = lookingFor.contains(option.id)
                                Button {
                                    toggleLookingFor(option.id)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: option.sfSymbol)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(option.title)
                                            .font(AppTheme.Typography.subheadline())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .foregroundStyle(isSelected ? .white : AppTheme.Colors.darkGray)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.chipUnselected)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Interesses
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Seus interesses (\(selectedInterests.count)/10)")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        FlowLayout(spacing: 8) {
                            ForEach(Interest.all) { interest in
                                let isSelected = selectedInterests.contains(interest)
                                InterestChip(interest: interest, isSelected: isSelected) {
                                    toggleInterest(interest)
                                }
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }

                    PrimaryButton(
                        title: "Salvar perfil",
                        isEnabled: Validators.isValidFullName(fullName) && selectedInterests.count >= 3 && !photos.isEmpty,
                        isLoading: isSaving
                    ) {
                        Task {
                            await saveChanges()
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.chipUnselected, in: Circle())
                    }
                }
            }
            .onChange(of: selectedPickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    let slots = max(0, 6 - photos.count)
                    for item in items.prefix(slots) {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            photos.append(ProfilePhoto(imageData: data))
                        }
                    }
                    selectedPickerItems = []
                }
            }
        }
    }

    private func toggleLookingFor(_ id: String) {
        if id == "todos" {
            lookingFor = ["todos"]
            return
        }
        lookingFor.removeAll { $0 == "todos" }
        if let idx = lookingFor.firstIndex(of: id) {
            lookingFor.remove(at: idx)
        } else {
            lookingFor.append(id)
        }
        if lookingFor.isEmpty {
            lookingFor = ["todos"]
        }
    }

    private func toggleInterest(_ interest: Interest) {
        if let idx = selectedInterests.firstIndex(of: interest) {
            selectedInterests.remove(at: idx)
        } else if selectedInterests.count < 10 {
            selectedInterests.append(interest)
        }
    }

    private func saveChanges() async {
        guard var current = appState.currentUser else { return }
        isSaving = true
        errorMessage = nil

        do {
            struct UpdateMeBody: Encodable {
                let fullName: String
            }
            try await APIClient.shared.requestVoid(
                path: "/users/me",
                method: "PUT",
                body: UpdateMeBody(fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines))
            )

            // Upload newly added local photos
            let newLocalPhotos = photos.filter { $0.remoteURL == nil && $0.imageData != nil }
            let uploadedNew = try await appState.services.storageService.uploadProfilePhotos(newLocalPhotos, userId: current.id)
            var finalPhotos = photos.filter { $0.remoteURL != nil }
            finalPhotos.append(contentsOf: uploadedNew)

            current.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            current.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            current.interests = selectedInterests
            current.lookingFor = lookingFor
            current.photos = finalPhotos

            try await appState.services.userRepository.saveProfile(current)
            appState.currentUser = current
            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }
}
