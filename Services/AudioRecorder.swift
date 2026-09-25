import Foundation
import AVFoundation

@MainActor
final class AudioRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var powerLevels: [CGFloat] = []
    
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func start() async -> Bool {
        let permitted = await AVAudioApplication.requestRecordPermission()
        guard permitted else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
            recorder?.record()
            isRecording = true
            duration = 0
            powerLevels = []
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, let recorder = self.recorder, recorder.isRecording else { return }
                    self.duration += 0.1
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    // Normalize power from -160..0 to 0..1
                    let normalized = max(0, CGFloat(power + 160) / 160.0)
                    self.powerLevels.append(normalized)
                    if self.powerLevels.count > 30 {
                        self.powerLevels.removeFirst()
                    }
                }
            }
            
            return true
        } catch {
            print("Não foi possível iniciar a gravação: \(error)")
            return false
        }
    }

    func stop() -> URL? {
        timer?.invalidate()
        timer = nil
        
        guard let recorder else { return nil }
        recorder.stop()
        self.recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return recorder.url
    }
}