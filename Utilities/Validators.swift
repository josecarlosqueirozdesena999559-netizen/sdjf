import Foundation

enum Validators {
    static func isValidFullName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.contains(where: { $0.isLetter })
    }

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    /// Allowed username characters: lowercase letters, numbers, underscore, and dot.
    /// Length: 3 to 24 characters, cannot start/end with dot or contain consecutive dots.
    static func validateUsernameFormat(_ username: String) -> UsernameFormatResult {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .empty
        }
        if trimmed.count < 3 {
            return .invalid("Use pelo menos 3 caracteres.")
        }
        if trimmed.count > 24 {
            return .invalid("Máximo de 24 caracteres.")
        }
        let allowedPattern = #"^[a-z0-9._]+$"#
        if trimmed.range(of: allowedPattern, options: .regularExpression) == nil {
            return .invalid("Use apenas letras minúsculas, números, ponto (.) ou underline (_).")
        }
        if trimmed.hasPrefix(".") || trimmed.hasSuffix(".") || trimmed.contains("..") {
            return .invalid("Não use pontos seguidos, no início ou no fim.")
        }
        return .valid
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8
    }

    static func passwordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty { return .empty }
        if password.count < 8 { return .tooShort }

        var score = 1
        if password.count >= 10 { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }

        switch score {
        case 0...1: return .weak
        case 2...3: return .medium
        default: return .strong
        }
    }
}

enum UsernameFormatResult: Equatable {
    case empty
    case valid
    case invalid(String)
}

enum PasswordStrength: Equatable {
    case empty
    case tooShort
    case weak
    case medium
    case strong

    var label: String {
        switch self {
        case .empty: return ""
        case .tooShort: return "Mínimo de 8 caracteres"
        case .weak: return "Senha aceita (pode ficar mais forte)"
        case .medium: return "Senha boa"
        case .strong: return "Senha forte"
        }
    }

    var progress: Double {
        switch self {
        case .empty: return 0.0
        case .tooShort: return 0.25
        case .weak: return 0.5
        case .medium: return 0.75
        case .strong: return 1.0
        }
    }
}
