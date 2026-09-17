const fs = require('fs');
let c = fs.readFileSync('Views/Auth/RegisterView.swift', 'utf8');
c = c.replace(/viewModel\.register\(authViewModel: authViewModel\) \{[\s\S]*?dismiss\(\)\n\s*\}/g, 'viewModel.register(authViewModel: authViewModel) { }');
fs.writeFileSync('Views/Auth/RegisterView.swift', c, 'utf8');
