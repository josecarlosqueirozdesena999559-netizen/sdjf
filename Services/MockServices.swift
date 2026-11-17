import Foundation

final class MockAuthService: AuthServiceProtocol {
    private let takenUsernames: Set<String> = [
        "admin", "teste", "usuario", "maria", "joao", "ana.silva", "lucas_sp", "carol"
    ]

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(320))
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !takenUsernames.contains(normalized)
    }

    func login(identifier: String, password: String) async throws -> UserProfile {
        try await Task.sleep(for: .milliseconds(300))
        return UserProfile(
            fullName: "Usuário Demonstração",
            email: identifier,
            username: identifier.lowercased(),
            age: 26,
            photos: [],
            interests: Array(Interest.all.prefix(3)),
            bio: ""
        )
    }

    func registerAccount(
        fullName: String,
        email: String,
        username: String,
        password: String,
        birthDate: Date,
        legalAcceptance: LegalAcceptance
    ) async throws -> UUID {
        try await Task.sleep(for: .milliseconds(350))
        return UUID()
    }
}

final class MockStorageService: StorageServiceProtocol {
    func uploadProfilePhotos(_ photos: [ProfilePhoto], userId: UUID) async throws -> [ProfilePhoto] {
        try await Task.sleep(for: .milliseconds(250))
        return photos
    }
}

final class LocalUserRepository: UserRepositoryProtocol {
    private let storageKey = "local_user_profile_v1"

    func saveProfile(_ profile: UserProfile) async throws {
        let data = try JSONEncoder().encode(profile)
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func loadCurrentProfile() async throws -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func clearLocalSession() async throws {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

final class MockVerificationService: VerificationServiceProtocol {
    func requestProfileVerification(userId: UUID) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(400))
        return true
    }
}

final class MockDiscoveryService: DiscoveryServiceProtocol {
    private let allCandidates: [UserProfile] = DemoDataFactory.candidates

    func fetchCandidates(filter: DiscoveryFilter) async throws -> [UserProfile] {
        try await Task.sleep(for: .milliseconds(180))
        return allCandidates.filter { profile in
            let matchesDistance = Double(profile.distanceKm) <= filter.maxDistanceKm
            let matchesAge = profile.age >= filter.minAge && profile.age <= filter.maxAge
            let matchesVerified = !filter.onlyVerified || profile.isVerified
            let matchesOnline = !filter.onlyOnline || profile.isOnline
            return matchesDistance && matchesAge && matchesVerified && matchesOnline
        }
    }

    func submitDecision(_ decision: SwipeDecision, targetUserId: UUID) async throws -> Bool {
        // Simulate a match on some likes/highlights for interactive demonstration
        if decision == .reject { return false }
        if decision == .highlight { return true }
        return targetUserId.uuidString.hashValue % 2 == 0
    }
}

final class MockMatchService: MatchServiceProtocol {
    func fetchMatches() async throws -> [MatchItem] {
        DemoDataFactory.initialMatches
    }
}

final class MockChatService: ChatServiceProtocol {
    func fetchConversations() async throws -> [Conversation] {
        DemoDataFactory.initialConversations
    }

    func sendMessage(text: String, conversationId: UUID) async throws -> ChatMessage {
        ChatMessage(id: UUID(), senderIsCurrentUser: true, text: text, sentAt: Date())
    }
}

enum DemoDataFactory {
    static let candidates: [UserProfile] = [
        UserProfile(
            fullName: "Camila Ferreira",
            username: "camila.f",
            age: 26,
            photos: [
                ProfilePhoto(placeholderPaletteHexes: ["2D3142", "4F5D75"], placeholderSymbol: "camera.fill", placeholderCaption: "Fim de tarde no parque"),
                ProfilePhoto(placeholderPaletteHexes: ["8C2F39", "B23A48"], placeholderSymbol: "fork.knife", placeholderCaption: "Café e gastronomia"),
                ProfilePhoto(placeholderPaletteHexes: ["3D5A80", "98C1D9"], placeholderSymbol: "airplane", placeholderCaption: "Última viagem")
            ],
            interests: [
                Interest.all[1], // Viagens
                Interest.all[6], // Gastronomia
                Interest.all[10], // Fotografia
                Interest.all[2] // Música
            ],
            bio: "Arquiteta, apaixonada por cafés especiais, fotografia analógica e viagens de fim de semana.",
            isVerified: true,
            isOnline: true,
            distanceKm: 3,
            city: "São Paulo"
        ),
        UserProfile(
            fullName: "Rafael Mendes",
            username: "rafa.mendes",
            age: 29,
            photos: [
                ProfilePhoto(placeholderPaletteHexes: ["1F2937", "4B5563"], placeholderSymbol: "dumbbell.fill", placeholderCaption: "Treino matinal"),
                ProfilePhoto(placeholderPaletteHexes: ["0F766E", "14B8A6"], placeholderSymbol: "leaf.fill", placeholderCaption: "Trilha na serra"),
                ProfilePhoto(placeholderPaletteHexes: ["7C2D12", "EA580C"], placeholderSymbol: "music.note", placeholderCaption: "Show ao vivo"),
                ProfilePhoto(placeholderPaletteHexes: ["312E81", "4F46E5"], placeholderSymbol: "laptopcomputer", placeholderCaption: "Projetos")
            ],
            interests: [
                Interest.all[0], // Academia
                Interest.all[9], // Natureza
                Interest.all[8], // Tecnologia
                Interest.all[2] // Música
            ],
            bio: "Desenvolvedor mobile, corredor de rua nos domingos e sempre em busca de boas trilhas.",
            isVerified: true,
            isOnline: false,
            distanceKm: 6,
            city: "São Paulo"
        ),
        UserProfile(
            fullName: "Juliana Costa",
            username: "ju.costa",
            age: 24,
            photos: [
                ProfilePhoto(placeholderPaletteHexes: ["701A75", "A21CAF"], placeholderSymbol: "paintpalette.fill", placeholderCaption: "Exposição no museu"),
                ProfilePhoto(placeholderPaletteHexes: ["1E3A8A", "3B82F6"], placeholderSymbol: "sun.max.fill", placeholderCaption: "Dia de praia"),
                ProfilePhoto(placeholderPaletteHexes: ["7F1D1D", "DC2626"], placeholderSymbol: "film.fill", placeholderCaption: "Festival de cinema")
            ],
            interests: [
                Interest.all[15], // Arte
                Interest.all[5], // Cinema
                Interest.all[13], // Praia
                Interest.all[11] // Leitura
            ],
            bio: "Designer gráfica, fã de cinema nacional e livros de ficção. Topa um museu no sábado?",
            isVerified: false,
            isOnline: true,
            distanceKm: 5,
            city: "São Paulo"
        ),
        UserProfile(
            fullName: "Lucas Almeida",
            username: "lucasalmeida",
            age: 31,
            photos: [
                ProfilePhoto(placeholderPaletteHexes: ["1E293B", "334155"], placeholderSymbol: "fork.knife", placeholderCaption: "Jantar caseiro"),
                ProfilePhoto(placeholderPaletteHexes: ["065F46", "10B981"], placeholderSymbol: "pawprint.fill", placeholderCaption: "Passeio com o Bento")
            ],
            interests: [
                Interest.all[6], // Gastronomia
                Interest.all[14], // Animais
                Interest.all[7], // Esportes
                Interest.all[1] // Viagens
            ],
            bio: "Gosto de cozinhar para amigos, passear com meu cachorro e descobrir restaurantes novos.",
            isVerified: true,
            isOnline: true,
            distanceKm: 11,
            city: "São Paulo"
        )
    ]

    static let initialMatches: [MatchItem] = [
        MatchItem(
            id: UUID(),
            profile: candidates[0],
            matchedAt: Date().addingTimeInterval(-3600 * 3),
            isHighlighted: true
        ),
        MatchItem(
            id: UUID(),
            profile: candidates[2],
            matchedAt: Date().addingTimeInterval(-3600 * 22),
            isHighlighted: false
        )
    ]

    static let initialConversations: [Conversation] = [
        Conversation(
            id: UUID(),
            profile: candidates[0],
            messages: [
                ChatMessage(
                    id: UUID(),
                    senderIsCurrentUser: false,
                    text: "Oi! Vi que você também curte fotografia e viagens.",
                    sentAt: Date().addingTimeInterval(-1800)
                )
            ],
            unreadCount: 1
        )
    ]
}
