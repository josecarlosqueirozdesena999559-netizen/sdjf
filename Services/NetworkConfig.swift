import Foundation

enum NetworkConfig {
    /// Fixed backend URL for production and App Store review.
    static let baseURL = URL(string: "https://latest-extraction-amy-thehun.trycloudflare.com")!

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
