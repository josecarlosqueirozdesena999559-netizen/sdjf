import Foundation

enum PixKeyKind: String, CaseIterable, Identifiable {
    case cpf = "CPF"
    case phone = "Telefone"
    case email = "E-mail"
    case random = "Aleatória"

    var id: String { rawValue }

    var placeholder: String {
        switch self {
        case .cpf: return "000.000.000-00"
        case .phone: return "(11) 99999-9999"
        case .email: return "nome@exemplo.com"
        case .random: return "00000000-0000-0000-0000-000000000000"
        }
    }

    var helperText: String {
        switch self {
        case .cpf: return "Digite os 11 números do seu CPF."
        case .phone: return "Informe o DDD + número com 9 dígitos."
        case .email: return "Informe um endereço de e-mail válido."
        case .random: return "Cole ou digite sua chave aleatória (32 caracteres)."
        }
    }
}

struct PixValidationResult {
    let isValid: Bool
    let formatted: String
    let errorMessage: String?
}

enum PixKeyValidator {
    private static let validBrDDDs: Set<Int> = [
        11, 12, 13, 14, 15, 16, 17, 18, 19,
        21, 22, 24, 27, 28,
        31, 32, 33, 34, 35, 37, 38,
        41, 42, 43, 44, 45, 46, 47, 48, 49,
        51, 53, 54, 55,
        61, 62, 63, 64, 65, 66, 67, 68, 69,
        71, 73, 74, 75, 77, 79,
        81, 82, 83, 84, 85, 86, 87, 88, 89,
        91, 92, 93, 94, 95, 96, 97, 98, 99
    ]

    static func detectKind(from raw: String) -> PixKeyKind {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("@") { return .email }
        let hexCount = trimmed.lowercased().filter { "0123456789abcdef".contains($0) }.count
        if trimmed.contains("-") && hexCount >= 20 { return .random }
        if trimmed.contains("(") || trimmed.hasPrefix("+") { return .phone }
        let digits = trimmed.filter { $0.isNumber }
        if trimmed.contains(".") || (digits.count == 11 && isValidCPF(digits)) {
            return .cpf
        }
        if isValidBrPhone(digits) { return .phone }
        return .cpf
    }

    // MARK: - Formatação ao vivo enquanto o usuário digita
    static func formatLive(_ raw: String, kind: PixKeyKind) -> String {
        switch kind {
        case .cpf:
            return formatCPF(raw)
        case .phone:
            return formatBrPhone(raw)
        case .email:
            return raw.replacingOccurrences(of: " ", with: "").lowercased()
        case .random:
            return formatRandomUUID(raw)
        }
    }

    static func formatCPF(_ raw: String) -> String {
        let digits = Array(raw.filter { $0.isNumber }.prefix(11))
        var out = ""
        for (idx, ch) in digits.enumerated() {
            if idx == 3 || idx == 6 { out.append(".") }
            if idx == 9 { out.append("-") }
            out.append(ch)
        }
        return out
    }

    static func formatBrPhone(_ raw: String) -> String {
        var digits = raw.filter { $0.isNumber }
        if (digits.count == 12 || digits.count == 13) && digits.hasPrefix("55") {
            digits = String(digits.dropFirst(2))
        }
        digits = String(digits.prefix(11))
        if digits.count <= 2 { return digits }
        let ddd = digits.prefix(2)
        if digits.count <= 6 {
            return "(\(ddd)) \(digits.dropFirst(2))"
        }
        if digits.count <= 10 {
            let mid = digits.dropFirst(2).prefix(4)
            let end = digits.dropFirst(6)
            return "(\(ddd)) \(mid)-\(end)"
        }
        let mid = digits.dropFirst(2).prefix(5)
        let end = digits.dropFirst(7)
        return "(\(ddd)) \(mid)-\(end)"
    }

    static func formatRandomUUID(_ raw: String) -> String {
        let hex = Array(raw.lowercased().filter { "0123456789abcdef".contains($0) }.prefix(32))
        var out = ""
        for (idx, ch) in hex.enumerated() {
            if idx == 8 || idx == 12 || idx == 16 || idx == 20 {
                out.append("-")
            }
            out.append(ch)
        }
        return out
    }

    // MARK: - Validações Reais
    static func isValidCPF(_ raw: String) -> Bool {
        let digits = raw.filter { $0.isNumber }.compactMap { Int(String($0)) }
        guard digits.count == 11 else { return false }
        if Set(digits).count == 1 { return false }

        var sum1 = 0
        for i in 0..<9 { sum1 += digits[i] * (10 - i) }
        var d1 = (sum1 * 10) % 11
        if d1 == 10 { d1 = 0 }
        guard d1 == digits[9] else { return false }

        var sum2 = 0
        for i in 0..<10 { sum2 += digits[i] * (11 - i) }
        var d2 = (sum2 * 10) % 11
        if d2 == 10 { d2 = 0 }
        return d2 == digits[10]
    }

    static func isValidBrPhone(_ raw: String) -> Bool {
        var digits = raw.filter { $0.isNumber }
        if (digits.count == 12 || digits.count == 13) && digits.hasPrefix("55") {
            digits = String(digits.dropFirst(2))
        }
        guard digits.count == 10 || digits.count == 11 else { return false }
        guard let ddd = Int(digits.prefix(2)), validBrDDDs.contains(ddd) else { return false }
        let body = String(digits.dropFirst(2))
        if digits.count == 11 && !body.hasPrefix("9") { return false }
        if Set(body).count == 1 { return false }
        return true
    }

    static func isValidEmail(_ raw: String) -> Bool {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pattern = #"^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$"#
        return clean.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidRandomKey(_ raw: String) -> Bool {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
        return clean.range(of: pattern, options: .regularExpression) != nil
    }

    static func validate(_ raw: String, kind: PixKeyKind) -> PixValidationResult {
        let formatted = formatLive(raw, kind: kind).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !formatted.isEmpty else {
            return PixValidationResult(isValid: false, formatted: "", errorMessage: nil)
        }

        switch kind {
        case .cpf:
            let digits = formatted.filter { $0.isNumber }
            if digits.count < 11 {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "Digite todos os 11 números do CPF.")
            }
            if !isValidCPF(digits) {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "CPF inválido. Confira os dígitos informados.")
            }
            return PixValidationResult(isValid: true, formatted: formatted, errorMessage: nil)

        case .phone:
            let digits = formatted.filter { $0.isNumber }
            if digits.count < 10 {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "Informe DDD e telefone completo.")
            }
            if !isValidBrPhone(digits) {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "Telefone brasileiro inválido. Confira o DDD e o 9º dígito.")
            }
            return PixValidationResult(isValid: true, formatted: formatted, errorMessage: nil)

        case .email:
            if !isValidEmail(formatted) {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "E-mail inválido. Ex: nome@dominio.com")
            }
            return PixValidationResult(isValid: true, formatted: formatted, errorMessage: nil)

        case .random:
            let hexLen = formatted.filter { "0123456789abcdef".contains($0) }.count
            if hexLen < 32 {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "Chave aleatória incompleta (\(hexLen)/32 caracteres).")
            }
            if !isValidRandomKey(formatted) {
                return PixValidationResult(isValid: false, formatted: formatted, errorMessage: "Formato de chave aleatória inválido.")
            }
            return PixValidationResult(isValid: true, formatted: formatted, errorMessage: nil)
        }
    }
}
