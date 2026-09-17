const fs = require('fs');
let c1 = fs.readFileSync('ViewModels/RegisterViewModel.swift', 'utf8');
c1 = c1.replace(/\ufffd necess\ufffdrio/g, 'É necessário');
c1 = c1.replace(/endere\ufffdo/g, 'endereço');
c1 = c1.replace(/v\ufffdlido/g, 'válido');
c1 = c1.replace(/usu\ufffdrio/g, 'usuário');
c1 = c1.replace(/Usu\ufffdrio/g, 'Usuário');
fs.writeFileSync('ViewModels/RegisterViewModel.swift', c1, 'utf8');

let c2 = fs.readFileSync('Views/Messages/ChatView.swift', 'utf8');
c2 = c2.replace(/AVALIA\ufffd\ufffdO/g, 'AVALIAÇÃO');
c2 = c2.replace(/Avalia\ufffd\ufffdo/g, 'Avaliação');
c2 = c2.replace(/avalia\ufffd\ufffdo/g, 'avaliação');
c2 = c2.replace(/<\ufffd/g, '🎤'); // wait, '<' was probably a microphone emoji?
c2 = c2.replace(/=\ufffd/g, '📷'); // '=' was probably a camera emoji?
c2 = c2.replace(/M\ufffddia/g, 'Mídia');
c2 = c2.replace(/\ufffdudio/g, 'áudio');
c2 = c2.replace(/neg\ufffdcio/g, 'negócio');
c2 = c2.replace(/\ufffdltimo/g, 'último');
c2 = c2.replace(/\ufffds /g, 'às ');
c2 = c2.replace(/experi\ufffdncia/g, 'experiência');
c2 = c2.replace(/coment\ufffdrio/g, 'comentário');
c2 = c2.replace(/confi\ufffdvel/g, 'confiável');
fs.writeFileSync('Views/Messages/ChatView.swift', c2, 'utf8');
