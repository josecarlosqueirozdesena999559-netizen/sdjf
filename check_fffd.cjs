const fs = require('fs');
const path = require('path');

function checkFFFD(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== '.git') checkFFFD(fullPath);
        } else if (file.endsWith('.swift')) {
            let buffer = fs.readFileSync(fullPath);
            if (buffer.indexOf(Buffer.from([0xef, 0xbf, 0xbd])) !== -1) {
                console.log('FFFD inside ' + fullPath);
            }
        }
    }
}
checkFFFD('.');
