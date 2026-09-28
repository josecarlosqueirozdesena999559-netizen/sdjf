const fs = require('fs');
let content = fs.readFileSync('Views/Messages/ChatView.swift', 'utf8');

content = content.replace(/aÁÁudioRecorder/g, 'audioRecorder');
content = content.replace(/AÁudioRecorder/g, 'AudioRecorder');
content = content.replace(/aÁÁudioPlayer/g, 'audioPlayer');
content = content.replace(/playAÁudio/g, 'playAudio');
content = content.replace(/AVAÁudioSession/g, 'AVAudioSession');
content = content.replace(/ÁÁudio/g, 'Áudio');
content = content.replace(/áÁudio/g, 'áudio');
content = content.replace(/UsuÃ¡rio/g, 'Usuário');
content = content.replace(/Ãºltimo/g, 'último');

fs.writeFileSync('Views/Messages/ChatView.swift', content, 'utf8');
