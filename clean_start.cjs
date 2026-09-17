const fs = require('fs');
const path = require('path');

function cleanFiles(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== '.git') cleanFiles(fullPath);
        } else if (file.endsWith('.swift')) {
            let buffer = fs.readFileSync(fullPath);
            if (buffer.length >= 3 && buffer[0] === 0xef && buffer[1] === 0xbf && buffer[2] === 0xbd) {
                console.log('Found FFFD at start of ' + fullPath);
                buffer = buffer.slice(3);
                fs.writeFileSync(fullPath, buffer);
            }
            // Also check for UTF-8 BOM
            if (buffer.length >= 3 && buffer[0] === 0xef && buffer[1] === 0xbb && buffer[2] === 0xbf) {
                console.log('Found BOM at start of ' + fullPath);
                buffer = buffer.slice(3);
                fs.writeFileSync(fullPath, buffer);
            }
        }
    }
}
cleanFiles('.');
