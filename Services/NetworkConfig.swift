import Foundation

enum NetworkConfig {
    /// Default live server URL (updated for TestFlight builds).
    static let defaultURL = "https://latest-extraction-amy-thehun.trycloudflare.com"
    private static let overrideKey = "api_base_url_override"

    static var customURL: String? {
        get {
            let val = UserDefaults.standard.string(forKey: overrideKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (val?.isEmpty == false) ? val : nil
        }
        set {
            let trimmed = newValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmed, !trimmed.isEmpty {
                UserDefaults.standard.set(trimmed, forKey: overrideKey)
            } else {
                UserDefaults.standard.removeObject(forKey: overrideKey)
            }
        }
    }

    static var baseURL: URL {
        if let custom = customURL, let url = URL(string: custom) {
            return url
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !plistValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: plistValue) {
            return url
        }
        return URL(string: defaultURL)!
    }

    static var socketWebSocketURL: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.scheme = (components.scheme == "https") ? "wss" : "ws"
        components.path = "/socket.io/"
        components.queryItems = [
            URLQueryItem(name: "EIO", value: "4"),
            URLQueryItem(name: "transport", value: "websocket")
        ]
        return components.url!
    }
}
