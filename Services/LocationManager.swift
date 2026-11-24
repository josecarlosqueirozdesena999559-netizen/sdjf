import Foundation
import CoreLocation
import SwiftUI

/// Gerenciador de Localização Real do iOS (GPS + Geocodificação Reversa)
@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let clManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation? = nil
    @Published var currentCity: String = "Sua Região"
    @Published var currentNeighborhood: String = "Próximo a você"
    @Published var displayLocationText: String = "Localizando..."

    override private init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = clManager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            clManager.startUpdatingLocation()
        }
    }

    /// Solicita autorização nativa do iOS para uso da localização
    func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            clManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            clManager.startUpdatingLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = loc
            self.reverseGeocode(location: loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silencioso em caso de erro temporário
    }

    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self, let place = placemarks?.first else { return }
            Task { @MainActor in
                let city = place.locality ?? place.administrativeArea ?? "Sua Região"
                let neighborhood = place.subLocality ?? place.name ?? "Bairro"
                self.currentCity = city
                self.currentNeighborhood = neighborhood
                self.displayLocationText = "\(neighborhood), \(city)"
            }
        }
    }

    /// Calcula a distância em km entre o usuário e uma coordenada
    func distanceInKm(latitude: Double, longitude: Double) -> Double? {
        guard let userLoc = currentLocation else { return nil }
        let target = CLLocation(latitude: latitude, longitude: longitude)
        return userLoc.distance(from: target) / 1000.0
    }
}
