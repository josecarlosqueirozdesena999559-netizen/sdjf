import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case discover = "Descobrir"
    case matches = "Matches"
    case conversations = "Conversas"
    case profile = "Perfil"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .discover: return "flame.fill"
        case .matches: return "heart.fill"
        case .conversations: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
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
                    Text(tab.rawValue)
                        .font(AppTheme.Typography.subheadline())
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
    @Binding var selectedTab: MainTab

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
                        Image(systemName: tab.sfSymbol)
                            .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                        Text(tab.rawValue)
                            .font(AppTheme.Typography.micro())
                    }
                    .foregroundStyle(isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
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
