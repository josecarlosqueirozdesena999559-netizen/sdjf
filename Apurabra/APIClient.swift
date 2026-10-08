import Foundation
import Combine
import CryptoKit

actor APIClient {
    static let shared = APIClient()
    let baseURL = URL(string: "https://apurabra.online")!
    private let decoder = JSONDecoder()
    private let cacheLifetime: TimeInterval = 7 * 24 * 60 * 60

    private var cacheDirectory: URL {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return root.appendingPathComponent("ApurabraAPIResponses", isDirectory: true)
    }

    func result(office: Office, state: String = "", municipality: String = "", round: ElectionRound = .first) async throws -> ElectionResult {
        try await request(resultURL(office: office, state: state, municipality: municipality, round: round))
    }

    func cachedResult(office: Office, state: String = "", municipality: String = "", round: ElectionRound = .first) -> ElectionResult? {
        cachedResponse(ElectionResult.self, for: resultURL(office: office, state: state, municipality: municipality, round: round))
    }

    func municipalities(state: String) async throws -> [Municipality] {
        try await request(municipalityURL(state: state))
    }

    func cachedMunicipalities(state: String) -> [Municipality]? {
        cachedResponse([Municipality].self, for: municipalityURL(state: state))
    }

    func mapSummary(office: Office, round: ElectionRound, includeResults: Bool = false) async throws -> MapSummary {
        try await request(mapSummaryURL(office: office, round: round, includeResults: includeResults))
    }

    func cachedMapSummary(office: Office, round: ElectionRound, includeResults: Bool = false) -> MapSummary? {
        cachedResponse(MapSummary.self, for: mapSummaryURL(office: office, round: round, includeResults: includeResults))
    }

    func governorSecondRoundResults() async -> [String: ElectionResult] {
        await withTaskGroup(of: (String, ElectionResult?).self) { group in
            for state in brazilStates {
                group.addTask {
                    let result = try? await self.result(office: .governador, state: state, round: .second)
                    return (state, result)
                }
            }
            var results: [String: ElectionResult] = [:]
            for await (state, result) in group {
                if let result { results[state] = result }
            }
            return results
        }
    }

    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if let absolute = URL(string: path), absolute.scheme != nil { return absolute }
        return URL(string: path, relativeTo: URL(string: "https://apurabra.online")!)?.absoluteURL
    }

    private func resultURL(office: Office, state: String, municipality: String, round: ElectionRound) -> URL {
        var components = URLComponents(url: baseURL.appending(path: "api/resultados"), resolvingAgainstBaseURL: false)!
        var query = [URLQueryItem(name: "cargo", value: office.rawValue)]
        if round == .second { query.append(URLQueryItem(name: "turno", value: "2")) }
        if !state.isEmpty { query.append(URLQueryItem(name: "uf", value: state)) }
        if !municipality.isEmpty { query.append(URLQueryItem(name: "municipio", value: municipality)) }
        components.queryItems = query
        return components.url!
    }

    private func municipalityURL(state: String) -> URL {
        var components = URLComponents(url: baseURL.appending(path: "api/localidades"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "uf", value: state)]
        return components.url!
    }

    private func mapSummaryURL(office: Office, round: ElectionRound, includeResults: Bool = false) -> URL {
        var components = URLComponents(url: baseURL.appending(path: "api/mapa"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "cargo", value: office.rawValue),
            URLQueryItem(name: "turno", value: String(round.rawValue)),
            URLQueryItem(name: "incluirResultados", value: includeResults ? "1" : "0")
        ]
        return components.url!
    }

    private func cacheFile(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined() + ".json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    private func cachedResponse<T: Decodable>(_ type: T.Type, for url: URL) -> T? {
        let file = cacheFile(for: url)
        let fileManager = FileManager.default
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: file.path),
            let modifiedAt = attributes[.modificationDate] as? Date
        else { return nil }

        guard Date().timeIntervalSince(modifiedAt) <= cacheLifetime else {
            try? fileManager.removeItem(at: file)
            return nil
        }
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func persist(_ data: Data, for url: URL) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try data.write(to: cacheFile(for: url), options: .atomic)
        } catch {
            #if DEBUG
            print("Não foi possível guardar a resposta em cache: \(error.localizedDescription)")
            #endif
        }
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .useProtocolCachePolicy
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoded = try decoder.decode(T.self, from: data)
        persist(data, for: url)
        return decoded
    }
}

@MainActor final class ResultStore: ObservableObject {
    @Published var result: ElectionResult?
    @Published var municipalities: [Municipality] = []
    @Published var loading = false
    @Published var errorMessage: String?
    private var activeQueryKey: String?
    private var activeMunicipalityState: String?

    func load(office: Office, state: String = "", municipality: String = "", round: ElectionRound = .first) async {
        let queryKey = "\(office.rawValue)|\(state)|\(municipality)|\(round.rawValue)"
        if activeQueryKey != queryKey {
            activeQueryKey = queryKey
            result = nil
        }
        errorMessage = nil

        if result == nil {
            loading = true
            let cached = await APIClient.shared.cachedResult(office: office, state: state, municipality: municipality, round: round)
            guard activeQueryKey == queryKey else { return }
            result = cached.flatMap { $0.belongs(to: round) ? $0 : nil }
        }
        loading = result == nil

        do {
            let latest = try await APIClient.shared.result(office: office, state: state, municipality: municipality, round: round)
            guard activeQueryKey == queryKey else { return }
            guard latest.belongs(to: round) else {
                if result == nil {
                    errorMessage = "A fonte não retornou dados separados para o \(round.title); dados de outro turno foram descartados."
                }
                loading = false
                return
            }
            result = latest
        } catch {
            guard activeQueryKey == queryKey else { return }
            if result == nil {
                errorMessage = "Não foi possível carregar os dados. Verifique sua conexão e tente novamente."
            }
        }
        loading = false
    }

    func loadMunicipalities(state: String) async {
        guard !state.isEmpty else { activeMunicipalityState = nil; municipalities = []; return }
        activeMunicipalityState = state
        if let cached = await APIClient.shared.cachedMunicipalities(state: state) {
            guard activeMunicipalityState == state else { return }
            municipalities = cached
        }
        do {
            let latest = try await APIClient.shared.municipalities(state: state)
            guard activeMunicipalityState == state else { return }
            municipalities = latest
        } catch {
            guard activeMunicipalityState == state else { return }
            if municipalities.isEmpty {
                municipalities = []
            }
        }
    }
}
