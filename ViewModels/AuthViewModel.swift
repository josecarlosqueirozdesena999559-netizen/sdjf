import Foundation
import Combine
import Supabase

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
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    init() {
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
    
    func logout() {
        Task {
            do {
                try await supabase.auth.signOut()
            } catch {
                print("Logout erro: \(error)")
            }
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
            
            // Map to our User struct
            self.currentUser = User(
                id: profile.id,
                name: profile.name,
                cpf: profile.document,
                birthDate: nil,
                email: profile.email ?? email,
                phone: "",
                username: profile.username,
                visibleName: profile.visible_name,
                avatarURL: profile.avatar_url,
                location: profile.location ?? "Desconhecido",
                latitude: nil,
                longitude: nil,
                memberSince: profile.created_at ?? Date(),
                isProfessional: false
            )
            self.isAuthenticated = true
        } catch {
            print("Erro ao carregar perfil, talvez não exista: \(error)")
            // Fallback for demo if profile doesn't exist yet but auth succeeded
            self.currentUser = User(id: userId, name: "Usuário", cpf: "", birthDate: nil, email: email, phone: "", username: "user", visibleName: nil, avatarURL: nil, location: "Desconhecido", latitude: nil, longitude: nil, memberSince: Date(), isProfessional: false)
            self.isAuthenticated = true
        }
    }
}

