import Foundation
import Combine

actor APIClient {
    static let shared = APIClient()
    let baseURL = URL(string: "https://kdfsd.vercel.app")!
    private let decoder = JSONDecoder()

    func result(office: Office, state: String = "", municipality: String = "") async throws -> ElectionResult {
        var components = URLComponents(url: baseURL.appending(path: "api/resultados"), resolvingAgainstBaseURL: false)!
        var query = [URLQueryItem(name: "cargo", value: office.rawValue)]
        if !state.isEmpty { query.append(URLQueryItem(name: "uf", value: state)) }
        if !municipality.isEmpty { query.append(URLQueryItem(name: "municipio", value: municipality)) }
        components.queryItems = query
        return try await request(components.url!)
    }

    func municipalities(state: String) async throws -> [Municipality] {
        var components = URLComponents(url: baseURL.appending(path: "api/localidades"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "uf", value: state)]
        return try await request(components.url!)
    }

    func mapColors(office: Office) async throws -> [String: String] {
        var components = URLComponents(url: baseURL.appending(path: "api/mapa"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "cargo", value: office.rawValue)]
        let summary: MapSummary = try await request(components.url!)
        return summary.cores
    }

    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if let absolute = URL(string: path), absolute.scheme != nil { return absolute }
        return URL(string: path, relativeTo: URL(string: "https://kdfsd.vercel.app")!)?.absoluteURL
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try decoder.decode(T.self, from: data)
    }
}

@MainActor final class ResultStore: ObservableObject {
    @Published var result: ElectionResult?
    @Published var municipalities: [Municipality] = []
    @Published var loading = false
    @Published var errorMessage: String?

    func load(office: Office, state: String = "", municipality: String = "") async {
        loading = true; errorMessage = nil
        do {
            result = try await APIClient.shared.result(office: office, state: state, municipality: municipality)
        }
        catch { errorMessage = "Não foi possível carregar os dados. Verifique sua conexão e tente novamente." }
        loading = false
    }

    func loadMunicipalities(state: String) async {
        guard !state.isEmpty else { municipalities = []; return }
        do { municipalities = try await APIClient.shared.municipalities(state: state) }
        catch { municipalities = [] }
    }
}
