import Foundation

/// Serviço de integração nativa do iOS com a API Oficial do WhatsApp Cloud da Meta
final class WhatsAppCloudAPIService {
    static let shared = WhatsAppCloudAPIService()

    private let token: String = "EAAsjZBozpZCmwBTK4QdUHZBEdP3Vyh6a6RboBa1zyniHKPjddIG5nrFOOwfef0qPTQsTNB9M5l6ibcpZAmoiA8uzRfkQv9sjjeLfTTeVQUE4ZAdGqRbtZCyl4pZBr2FcZBEQX5i9IvhkvxUzLxK835ZBW4VEC3W6IO7k6wz9AO0iM1c3uVgKkWdHzxKfMG51qZA8N3nx1DmXwv9H6xZAuVoFjRMq6msPkLCpW7StMLrgyCzAgz2VE86xeItYdljgrLckIGSIFpxopeBbzPKQ5J1UdZA0SQZDZD"
    private let phoneNumberId: String = "1490074984181964"

    private init() {}

    /// Dispara o código OTP de 6 dígitos via WhatsApp usando o template oficial aprovado 'junto_codigo_verificacao'
    func sendOTP(to rawPhone: String, code: String) async -> Bool {
        var digits = rawPhone.filter { $0.isNumber }
        if !digits.hasPrefix("55") {
            digits = "55" + digits
        }

        guard let url = URL(string: "https://graph.facebook.com/v21.0/\(phoneNumberId)/messages") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Payload do template oficial 'junto_codigo_verificacao' aprovado na Meta
        let payload: [String: Any] = [
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": digits,
            "type": "template",
            "template": [
                "name": "junto_codigo_verificacao",
                "language": [
                    "code": "pt_BR"
                ],
                "components": [
                    [
                        "type": "body",
                        "parameters": [
                            [
                                "type": "text",
                                "text": code
                            ]
                        ]
                    ],
                    [
                        "type": "button",
                        "sub_type": "url",
                        "index": "0",
                        "parameters": [
                            [
                                "type": "text",
                                "text": code
                            ]
                        ]
                    ]
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                print("[WhatsApp API] OTP enviado com sucesso para \(digits). Status: \(http.statusCode)")
                return true
            } else {
                if let errString = String(data: data, encoding: .utf8) {
                    print("[WhatsApp API] Erro no envio: \(errString)")
                }
                // Fallback: se o template falhar por algum motivo de janela, tenta mensagem de texto livre
                return await sendTextFallback(to: digits, code: code)
            }
        } catch {
            print("[WhatsApp API] Falha de conexão: \(error.localizedDescription)")
            return await sendTextFallback(to: digits, code: code)
        }
    }

    /// Fallback de texto livre caso haja janela de 24h aberta
    private func sendTextFallback(to digits: String, code: String) async -> Bool {
        guard let url = URL(string: "https://graph.facebook.com/v21.0/\(phoneNumberId)/messages") else {
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": digits,
            "type": "text",
            "text": [
                "preview_url": false,
                "body": "🔐 *Juntô*: Seu código de verificação é *\(code)*. Válido por 10 minutos."
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                print("[WhatsApp API] Fallback de texto enviado com sucesso.")
                return true
            }
            return false
        } catch {
            return false
        }
    }
}
