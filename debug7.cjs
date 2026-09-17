const fs = require('fs');
let content = fs.readFileSync('Views/Messages/ChatView.swift', 'utf8');
let lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('\uFFFD')) {
        console.log('Line ' + (i+1) + ': ' + lines[i]);
    }
}
