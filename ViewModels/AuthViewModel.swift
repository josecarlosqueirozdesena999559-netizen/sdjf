import Foundation
import Combine
import Supabase
import OneSignalFramework

struct Profile: Codable {
    let id: UUID
    let name: String
    let visible_name: String?
    let username: String?
    let email: String?
    let document: String?
    let location: String?
    let avatar_url: String?
    let created_at: Date?
    let rating: Double?
    let avg_response_time: String?
    let bio: String?
    let latitude: Double?
    let longitude: Double?
    let is_online: Bool?
    let last_seen: Date?
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var hasUnreadNotifications: Bool = false
    @Published var needsProfileSetup: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        LocationManager.shared.$addressString
            .compactMap { x in x }
            .sink { [weak self] newAddress in
                if let loc = LocationManager.shared.location {
                    self?.updateLocation(lat: loc.latitude, lon: loc.longitude, address: newAddress)
                }
            }
            .store(in: &cancellables)
            
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            await loadProfile(for: session.user.id, email: session.user.email ?? "")
        } catch {
            self.isAuthenticated = false
        }
    }
    
    func login(emailOrUsername: String, password: String) {
        Task {
            self.isLoading = true
            self.errorMessage = nil
            do {
                var loginEmail = emailOrUsername
                
                if !loginEmail.contains("@") || loginEmail.hasPrefix("@") {
                    let cleanUsername = loginEmail.replacingOccurrences(of: "@", with: "").lowercased().trimmingCharacters(in: .whitespaces)
                    
                    struct ProfileLookup: Codable {
                        let email: String?
                    }
                    
                    let profiles: [ProfileLookup] = try await supabase.database
                        .from("profiles")
                        .select("email")
                        .eq("username", value: cleanUsername)
                        .execute()
                        .value
                    
                    if let foundProfile = profiles.first, let foundEmail = foundProfile.email {
                        loginEmail = foundEmail
                    } else {
                        await MainActor.run {
                            self.errorMessage = "Usuário não encontrado."
                            self.isLoading = false
                        }
                        return
                    }
                }
                
                let session = try await supabase.auth.signIn(email: loginEmail, password: password)
                await loadProfile(for: session.user.id, email: session.user.email ?? loginEmail)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Falha no login: verifique suas credenciais."
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func updateLocation(lat: Double, lon: Double, address: String? = nil) {
        guard let userId = currentUser?.id else { return }
        
        Task {
            do {
                struct LocUpdate: Encodable {
                    let latitude: Double
                    let longitude: Double
                    let location: String?
                }
                let finalAddress = address ?? currentUser?.location ?? "Desconhecido"
                let update = LocUpdate(latitude: lat, longitude: lon, location: finalAddress)
                try await supabase.database.from("profiles").update(update).eq("id", value: userId.uuidString).execute()
                await MainActor.run {
                    self.currentUser?.latitude = lat
                    self.currentUser?.longitude = lon
                    if let address = address {
                        self.currentUser?.location = address
                    }
                }
            } catch {
                print("Error updating location: $error")
            }
        }
    }
    
    func updatePresence(isOnline: Bool) {
        guard let userId = currentUser?.id else { return }
        Task {
            do {
                struct PresenceUpdate: Encodable {
                    let is_online: Bool
                    let last_seen: String
                }
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let nowString = formatter.string(from: Date())
                
                let update = PresenceUpdate(is_online: isOnline, last_seen: nowString)
                try await supabase.database.from("profiles").update(update).eq("id", value: userId.uuidString).execute()
            } catch {
                print("Error updating presence: $error")
            }
        }
    }
    
    func logout() {
        Task {
            do {
                try await supabase.auth.signOut()
            } catch {
                print("Logout erro: \(error)")
            }
            OneSignal.logout()
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    private func loadProfile(for userId: UUID, email: String) async {
        do {
            let profile: Profile = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
                
            self.currentUser = User(
                id: userId,
                name: profile.name,
                cpf: profile.document ?? "",
                birthDate: nil,
                email: profile.email ?? email,
                phone: "",
                username: profile.username ?? "",
                visibleName: profile.visible_name,
                avatarURL: profile.avatar_url,
                location: profile.location ?? "Desconhecido",
                latitude: profile.latitude,
                longitude: profile.longitude,
                memberSince: profile.created_at ?? Date(),
                isProfessional: false,
                rating: profile.rating,
                responseTime: profile.avg_response_time,
                bio: profile.bio,
                isOnline: profile.is_online,
                lastSeen: profile.last_seen
            )
            self.isAuthenticated = true
            OneSignal.login(userId.uuidString)
        } catch {
            print("Erro ao carregar perfil: \(error)")
            self.currentUser = User(id: userId, name: "Usuário", cpf: "", birthDate: nil, email: email, phone: "", username: "user", visibleName: nil, avatarURL: nil, location: "Desconhecido", latitude: nil, longitude: nil, memberSince: Date(), isProfessional: false, rating: nil, responseTime: nil, bio: nil, isOnline: nil, lastSeen: nil)
            self.isAuthenticated = true
        }
        
        await checkUnreadNotifications()
        startNotifPolling()
    }
    
    private var notifTimer: Timer?
    
    func startNotifPolling() {
        notifTimer?.invalidate()
        notifTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task {
                await self?.checkUnreadNotifications()
            }
        }
    }
    
    func checkUnreadNotifications() async {
        guard let userId = self.currentUser?.id else { return }
        do {
            let count: Int = try await supabase.database
                .from("notifications")
                .select("id", head: true, count: .exact)
                .eq("user_id", value: userId)
                .eq("is_read", value: false)
                .execute()
                .count ?? 0
            
            self.hasUnreadNotifications = count > 0
        } catch {
            print("Failed to check unread notifications: \(error)")
        }
    }
}