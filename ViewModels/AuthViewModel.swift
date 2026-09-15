import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    
    func login() {
        // Mock login
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = MockData.users.first
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
