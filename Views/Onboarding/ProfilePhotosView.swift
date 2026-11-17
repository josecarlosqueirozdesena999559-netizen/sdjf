import SwiftUI
import PhotosUI

struct ProfilePhotosView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showPreviewSheet: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suas fotos")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            if index < viewModel.photos.count {
                                photoSlotFilled(index: index)
                            } else {
                                photoSlotEmpty(isNextAvailable: index == viewModel.photos.count)
                            }
                        }
                    }

                    HStack {
                        Text("\(viewModel.photos.count) de 6 fotos • Mínimo 1 foto")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                        Spacer()
                    }

                    if !viewModel.photos.isEmpty {
                        SecondaryOutlineButton(title: "Pré-visualizar perfil", icon: "eye.fill") {
                            showPreviewSheet = true
                        }
                    }
                }
            }

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.canAdvanceFromPhotos
            ) {
                viewModel.goToNextStep()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .onChange(of: viewModel.selectedPickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                await viewModel.loadPickedPhotos(items)
            }
        }
        .sheet(isPresented: $showPreviewSheet) {
            ProfilePreviewSheet(
                fullName: viewModel.fullName.isEmpty ? "Seu Nome" : viewModel.fullName,
                photos: viewModel.photos,
                interests: viewModel.selectedInterests,
                bio: viewModel.bio
            )
        }
    }

    private func photoSlotFilled(index: Int) -> some View {
        let photo = viewModel.photos[index]
        return ZStack(alignment: .topTrailing) {
            PhotoContentView(photo: photo)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                        .strokeBorder(index == 0 ? AppTheme.Colors.primaryRed : AppTheme.Colors.borderSubtle, lineWidth: index == 0 ? 2 : 1)
                )

            Button {
                viewModel.removePhoto(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.65), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .accessibilityLabel("Excluir foto")

            VStack {
                Spacer()
                HStack(spacing: 4) {
                    if index == 0 {
                        Text("Principal")
                            .font(AppTheme.Typography.micro())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.primaryRed, in: Capsule())
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                viewModel.setAsMainPhoto(at: index)
                            }
                        } label: {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Definir como foto principal")
                    }

                    Spacer()

                    if index > 0 {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                viewModel.movePhotoLeft(at: index)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mover foto para a esquerda")
                    }

                    if index < viewModel.photos.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                viewModel.movePhotoRight(at: index)
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mover foto para a direita")
                    }
                }
                .padding(6)
            }
        }
        .frame(height: 150)
    }

    private func photoSlotEmpty(isNextAvailable: Bool) -> some View {
        let maxSelect = max(1, 6 - viewModel.photos.count)
        return PhotosPicker(
            selection: $viewModel.selectedPickerItems,
            maxSelectionCount: maxSelect,
            matching: .images
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .fill(AppTheme.Colors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .strokeBorder(
                                isNextAvailable ? AppTheme.Colors.primaryRed.opacity(0.45) : AppTheme.Colors.borderSubtle,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isNextAvailable ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
            }
            .frame(height: 150)
        }
        .buttonStyle(.plain)
    }
}

struct ProfilePreviewSheet: View {
    let fullName: String
    let photos: [ProfilePhoto]
    let interests: [Interest]
    let bio: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    PhotoGalleryView(photos: photos, enableSwipeGesture: true)

                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.75)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(fullName.split(separator: " ").first.map(String.init) ?? fullName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)

                        if !bio.isEmpty {
                            Text(bio)
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(Color.white.opacity(0.9))
                                .lineLimit(2)
                        }
                    }
                    .padding(18)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
                .padding(.horizontal, AppTheme.Spacing.lg)

                Text("Toque nas laterais ou deslize para navegar entre as fotos.")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)

                Spacer()
            }
            .padding(.top, 12)
            .background(AppTheme.Colors.background)
            .navigationTitle("Pré-visualização")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }
}
