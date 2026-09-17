const fs = require('fs');
const path = require('path');

function processDirectory(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== '.git') processDirectory(fullPath);
        } else if (file.endsWith('.swift')) {
            let buffer = fs.readFileSync(fullPath);
            // Decode as latin1, encode to utf8
            let content = buffer.toString('latin1');
            fs.writeFileSync(fullPath, content, 'utf8');
        }
    }
}

processDirectory('.');
