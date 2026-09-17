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
    @Published var cpf = "" {
        didSet {
            let numbers = cpf.filter { $0.isNumber }
            var result = ""
            for (index, char) in numbers.enumerated() {
                if index == 3 || index == 6 { result.append(".") }
                else if index == 9 { result.append("-") }
                if index < 11 { result.append(char) }
            }
            if cpf != result { cpf = result }
        }
    }
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
    
    static func isValidCPF(_ cpf: String) -> Bool {
        let numbers = cpf.filter { $0.isNumber }.compactMap { Int(String($0)) }
        guard numbers.count == 11 else { return false }
        if Set(numbers).count == 1 { return false }
        
        let sum1 = (0..<9).reduce(0) { $0 + numbers[$1] * (10 - $1) }
        let digit1 = (sum1 * 10) % 11 % 10
        if digit1 != numbers[9] { return false }
        
        let sum2 = (0..<10).reduce(0) { $0 + numbers[$1] * (11 - $1) }
        let digit2 = (sum2 * 10) % 11 % 10
        if digit2 != numbers[10] { return false }
        
        return true
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    static func isValidUsername(_ username: String) -> Bool {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanUser.count >= 3 && cleanUser.count <= 20 else { return false }
        let userRegEx = "^[a-zA-Z0-9._]+$"
        let userPred = NSPredicate(format: "SELF MATCHES %@", userRegEx)
        return userPred.evaluate(with: cleanUser)
    }
    
    func validateAndProceed() {
        errorMessage = nil
        
        switch currentStep {
        case .name:
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.count < 3 || !trimmedName.contains(" ") {
                errorMessage = "Digite seu nome e sobrenome completo."
                return
            }
        case .cpf:
            let cleanCpf = cpf.filter { $0.isNumber }
            if cleanCpf.count != 11 {
                errorMessage = "O CPF deve conter exatamente 11 números."
                return
            }
            if !RegisterViewModel.isValidCPF(cleanCpf) {
                errorMessage = "CPF inválido. Por favor, verifique os números."
                return
            }
            if MockData.users.contains(where: { $0.cpf?.filter { $0.isNumber } == cleanCpf }) {
                errorMessage = "Este CPF já está cadastrado em nosso sistema."
                return
            }
        case .birthDate:
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            if age < 18 {
                errorMessage = "É necessário ter mais de 18 anos para se cadastrar."
                return
            }
        case .email:
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            if !RegisterViewModel.isValidEmail(cleanEmail) {
                errorMessage = "Digite um endereço de e-mail válido (ex: nome@email.com)."
                return
            }
            if MockData.users.contains(where: { $0.email.lowercased() == cleanEmail.lowercased() }) {
                errorMessage = "Este e-mail já está em uso por outra conta."
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
            if !RegisterViewModel.isValidUsername(cleanUser) {
                errorMessage = "O usuário deve ter de 3 a 20 caracteres e conter apenas letras, números, ponto ou underline."
                return
            }
            if MockData.users.contains(where: { $0.username?.lowercased() == cleanUser }) {
                errorMessage = "Este nome de usuário '@\(cleanUser)' já está em uso. Escolha outro."
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
            self.locationName = "Falha ao obter Localização."
        }
    }
            func register(authViewModel: AuthViewModel, completion: @escaping () -> Void) {
        self.errorMessage = nil
        Task {
            do {
                let response = try await supabase.auth.signUp(email: self.email, password: self.password)
                let user = response.user
                var avatarUrlStr: String? = nil
                if let image = self.profileImage, let data = image.jpegData(compressionQuality: 0.7) {
                    let fileName = "\(user.id.uuidString).jpg"
                    do {
                        try await supabase.storage.from("avatars").upload(
                            path: fileName,
                            file: data
                        )
                        let publicUrl = try supabase.storage.from("avatars").getPublicURL(path: fileName)
                        avatarUrlStr = publicUrl.absoluteString
                    } catch {
                        print("Erro ao fazer upload do avatar: \(error)")
                    }
                }
                
                let currentCpf = self.cpf
                let cleanCpf = currentCpf.filter { char in char.isNumber }
                let newProfile = Profile(
                    id: user.id,
                    name: self.name,
                    visible_name: self.visibleName.isEmpty ? nil : self.visibleName,
                    username: self.username,
                    email: self.email,
                    document: cleanCpf,
                    location: self.locationName.isEmpty ? "Desconhecido" : self.locationName,
                    avatar_url: avatarUrlStr,
                    created_at: Date()
                )
                
                try await supabase.database
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                
                let finalEmail = self.email
                let finalPassword = self.password
                
                await MainActor.run {
                    authViewModel.login(emailOrUsername: finalEmail, password: finalPassword)
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ocorreu um erro no cadastro: \(error.localizedDescription)"
                }
            }
        }
    }
}


