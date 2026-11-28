import Foundation
import CoreLocation
import Combine
import SwiftUI

@MainActor
final class TrilhaGameStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Fluxo de telas
    enum AppStage {
        case splash
        case avatarSetup
        case mainMap
    }

    @Published var stage: AppStage = .splash
    @Published var selectedTeam: TrilhaTeam = .esmeralda
    @Published var selectedAvatarId: Int = 1
    @Published var playerName: String = "Explorador"

    // Economia e progresso
    @Published var userId: UUID = UUID()
    @Published var keysCount: Int = 3
    @Published var xp: Int = 120
    @Published var coins: Int = 80
    @Published var totalDistanceMeters: Double = 0
    @Published var distanceTowardsNextKey: Double = 0

    // Localização & Anti-Cheat
    @Published var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -23.561414, longitude: -46.655881)
    @Published var speedKmh: Double = 0
    @Published var isMockLocationBlocked: Bool = false
    @Published var isSpeedBlocked: Bool = false

    // Mapa 3D: territórios, lojas e chaves no chão
    @Published var territories: [TerritoryHex] = []
    @Published var stores: [StoreLocation] = []
    @Published var floatingKeys: [CLLocationCoordinate2D] = []

    // Vitrine animada de proximidade (40m -> entra, >60m ou 15s -> sai, cooldown 30 min)
    @Published var activeShowcaseStore: StoreLocation?
    @Published var activeShowcaseDistance: Double = 0
    private var showcaseCooldowns: [UUID: Date] = [:]
    private var showcaseTimer: Timer?

    // Modo Esporte
    @Published var selectedSportMode: SportMode = .walk
    @Published var isWorkoutActive: Bool = false
    @Published var workoutDistanceMeters: Double = 0
    @Published var workoutSeconds: Int = 0
    @Published var workoutRoute: [CLLocationCoordinate2D] = []
    @Published var workoutTerritoriesConquered: Int = 0
    @Published var latestWorkoutSummary: WorkoutSummary?
    private var workoutTimer: Timer?

    // Mochila & Ranking
    @Published var coupons: [CouponQR] = [
        CouponQR(
            id: UUID(),
            storeName: "Café Esmeralda",
            rarity: .rare,
            rewardTitle: "20% OFF no Espresso + Pão de Queijo",
            qrToken: "TRILHA-RARE-19C302",
            createdAt: Date(),
            redeemedAt: nil
        )
    ]
    @Published var ranking: [RankingEntry] = [
        RankingEntry(position: 1, playerName: "LucasRunner", team: .esmeralda, territoriesCount: 42, distanceKm: 64.2),
        RankingEntry(position: 2, playerName: "MarinaBike", team: .horizonte, territoriesCount: 38, distanceKm: 91.5),
        RankingEntry(position: 3, playerName: "PedroTrail", team: .solar, territoriesCount: 31, distanceKm: 49.8),
        RankingEntry(position: 4, playerName: "Você", team: .esmeralda, territoriesCount: 12, distanceKm: 14.6)
    ]

    // Modais
    @Published var chestModalStore: StoreLocation?
    @Published var showBackpack: Bool = false
    @Published var showRanking: Bool = false
    @Published var showSettings: Bool = false
    @Published var showMerchantPanel: Bool = false

    private let locationManager = CLLocationManager()
    private var lastValidLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        seedWorld(around: userLocation)
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func seedWorld(around center: CLLocationCoordinate2D) {
        territories = H3GridHelper.nearbyHexes(around: center, resolution: 9)
        stores = [
            StoreLocation(
                id: UUID(),
                name: "Café Esmeralda",
                category: "Cafeteria & Padaria",
                coordinate: CLLocationCoordinate2D(latitude: center.latitude + 0.00024, longitude: center.longitude + 0.00018),
                hasPremiumChest: true,
                premiumWindowLabel: "09:30 – 18:30",
                promoTitle: "Baú Premium disponível hoje",
                premiumAvailableToday: true
            ),
            StoreLocation(
                id: UUID(),
                name: "Arena Sport Fit",
                category: "Suplementos & Moda",
                coordinate: CLLocationCoordinate2D(latitude: center.latitude - 0.0009, longitude: center.longitude + 0.0008),
                hasPremiumChest: true,
                premiumWindowLabel: "10:00 – 19:00",
                promoTitle: "20% OFF + Baú Dourado",
                premiumAvailableToday: true
            ),
            StoreLocation(
                id: UUID(),
                name: "Bike Point Urbano",
                category: "Oficina & Café",
                coordinate: CLLocationCoordinate2D(latitude: center.latitude + 0.0011, longitude: center.longitude - 0.0007),
                hasPremiumChest: false,
                premiumWindowLabel: "Sem Premium hoje",
                promoTitle: "Baú Comum e Raro",
                premiumAvailableToday: false
            )
        ]
        floatingKeys = [
            CLLocationCoordinate2D(latitude: center.latitude + 0.00045, longitude: center.longitude - 0.00035),
            CLLocationCoordinate2D(latitude: center.latitude - 0.00042, longitude: center.longitude - 0.00050)
        ]
    }

    // MARK: - CLLocationManagerDelegate + Anti-Cheat
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.processLocation(loc)
        }
    }

    func processLocation(_ loc: CLLocation) {
        // Bloqueio Mock Location / Fake GPS (iOS 15+)
        if let src = loc.sourceInformation, (src.isSimulatedBySoftware || src.isProducedByAccessory) {
            isMockLocationBlocked = true
            return
        }
        isMockLocationBlocked = false

        let rawSpeedKmh = max(0, loc.speed * 3.6)
        speedKmh = rawSpeedKmh
        let maxAllowed = isWorkoutActive ? selectedSportMode.maxSpeedKmh : 25.0
        if rawSpeedKmh > maxAllowed {
            isSpeedBlocked = true
            return
        }
        isSpeedBlocked = false

        userLocation = loc.coordinate
        if territories.isEmpty {
            seedWorld(around: loc.coordinate)
        }

        if let prev = lastValidLocation {
            let delta = loc.distance(from: prev)
            if delta >= 3 && delta < 120 {
                applyMovement(meters: delta, newCoord: loc.coordinate)
            }
        }
        lastValidLocation = loc
        evaluateStoreProximity()
    }

    /// Simula caminhada de 100m para testar no Simulador / Appetize sem sair do lugar
    func simulateStep(meters: Double = 125) {
        let next = CLLocationCoordinate2D(
            latitude: userLocation.latitude + 0.00018,
            longitude: userLocation.longitude + 0.00014
        )
        userLocation = next
        applyMovement(meters: meters, newCoord: next)
        evaluateStoreProximity()
    }

    private func applyMovement(meters: Double, newCoord: CLLocationCoordinate2D) {
        totalDistanceMeters += meters
        distanceTowardsNextKey += meters

        // A cada 500 m ganha Chaves (1,5x no Modo Esporte)
        while distanceTowardsNextKey >= 500 {
            distanceTowardsNextKey -= 500
            let earned = isWorkoutActive ? 2 : 1
            keysCount += earned
        }

        // Pontua no hexágono H3 atual
        let key = H3GridHelper.hexKey(for: newCoord, resolution: 9)
        if let idx = territories.firstIndex(where: { $0.id == key }) {
            let previousOwner = territories[idx].ownerTeam
            territories[idx].points += isWorkoutActive ? 15 : 10
            territories[idx].ownerTeam = selectedTeam
            if previousOwner != selectedTeam && isWorkoutActive {
                workoutTerritoriesConquered += 1
            }
        }

        if isWorkoutActive {
            workoutDistanceMeters += meters
            workoutRoute.append(newCoord)
        }
    }

    // MARK: - Vitrine Animada de Proximidade (<= 40m entra, > 60m ou 15s sai, cooldown 30 min)
    func evaluateStoreProximity() {
        let userCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let now = Date()

        if let active = activeShowcaseStore {
            let storeCL = CLLocation(latitude: active.coordinate.latitude, longitude: active.coordinate.longitude)
            let dist = userCL.distance(from: storeCL)
            activeShowcaseDistance = dist
            if dist > 60.0 {
                dismissShowcase()
            }
            return
        }

        for store in stores {
            let storeCL = CLLocation(latitude: store.coordinate.latitude, longitude: store.coordinate.longitude)
            let dist = userCL.distance(from: storeCL)
            if dist <= 40.0 {
                if let cd = showcaseCooldowns[store.id], cd > now { continue }
                activeShowcaseStore = store
                activeShowcaseDistance = dist
                showcaseCooldowns[store.id] = now.addingTimeInterval(30 * 60)
                showcaseTimer?.invalidate()
                showcaseTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.dismissShowcase()
                    }
                }
                break
            }
        }
    }

    func dismissShowcase() {
        showcaseTimer?.invalidate()
        showcaseTimer = nil
        withAnimation(.easeOut(duration: 0.28)) {
            activeShowcaseStore = nil
        }
    }

    func distanceTo(store: StoreLocation) -> Double {
        let a = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let b = CLLocation(latitude: store.coordinate.latitude, longitude: store.coordinate.longitude)
        return a.distance(from: b)
    }

    // MARK: - Modo Esporte
    func startWorkout(mode: SportMode) {
        selectedSportMode = mode
        isWorkoutActive = true
        workoutDistanceMeters = 0
        workoutSeconds = 0
        workoutTerritoriesConquered = 0
        workoutRoute = [userLocation]
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.workoutSeconds += 1
            }
        }
    }

    func finishWorkout() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        isWorkoutActive = false

        let km = workoutDistanceMeters / 1000.0
        let mins = max(0.1, Double(workoutSeconds) / 60.0)
        let pace = km > 0.05 ? (mins / km) : 0
        let kcal = Int(km * selectedSportMode.kcalPerKm)
        let baseKeys = max(1, Int(workoutDistanceMeters / 500.0))
        let bonusKeys = Int(ceil(Double(baseKeys) * 1.5))
        let bonusXp = Int(ceil(max(20.0, km * 50.0) * 1.5))

        keysCount += bonusKeys
        xp += bonusXp

        latestWorkoutSummary = WorkoutSummary(
            mode: selectedSportMode,
            distanceMeters: workoutDistanceMeters,
            durationSeconds: workoutSeconds,
            calories: kcal,
            avgPaceMinPerKm: pace,
            keysEarned: bonusKeys,
            xpEarned: bonusXp,
            territoriesConquered: workoutTerritoriesConquered,
            route: workoutRoute
        )
    }

    // MARK: - Abertura de Baú
    func claimChest(for store: StoreLocation) async -> ChestClaimResponse {
        guard keysCount > 0 else {
            return ChestClaimResponse(ok: false, rarity: nil, rewardTitle: nil, qrToken: nil, error: "Você precisa de pelo menos 1 Chave.")
        }
        let resp = await SupabaseService.shared.claimChestReward(
            userId: userId,
            store: store,
            userCoordinate: userLocation,
            keyCost: 1
        )
        if resp.ok {
            keysCount = max(0, keysCount - 1)
            let rarity = resp.rarity ?? .common
            if rarity == .premium, let idx = stores.firstIndex(where: { $0.id == store.id }) {
                stores[idx].premiumAvailableToday = false
            }
            if let token = resp.qrToken, let title = resp.rewardTitle {
                coupons.insert(
                    CouponQR(
                        id: UUID(),
                        storeName: store.name,
                        rarity: rarity,
                        rewardTitle: title,
                        qrToken: token,
                        createdAt: Date(),
                        redeemedAt: nil
                    ),
                    at: 0
                )
            }
            xp += rarity == .premium ? 150 : (rarity == .rare ? 60 : 25)
            if rarity == .common { coins += 50 }
        }
        return resp
    }
}
