$content = Get-Content -Path 'Views\Messages\ChatView.swift' -Raw -Encoding UTF8

$content = $content -replace '(?sm)                HStack\(spacing: 8\) \{.*?if messageText.isEmpty \{.*?Button\(action: \{\}\) \{.*?Image\(systemName: "mic.fill"\).*?\}', @"
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
"@

$content = $content -replace '^\xEF\xBB\xBF', ''

Set-Content -Path 'Views\Messages\ChatView.swift' -Value $content -Encoding UTF8
