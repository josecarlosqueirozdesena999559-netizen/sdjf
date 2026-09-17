const fs = require('fs');
const path = require('path');

function fixMojibake(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== '.git') fixMojibake(fullPath);
        } else if (file.endsWith('.swift')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            try {
                // If it contains Ã, it's likely mojibake
                if (content.includes('Ã')) {
                    let fixed = Buffer.from(content, 'latin1').toString('utf8');
                    fs.writeFileSync(fullPath, fixed, 'utf8');
                    console.log('Fixed: ' + fullPath);
                }
            } catch (e) {}
        }
    }
}

fixMojibake('.');
