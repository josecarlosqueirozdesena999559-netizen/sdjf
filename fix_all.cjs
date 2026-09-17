const fs = require('fs');
const path = require('path');

const replacements = {
    'UsuÃ¡rio': 'Usuário',
    'usuÃ¡rio': 'usuário',
    'EletrÃ´nicos': 'Eletrônicos',
    'acessÃ³rios': 'acessórios',
    'EletrodomÃ©sticos': 'Eletrodomésticos',
    'fogÃµes': 'fogões',
    'calÃ§ados': 'calçados',
    'MÃ³veis': 'Móveis',
    'decoraÃ§Ã£o': 'decoração',
    'VeÃ\xadculos': 'Veículos', // Note: Ã­ is sometimes weird
    'VeÃ­culos': 'Veículos',
    'CosmÃ©ticos': 'Cosméticos',
    'mÃ£os': 'mãos',
    'SÃ£o Paulo': 'São Paulo',
    'versÃ£o': 'versão',
    'AtenÃ§Ã£o': 'Atenção',
    'ExibiÃ§Ã£o': 'Exibição',
    'JoÃ£o': 'João',
    'aparecerÃ¡': 'aparecerá',
    'vocÃª': 'você',
    'Ã©': 'é',
    'localizaÃ§Ã£o': 'localização',
    'prÃ³ximos': 'próximos'
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
