const fs = require('fs');
let buffer = fs.readFileSync('ViewModels/RegisterViewModel.swift');
let idx = buffer.indexOf(Buffer.from('11 n', 'utf8'));
if (idx !== -1) {
    console.log(buffer.slice(idx, idx + 20).toString('hex'));
}
