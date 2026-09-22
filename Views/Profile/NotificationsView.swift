import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.custom("Inter-Regular", size: 48))
                        .foregroundColor(Theme.textSecondary)
                    Text("Nenhuma notificação por enquanto.")
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(notifications) { notification in
                        HStack(spacing: 16) {
                            Circle()
                                .fill(notification.is_read ? Theme.inputBackground : Theme.lightGreen)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: iconForType(notification.type))
                                        .foregroundColor(notification.is_read ? Theme.textSecondary : Theme.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                    .foregroundColor(notification.is_read ? Theme.textSecondary : Theme.textPrimary)
                                Text(notification.body)
                                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .onTapGesture {
                            markAsRead(notification)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .customBackButton()
        .navigationTitle("Notificações")
        .onAppear {
            fetchNotifications()
        }
        .refreshable {
            fetchNotifications()
        }
        .onDisappear {
            Task {
                await authViewModel.checkUnreadNotifications()
            }
        }
    }
    
    private func fetchNotifications() {
        Task {
            guard let userId = authViewModel.currentUser?.id else {
                isLoading = false
                return
            }
            do {
                let fetched: [AppNotification] = try await supabase.database
                    .from("notifications")
                    .select()
                    .eq("user_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.notifications = fetched
                    self.isLoading = false
                }
            } catch {
                print("Erro fetching notifications: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func markAsRead(_ notification: AppNotification) {
        guard !notification.is_read else { return }
        Task {
            do {
                try await supabase.database
                    .from("notifications")
                    .update(["is_read": true])
                    .eq("id", value: notification.id)
                    .execute()
                
                await MainActor.run {
                    if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                        notifications[idx].is_read = true
                    }
                }
            } catch {
                print("Failed to mark as read: \(error)")
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "welcome", "system": return "bell.fill"
        case "sale", "purchase": return "bag.fill"
        case "message": return "message.fill"
        default: return "bell.fill"
        }
    }
}
