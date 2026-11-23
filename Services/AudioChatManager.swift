import Foundation
import AVFoundation
import SwiftUI

/// Gerenciador real de gravação limpa (AVAudioRecorder com supressão de ruído / voiceChat) e reprodução sincronizada com auto-play
@MainActor
final class AudioChatManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var recordingSeconds = 0
    @Published var liveLevels: [CGFloat] = []

    @Published var playingMessageId: UUID? = nil
    @Published var playbackProgress: Double = 0.0
    @Published var playbackCurrentSeconds: Int = 0

    /// Chamado automaticamente quando um áudio termina de tocar (permite tocar o próximo áudio da fila)
    var onPlaybackFinished: ((UUID) -> Void)?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var currentRecordingURL: URL?
    private var meteringTimer: Timer?
    private var playbackTimer: Timer?
    private var recordStartDate: Date?
    private var simulatedDuration: Double = 0

    // MARK: - Gravação Real Limpa (44.1kHz AAC High + VoiceChat noise suppression)
    func startRecording() {
        stopPlayback()
        liveLevels = []
        recordingSeconds = 0
        recordStartDate = Date()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("junto_audio_\(UUID().uuidString).m4a")
            currentRecordingURL = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let rec = try AVAudioRecorder(url: fileURL, settings: settings)
            rec.isMeteringEnabled = true
            rec.prepareToRecord()
            rec.record()
            recorder = rec
        } catch {
            recorder = nil
        }

        isRecording = true

        meteringTimer?.invalidate()
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleAudioLevel()
            }
        }
    }

    private func sampleAudioLevel() {
        guard isRecording else { return }

        if let start = recordStartDate {
            recordingSeconds = Int(Date().timeIntervalSince(start))
        }

        let normalized: CGFloat
        if let rec = recorder, rec.isRecording {
            rec.updateMeters()
            let power = rec.averagePower(forChannel: 0) // -160 dB a 0 dB
            let clamped = max(-52.0, min(0.0, Double(power)))
            normalized = CGFloat(max(0.14, (clamped + 52.0) / 52.0))
        } else {
            normalized = CGFloat.random(in: 0.18...0.85)
        }

        liveLevels.append(normalized)
        if liveLevels.count > 48 {
            liveLevels.removeFirst()
        }
    }

    func cancelRecording() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentRecordingURL = nil
        isRecording = false
        recordingSeconds = 0
        liveLevels = []
    }

    func finishRecording() -> (duration: Int, waveform: [CGFloat], fileURL: URL?) {
        meteringTimer?.invalidate()
        meteringTimer = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let finalDuration = max(recordingSeconds, 1)
        let sampledWaveform = resampleWaveform(liveLevels, targetCount: 24)
        let url = currentRecordingURL

        currentRecordingURL = nil
        isRecording = false
        recordingSeconds = 0
        liveLevels = []

        return (finalDuration, sampledWaveform, url)
    }

    // MARK: - Reprodução Limpa e Sincronizada com Ondas + Auto-Play
    func togglePlayback(messageId: UUID, fileURL: URL?, durationSeconds: Int) {
        if playingMessageId == messageId {
            stopPlayback()
            return
        }

        stopPlayback()
        playingMessageId = messageId
        playbackProgress = 0
        playbackCurrentSeconds = 0
        simulatedDuration = max(Double(durationSeconds), 1.0)

        if let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [])
                try session.setActive(true)
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                p.volume = 1.0
                p.prepareToPlay()
                p.play()
                player = p
            } catch {
                player = nil
            }
        }

        let start = Date()
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.playingMessageId == messageId else { return }
                if let p = self.player, p.duration > 0 {
                    self.playbackProgress = min(p.currentTime / p.duration, 1.0)
                    self.playbackCurrentSeconds = Int(p.currentTime)
                    if !p.isPlaying && self.playbackProgress >= 0.98 {
                        let finishedId = messageId
                        self.stopPlayback()
                        self.onPlaybackFinished?(finishedId)
                    }
                } else {
                    let elapsed = Date().timeIntervalSince(start)
                    self.playbackProgress = min(elapsed / self.simulatedDuration, 1.0)
                    self.playbackCurrentSeconds = Int(elapsed)
                    if elapsed >= self.simulatedDuration {
                        let finishedId = messageId
                        self.stopPlayback()
                        self.onPlaybackFinished?(finishedId)
                    }
                }
            }
        }
    }

    func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        player?.stop()
        player = nil
        playingMessageId = nil
        playbackProgress = 0
        playbackCurrentSeconds = 0
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            let finishedId = self.playingMessageId
            self.stopPlayback()
            if flag, let id = finishedId {
                self.onPlaybackFinished?(id)
            }
        }
    }

    private func resampleWaveform(_ raw: [CGFloat], targetCount: Int) -> [CGFloat] {
        guard !raw.isEmpty else {
            return (0..<targetCount).map { _ in CGFloat.random(in: 0.22...0.82) }
        }
        if raw.count <= targetCount {
            var padded = raw
            while padded.count < targetCount { padded.append(0.22) }
            return padded
        }
        let step = Double(raw.count) / Double(targetCount)
        return (0..<targetCount).map { i in
            let idx = min(Int(Double(i) * step), raw.count - 1)
            return raw[idx]
        }
    }
}
