const fs = require('fs');
let c = fs.readFileSync('ViewModels/RegisterViewModel.swift', 'utf8');
c = c.replace(/let response_time: String\?/g, 'let avg_response_time: String?');
c = c.replace(/response_time: nil/g, 'avg_response_time: nil');
fs.writeFileSync('ViewModels/RegisterViewModel.swift', c, 'utf8');
