const fs = require('fs');
const path = 'Views/Auth/RegisterView.swift';
let content = fs.readFileSync(path, 'utf8');

const strStart = 'PrimaryButton(title: "Concluir cadastro"';
const strEnd = 'dismiss()\n            }';
const idxStart = content.indexOf(strStart);
const idxEnd = content.indexOf(strEnd) + strEnd.length;

if (idxStart !== -1 && idxEnd !== -1) {
    const newBtn = 'PrimaryButton(title: "Concluir cadastro", isEnabled: !viewModel.visibleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) { viewModel.register(authViewModel: authViewModel) { dismiss() } }';
    content = content.substring(0, idxStart) + newBtn + content.substring(idxEnd);
}

fs.writeFileSync(path, content, 'utf8');
