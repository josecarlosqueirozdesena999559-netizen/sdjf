$content = Get-Content -Path 'Views\Messages\ChatView.swift' -Raw -Encoding UTF8

$content = $content.Replace('@State private var selectedAttachment: PhotosPickerItem? = nil', "@State private var selectedAttachment: PhotosPickerItem? = nil`n    @State private var isRecordingAudio = false")

$old_tf = @"
                HStack(spacing: 8) {
                    TextField("Mensagem...", text: `$messageText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    
                    if messageText.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.trailing, 12)
                        }
                    } else {
"@

$new_tf = @"
                HStack(spacing: 8) {
                    if isRecordingAudio {
                        AudioWaveView()
                            .frame(height: 40)
                            .padding(.horizontal)
                        Spacer()
                    } else {
                        TextField("Mensagem...", text: `$messageText)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                    }
                    
                    if messageText.isEmpty {
                        Button(action: {
                            if isRecordingAudio {
                                let newMsg = Message(id: UUID(), senderId: authViewModel.currentUser?.id ?? UUID(), receiverId: conversation.participantId, text: "🎵 Mensagem de Voz", timestamp: Date(), isRead: false)
                                messages.append(newMsg)
                                isRecordingAudio = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    chatStatus = "online"
                                    for i in 0..<messages.count {
                                        if messages[i].senderId != conversation.participantId { messages[i].isRead = true }
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { chatStatus = "gravando áudio..." }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    messages.append(Message(id: UUID(), senderId: conversation.participantId, receiverId: authViewModel.currentUser?.id ?? UUID(), text: "🎵 Áudio (0:12)", timestamp: Date(), isRead: true))
                                    chatStatus = "online"
                                }
                            } else {
                                isRecordingAudio = true
                            }
                        }) {
                            Image(systemName: isRecordingAudio ? "paperplane.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isRecordingAudio ? Theme.primary : Theme.textSecondary)
                                .padding(.trailing, 12)
                        }
                    } else {
"@

$content = $content.Replace($old_tf, $new_tf)

$audio_wave = @"

struct AudioWaveView: View {
    @State private var drawingHeight = true
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.primary)
                    .frame(width: 4, height: drawingHeight ? CGFloat.random(in: 10...30) : CGFloat.random(in: 10...30))
                    .animation(
                        Animation.easeInOut(duration: 0.2)
                            .repeatForever()
                            .delay(Double(index) * 0.05),
                        value: drawingHeight
                    )
            }
        }
        .onAppear {
            drawingHeight.toggle()
        }
    }
}
"@

if ($content -notmatch 'struct AudioWaveView') {
    $content += $audio_wave
}

Set-Content -Path 'Views\Messages\ChatView.swift' -Value $content -Encoding UTF8
