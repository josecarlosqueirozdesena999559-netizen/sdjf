const fs = require('fs');
const path = 'Views/Auth/RegisterView.swift';
let content = fs.readFileSync(path, 'utf8');

// Replace button
const regexBtn = /PrimaryButton\(title: "Concluir cadastro"[\s\S]*?dismiss\(\)\n\s*\}/;
const newBtn = 'PrimaryButton(title: "Concluir cadastro", isEnabled: !viewModel.visibleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) { viewModel.register(authViewModel: authViewModel) { dismiss() } }';
if(content.match(regexBtn)) {
    content = content.replace(regexBtn, newBtn);
}

// Add green text
const regexText = /TextField\("seu\.usuario", text: \\\\.username\)[\s\S]*?\.overlay\(RoundedRectangle\(cornerRadius: 12\)\.stroke\(Theme\.border, lineWidth: 1\)\)/;
const textToInsert = '\n                if !viewModel.username.isEmpty && viewModel.username.count >= 3 && viewModel.errorMessage == nil {\n                    Text("Nome de usuário disponível")\n                        .font(.caption)\n                        .foregroundColor(Theme.primary)\n                }';
const match = content.match(regexText);
if (match && !content.includes('Nome de usuário disponível')) {
    content = content.replace(match[0], match[0] + textToInsert);
}

fs.writeFileSync(path, content, 'utf8');
