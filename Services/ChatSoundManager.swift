import Foundation
import AVFoundation

/// Gerenciador de sons instantâneos do chat (envio e recebimento estilo WhatsApp, zero atraso).
final class ChatSoundManager {
    static let shared = ChatSoundManager()

    private var sendPlayers: [AVAudioPlayer] = []
    private var receivePlayers: [AVAudioPlayer] = []
    private var sendIndex: Int = 0
    private var receiveIndex: Int = 0
    private var isPreloaded: Bool = false

    private init() {
        preload()
    }

    /// Pré-carrega ambos os áudios na memória no boot do app para disparo instantâneo (< 5ms)
    func preload() {
        guard !isPreloaded else { return }
        isPreloaded = true

        configureAmbientSession()
        sendPlayers = buildPlayerPool(resource: "chat_send", count: 3)
        receivePlayers = buildPlayerPool(resource: "chat_receive", count: 2)
    }

    private func configureAmbientSession() {
        let session = AVAudioSession.sharedInstance()
        // Só altera para .ambient se o microfone não estiver gravando áudio no momento
        if session.category != .playAndRecord {
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
        }
    }

    private func audioURL(for resource: String) -> URL? {
        if let rootURL = Bundle.main.url(forResource: resource, withExtension: "mp3") {
            return rootURL
        }
        if let subURL = Bundle.main.url(forResource: resource, withExtension: "mp3", subdirectory: "Sounds") {
            return subURL
        }
        return nil
    }

    private func buildPlayerPool(resource: String, count: Int) -> [AVAudioPlayer] {
        guard let url = audioURL(for: resource) else { return [] }
        var pool: [AVAudioPlayer] = []
        for _ in 0..<count {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = 0.95
                player.prepareToPlay()
                pool.append(player)
            }
        }
        return pool
    }

    /// Som instantâneo ao clicar no botão de enviar mensagem (zero atraso)
    func playSendSound() {
        if sendPlayers.isEmpty {
            sendPlayers = buildPlayerPool(resource: "chat_send", count: 3)
        }
        guard !sendPlayers.isEmpty else { return }
        configureAmbientSession()

        let player = sendPlayers[sendIndex % sendPlayers.count]
        sendIndex = (sendIndex + 1) % sendPlayers.count
        player.currentTime = 0
        player.play()
    }

    /// Som instantâneo quando chega nova mensagem de outra pessoa estando com a conversa aberta (estilo WhatsApp)
    func playReceiveSound() {
        if receivePlayers.isEmpty {
            receivePlayers = buildPlayerPool(resource: "chat_receive", count: 2)
        }
        guard !receivePlayers.isEmpty else { return }
        configureAmbientSession()

        let player = receivePlayers[receiveIndex % receivePlayers.count]
        receiveIndex = (receiveIndex + 1) % receivePlayers.count
        player.currentTime = 0
        player.play()
    }
}
