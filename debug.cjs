const fs = require('fs');
let content = fs.readFileSync('Views/Auth/RegisterView.swift', 'utf8');
let idx = content.indexOf('Qual ');
console.log(content.charCodeAt(idx + 5));
