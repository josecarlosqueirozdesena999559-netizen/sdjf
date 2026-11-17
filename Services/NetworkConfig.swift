import Foundation

enum NetworkConfig {
    /// Reads API_BASE_URL from Info.plist when configured, otherwise falls back to defaultURL.
    /// For TestFlight on any network (4G/5G/external Wi-Fi), set this to your HTTPS tunnel or VPS URL.
    static let defaultURL = "http://localhost:3001"

    static var baseURL: URL {
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
