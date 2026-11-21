import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(statusCode: Int, message: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Endereço do servidor inválido."
        case .unauthorized:
            return "Sessão expirada. Faça login novamente."
        case .serverError(_, let message):
            return message
        case .decodingError:
            return "Erro ao processar resposta do servidor."
        }
    }
}

private struct ServerErrorPayload: Decodable {
    let error: String?
    let message: String?
}

private struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let isoWithFractional = ISO8601DateFormatter()
            isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoStandard = ISO8601DateFormatter()
            isoStandard.formatOptions = [.withInternetDateTime]
            if let date = isoWithFractional.date(from: str) ?? isoStandard.date(from: str) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(str)")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let data = try await rawRequest(
            path: path,
            method: method,
            bodyData: body.map { try encoder.encode($0) },
            contentType: "application/json",
            requiresAuth: requiresAuth
        )

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    func requestVoid(
        path: String,
        method: String = "POST",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        _ = try await rawRequest(
            path: path,
            method: method,
            bodyData: body.map { try encoder.encode($0) },
            contentType: "application/json",
            requiresAuth: requiresAuth
        )
    }

    func uploadJPEG<T: Decodable>(path: String, imageData: Data, filename: String = "photo.jpg") async throws -> T {
        try await uploadData(path: path, data: imageData, filename: filename, mimeType: "image/jpeg")
    }

    func uploadAudio<T: Decodable>(path: String, audioData: Data, filename: String = "voice.m4a") async throws -> T {
        try await uploadData(path: path, data: audioData, filename: filename, mimeType: "audio/m4a")
    }

    func uploadData<T: Decodable>(
        path: String,
        data: Data,
        filename: String,
        mimeType: String
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let resData = try await rawRequest(
            path: path,
            method: "POST",
            bodyData: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            requiresAuth: true
        )

        return try decoder.decode(T.self, from: resData)
    }

    private func rawRequest(
        path: String,
        method: String,
        bodyData: Data?,
        contentType: String,
        requiresAuth: Bool,
        isRetryAfterRefresh: Bool = false
    ) async throws -> Data {
        guard let url = URL(string: path, relativeTo: NetworkConfig.baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.read(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.httpBody = bodyData
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError(statusCode: 500, message: "Resposta inválida do servidor.")
        }

        if http.statusCode == 401 && requiresAuth && !isRetryAfterRefresh {
            if await attemptTokenRefresh() {
                return try await rawRequest(
                    path: path,
                    method: method,
                    bodyData: bodyData,
                    contentType: contentType,
                    requiresAuth: requiresAuth,
                    isRetryAfterRefresh: true
                )
            }
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let errPayload = try? decoder.decode(ServerErrorPayload.self, from: data)
            throw APIError.serverError(
                statusCode: http.statusCode,
                message: errPayload?.message ?? "Erro no servidor (\(http.statusCode))."
            )
        }

        return data
    }

    private func attemptTokenRefresh() async -> Bool {
        guard let refreshToken = KeychainHelper.read(forKey: "refresh_token") else {
            return false
        }
        guard let url = URL(string: "/auth/refresh", relativeTo: NetworkConfig.baseURL) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let refreshed = try? decoder.decode(RefreshResponse.self, from: data) else {
            KeychainHelper.clearAllTokens()
            return false
        }

        KeychainHelper.save(refreshed.accessToken, forKey: "access_token")
        KeychainHelper.save(refreshed.refreshToken, forKey: "refresh_token")
        return true
    }
}
