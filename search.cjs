const https = require('https');
https.get('https://api.github.com/search/code?q=protocol+repo:supabase/supabase-swift+path:Sources/Auth', { headers: { 'User-Agent': 'Node.js' } }, (res) => {
    let data = '';
    res.on('data', d => data += d);
    res.on('end', () => console.log(data.slice(0, 500)));
});
