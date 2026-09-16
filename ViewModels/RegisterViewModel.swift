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
    
    @Published var errorMessage: String? = nil
    
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
    
    func validateAndProceed() {
        errorMessage = nil
        
        switch currentStep {
        case .name:
            if name.count < 3 {
                errorMessage = "Digite seu nome completo."
                return
            }
        case .cpf:
            let cleanCpf = cpf.filter { $0.isNumber }
            if cleanCpf.count != 11 {
                errorMessage = "O CPF deve ter 11 números."
                return
            }
            if MockData.users.contains(where: { $0.cpf?.filter { $0.isNumber } == cleanCpf }) {
                errorMessage = "Este CPF já está cadastrado."
                return
            }
        case .birthDate:
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            if age < 18 {
                errorMessage = "Você precisa ter mais de 18 anos."
                return
            }
        case .email:
            if !email.contains("@") || !email.contains(".") {
                errorMessage = "Digite um e-mail válido."
                return
            }
            if MockData.users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                errorMessage = "Este e-mail já está em uso."
                return
            }
        case .password:
            if password.count < 6 {
                errorMessage = "A senha deve ter no mínimo 6 caracteres."
                return
            }
        case .username:
            let cleanUser = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanUser.isEmpty {
                errorMessage = "Digite um nome de usuário."
                return
            }
            if MockData.users.contains(where: { $0.username?.lowercased() == cleanUser }) {
                errorMessage = "Este usuário já existe. Tente outro."
                return
            }
        default:
            break
        }
        
        nextStep()
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
