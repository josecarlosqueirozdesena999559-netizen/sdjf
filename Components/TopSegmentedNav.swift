import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case discover = "Descobrir"
    case seeAgain = "Veja Novamente"
    case matches = "Matches"
    case conversations = "Conversas"
    case profile = "Perfil"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .discover: return "flame.fill"
        case .seeAgain: return "arrow.counterclockwise.circle.fill"
        case .matches: return "heart.fill"
        case .conversations: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }

    var topBarSymbol: String {
        switch self {
        case .discover: return "flame.fill"
        case .seeAgain: return "arrow.counterclockwise"
        case .matches: return "heart"
        case .conversations: return "bubble.left"
        case .profile: return "person"
        }
    }

    static var topTabs: [MainTab] {
        [.discover, .matches, .conversations]
    }
}

struct TopSegmentedNav: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MainTab.topTabs) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.topBarSymbol)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(AppTheme.Typography.subheadline())
                    }
                    .foregroundStyle(isSelected ? AppTheme.Colors.white : AppTheme.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(AppTheme.Colors.primaryRed)
                                .shadow(color: AppTheme.Colors.primaryRed.opacity(0.25), radius: 8, x: 0, y: 4)
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FloatingTabBar: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: MainTab

    private var totalUnreadMessages: Int {
        appState.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.sfSymbol)
                                .font(.system(size: 19, weight: isSelected ? .semibold : .regular))

                            if tab == .conversations && totalUnreadMessages > 0 {
                                Text("\(min(totalUnreadMessages, 99))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(AppTheme.Colors.primaryRed, in: Capsule())
                                    .offset(x: 10, y: -6)
                            }
                        }
                        Text(tab.rawValue)
                            .font(AppTheme.Typography.micro())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Capsule()
                            .fill(isSelected ? AppTheme.Colors.primaryRed : Color.clear)
                            .frame(width: 24, height: 2.5)
                    }
                    .foregroundStyle(isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .glassCard(cornerRadius: 28, material: .ultraThinMaterial)
        .padding(.horizontal, 20)
    }
}
