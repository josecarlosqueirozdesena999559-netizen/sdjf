const fs = require('fs');
const jwt = require('jsonwebtoken');

const keyId = 'Y7S65HKRPV';
const issuerId = '69a6de90-4355-4c55-e053-5b8c7c11a4d1';
const privateKey = fs.readFileSync('C:/Users/KENEDI/Downloads/AuthKey_' + keyId + '.p8', 'utf8');

const token = jwt.sign({}, privateKey, {
  algorithm: 'ES256',
  expiresIn: '20m',
  issuer: issuerId,
  audience: 'appstoreconnect-v1',
  header: {
    alg: 'ES256',
    kid: keyId,
    typ: 'JWT'
  }
});

fetch('https://api.appstoreconnect.apple.com/v1/apps', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
}).then(res => res.json()).then(data => {
  if (data.data) {
    data.data.forEach(app => {
      console.log(App:  + app.attributes.name +  | Bundle ID:  + app.attributes.bundleId +  | ID:  + app.id);
    });
  } else {
    console.log(data);
  }
});
