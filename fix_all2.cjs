const fs = require('fs');
const path = require('path');

const replacements = {
    'Qual Ǹ': 'Qual é',
    'Usuǭrio': 'Usuário',
    'usuǭrio': 'usuário',
    'nǜo': 'não',
    'Localizaǜo': 'Localização',
    'nmeros': 'números',
    'invlido': 'inválido',
    'j est': 'já está',
    'usurio': 'usuário',
    'mnimo': 'mínimo',
    'mǜos': 'mãos',
    'decoraǜo': 'decoração',
    'Eletrnicos': 'Eletrônicos',
    'EletrodomǸsticos': 'Eletrodomésticos',
    'calados': 'calçados',
    'Veculos': 'Veículos',
    'CosmǸticos': 'Cosméticos',
    'Sǜo Paulo': 'São Paulo',
    'versǜo': 'versão',
    'Notificaes': 'Notificações',
    'permissǜo': 'permissão',
    'notificaǜo': 'notificação',
    'Atenǜo': 'Atenção',
    'Exibiǜo': 'Exibição',
    'Joǜo': 'João',
    'aparecerǭ': 'aparecerá',
    'vocǸ': 'você',
    'prximos': 'próximos'
};

function processDirectory(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== '.git') processDirectory(fullPath);
        } else if (file.endsWith('.swift')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            let changed = false;
            for (const [bad, good] of Object.entries(replacements)) {
                if (content.includes(bad)) {
                    content = content.split(bad).join(good);
                    changed = true;
                }
            }
            if (changed) {
                fs.writeFileSync(fullPath, content, 'utf8');
            }
        }
    }
}

processDirectory('.');
