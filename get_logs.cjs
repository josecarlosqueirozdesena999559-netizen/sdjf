const https = require('https');
const url = 'https://api.github.com/repos/josecarlosqueirozdesena999559-netizen/sdjf/actions/jobs/105206839041/logs';
const options = {
    headers: {
        'User-Agent': 'Node.js',
        'Accept': 'application/vnd.github.v3+json'
    }
};

function getLog(urlStr) {
    https.get(urlStr, options, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
            getLog(res.headers.location);
        } else {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                const fs = require('fs');
                fs.writeFileSync('build_log.txt', data);
                console.log('Saved log');
            });
        }
    });
}
getLog(url);
