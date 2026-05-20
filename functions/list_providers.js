const https = require('https');
const fs = require('fs');
const path = require('path');

async function run() {
  const configPath = path.join('C:', 'Users', 'Saalis Junejo', '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    console.error("Firebase tools config not found!");
    process.exit(1);
  }
  
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const accessToken = config.tokens.access_token;
  
  const url = "https://firestore.googleapis.com/v1/projects/hirein-4/databases/(default)/documents/providers";
  const urlObj = new URL(url);
  const options = {
    hostname: urlObj.hostname,
    path: urlObj.pathname,
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
    timeout: 10000,
  };

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      try {
        const responseJson = JSON.parse(data);
        console.log("Status:", res.statusCode);
        if (responseJson.documents) {
          console.log(`Found ${responseJson.documents.length} providers in Firestore:`);
          responseJson.documents.forEach((doc, i) => {
            const fields = doc.fields;
            console.log(`  ${i+1}. ID: ${doc.name.split('/').pop()}, Name: ${fields.name?.stringValue}, Category: ${fields.category?.stringValue}, Lat: ${fields.lat?.doubleValue || fields.lat?.integerValue}, Lng: ${fields.lng?.doubleValue || fields.lng?.integerValue}`);
          });
        } else {
          console.log("No providers found in Firestore.");
        }
      } catch (e) {
        console.error("Failed to parse response:", e);
      }
    });
  });

  req.on('error', console.error);
  req.end();
}

run().catch(console.error);
