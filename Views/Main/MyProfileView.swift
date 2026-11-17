import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            if let user = appState.currentUser {
                VStack(alignment: .leading, spacing: 18) {
                    PhotoGalleryView(photos: user.photos, enableSwipeGesture: true)
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("\(user.fullName), \(user.age)")
                                .font(AppTheme.Typography.title())
                                .foregroundStyle(AppTheme.Colors.darkGray)

                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                            }
                        }

                        Text("@\(user.username)")
                            .font(AppTheme.Typography.subheadline())
                            .foregroundStyle(AppTheme.Colors.textGray)
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Permissões")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        permissionRow(
                            title: "Localização",
                            enabled: appState.permissionService.isLocationAuthorized
                        ) {
                            Task { _ = await appState.permissionService.requestLocationWhenInUse() }
                        }

                        permissionRow(
                            title: "Notificações",
                            enabled: appState.permissionService.isNotificationAuthorized
                        ) {
                            Task { _ = await appState.permissionService.requestNotifications() }
                        }
                    }
                    .padding(16)
                    .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))

                    SecondaryOutlineButton(title: "Reiniciar cadastro (demonstração)", icon: "arrow.counterclockwise") {
                        appState.signOut()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }

    private func permissionRow(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.subheadline())
                .foregroundStyle(AppTheme.Colors.darkGray)
            Spacer()
            if enabled {
                Text("Ativada")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.successGreen)
            } else {
                Button("Ativar", action: action)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }
        }
    }
}
