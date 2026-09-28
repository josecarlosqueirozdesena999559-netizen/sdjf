const crypto = require('crypto');
const fs = require('fs');

const keyId = 'Y7S65HKRPV';
const issuerId = '69a6de90-4355-4c55-e053-5b8c7c11a4d1';
const privateKey = fs.readFileSync('C:\\Users\\KENEDI\\Downloads\\AuthKey_Y7S65HKRPV.p8', 'utf8');

const header = { alg: 'ES256', kid: keyId, typ: 'JWT' };
const payload = {
    iss: issuerId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 1200,
    aud: 'appstoreconnect-v1'
};

const base64url = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
const signInput = base64url(header) + '.' + base64url(payload);

const ecdsaSign = crypto.createSign('SHA256');
ecdsaSign.update(signInput);
const signature = ecdsaSign.sign(privateKey, 'base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

const jwt = signInput + '.' + signature;
console.log(jwt);
