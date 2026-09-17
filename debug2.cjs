const fs = require('fs');
let buffer = fs.readFileSync('Views/Auth/RegisterView.swift');
let idx = buffer.indexOf(Buffer.from('Qual ', 'utf8'));
if (idx !== -1) {
    console.log(buffer.slice(idx, idx + 20));
}
