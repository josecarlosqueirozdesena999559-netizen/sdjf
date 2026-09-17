const fs = require('fs');
let c = fs.readFileSync('ViewModels/AuthViewModel.swift', 'utf8');
c = c.replace(/let response_time: String\?/g, 'let avg_response_time: String?');
c = c.replace(/response_time: profile\.response_time/g, 'responseTime: profile.avg_response_time');
fs.writeFileSync('ViewModels/AuthViewModel.swift', c, 'utf8');
