import Foundation
import Combine
import CoreLocation
import UIKit

enum RegisterStep: Int, CaseIterable {
    case name = 0
    case cpf
    case birthDate
    case email
    case password
    case username
    case location
    case profileSetup
}

class RegisterViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentStep: RegisterStep = .name
    
    @Published var name = ""
    @Published var cpf = ""
    @Published var birthDate = Date()
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    
    // Location
    @Published var locationName = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var isFetchingLocation = false
    
    // Profile
    @Published var visibleName = ""
    @Published var profileImage: UIImage? = nil
    
    // Location Manager
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func nextStep() {
        if currentStep != .profileSetup {
            if let next = RegisterStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }
    
    func previousStep() {
        if currentStep != .name {
            if let prev = RegisterStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prev
            }
        }
    }
    
    func requestLocation() {
        isFetchingLocation = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        self.latitude = loc.coordinate.latitude
        self.longitude = loc.coordinate.longitude
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            DispatchQueue.main.async {
                self.isFetchingLocation = false
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""
                    if !city.isEmpty && !state.isEmpty {
                        self.locationName = "\(city) - \(state)"
                    } else {
                        self.locationName = "Localização obtida com sucesso!"
                    }
                } else {
                    self.locationName = "Localização obtida com sucesso!"
                }
            }
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isFetchingLocation = false
            self.locationName = "Falha ao obter localização."
        }
    }
}
