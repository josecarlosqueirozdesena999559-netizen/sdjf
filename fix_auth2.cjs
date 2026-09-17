const fs = require('fs');
let c = fs.readFileSync('ViewModels/AuthViewModel.swift', 'utf8');
c = c.replace(/responseTime: profile\.response_time/g, 'responseTime: profile.avg_response_time');
c = c.replace(/Usuǭrio/g, 'Usuário');
c = c.replace(/Usu\xef\xbf\xbd\xef\xbf\xbdrio/g, 'Usuário'); // FFFD fallback
c = c.replace(/nǜo/g, 'não');
fs.writeFileSync('ViewModels/AuthViewModel.swift', c, 'utf8');
