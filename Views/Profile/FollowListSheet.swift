import SwiftUI

enum FollowListMode: String, Identifiable {
    case followers = "Seguidores"
    case following = "Seguindo"
    var id: String { rawValue }
}

struct FollowListSheet: View {
    let userId: UUID
    let mode: FollowListMode
    @Environment(\.dismiss) var dismiss
    
    @State private var users: [Profile] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if users.isEmpty {
                    VStack {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                            .padding(.bottom, 8)
                        Text(mode == .followers ? "Nenhum seguidor ainda." : "Não está seguindo ninguém.")
                            .typographyLabel()
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(users, id: \.id) { profile in
                            NavigationLink(destination: SellerProfileView(seller: Seller(id: profile.id, user: User(id: profile.id, name: profile.name, email: "", phone: "", username: profile.username, visibleName: profile.visible_name, avatarURL: profile.avatar_url, location: profile.location ?? "", memberSince: Date(), isProfessional: false), isVerified: false, rating: 0, reviewCount: 0, salesCount: 0, averageResponseTime: "", bio: ""))) {
                                HStack(spacing: 12) {
                                    if let urlString = profile.avatar_url, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(Theme.textSecondary)
                                            }
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(profile.visible_name ?? profile.name)
                                            .typographyLabel()
                                        if let username = profile.username {
                                            Text("@\(username)")
                                                .typographyCaption()
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            .task {
                await fetchUsers()
            }
        }
    }
    
    private func fetchUsers() async {
        do {
            isLoading = true
            struct FollowRow: Codable {
                let follower_id: UUID
                let following_id: UUID
            }
            let follows: [FollowRow] = try await supabase.database.from("follows")
                .select()
                .eq(mode == .followers ? "following_id" : "follower_id", value: userId)
                .execute()
                .value
            
            let ids = follows.map { mode == .followers ? $0.follower_id : $0.following_id }
            if ids.isEmpty {
                self.users = []
            } else {
                self.users = try await supabase.database.from("profiles")
                    .select()
                    .in("id", value: ids.map { $0.uuidString })
                    .execute()
                    .value
            }
        } catch {
            print("Error fetching follow list: \(error)")
        }
        isLoading = false
    }
}
