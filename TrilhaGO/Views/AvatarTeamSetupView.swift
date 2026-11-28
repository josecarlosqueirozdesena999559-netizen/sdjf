import SwiftUI

struct AvatarTeamSetupView: View {
    @ObservedObject var store: TrilhaGameStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 3)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#DCFCE7"),
                    TrilhaColors.surfaceGray,
                    Color(hex: "#CCFBF1")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("ESCOLHA SEU VISUAL")
                        .font(TrilhaFont.title(20))
                        .foregroundStyle(TrilhaColors.darkText)
                    Text("Você pode personalizar o avatar mais tarde.")
                        .font(TrilhaFont.body(14))
                        .foregroundStyle(TrilhaColors.mutedText)
                }
                .padding(.top, 26)

                // Seletor de Equipe
                HStack(spacing: 10) {
                    ForEach(TrilhaTeam.allCases) { team in
                        let selected = store.selectedTeam == team
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.selectedTeam = team
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(team.color)
                                    .frame(width: 10, height: 10)
                                Text(team.displayName)
                                    .font(TrilhaFont.body(13, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selected ? TrilhaColors.pureWhite : TrilhaColors.pureWhite.opacity(0.65))
                            .foregroundStyle(TrilhaColors.darkText)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selected ? team.color : TrilhaColors.border, lineWidth: selected ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Grade 3x3 circular de Avatares
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...9, id: \.self) { idx in
                        let isSelected = store.selectedAvatarId == idx
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                store.selectedAvatarId = idx
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image("avatar_\(idx)")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                                    .background(Circle().fill(TrilhaColors.pureWhite))
                                    .overlay(
                                        Circle().stroke(
                                            isSelected ? TrilhaColors.emerald : TrilhaColors.pureWhite,
                                            lineWidth: isSelected ? 4 : 3
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(TrilhaColors.emerald)
                                        .background(Circle().fill(TrilhaColors.pureWhite).padding(2))
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                EmeraldPillButton(title: "PRÓXIMO") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        store.stage = .mainMap
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 30)
            }
        }
    }
}
