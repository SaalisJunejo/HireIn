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

  const providerData = {
    fields: {
      id: { stringValue: "provider_hyd_elec_001" },
      name: { stringValue: "Sajjad Electrician" },
      category: { stringValue: "Electrician" },
      lat: { doubleValue: 25.3950 },
      lng: { doubleValue: 68.3580 },
      rating: { doubleValue: 4.8 },
      baseRatePkr: { integerValue: "800" },
      pkrPerKm: { integerValue: "30" },
      urgentSurcharge: { integerValue: "300" },
      approvalStatus: { stringValue: "approved" },
      available: { booleanValue: true }
    }
  };

  const body = JSON.stringify(providerData);
  const url = "https://firestore.googleapis.com/v1/projects/hirein-4/databases/(default)/documents/providers/provider_hyd_elec_001";
  
  const urlObj = new URL(url);
  const options = {
    hostname: urlObj.hostname,
    path: urlObj.pathname,
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
    },
    timeout: 10000,
  };

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      try {
        const responseJson = JSON.parse(data);
        if (res.statusCode === 200) {
          console.log("SUCCESS: Electrician provider seeded successfully to Hyderabad, Sindh!");
          console.log("Verified Document URI:", responseJson.name);
          process.exit(0);
        } else {
          console.error("ERROR: Failed to seed:", responseJson);
          process.exit(1);
        }
      } catch (e) {
        console.error("ERROR: Failed to parse response:", data);
        process.exit(1);
      }
    });
  });

  req.on('error', console.error);
  req.write(body);
  req.end();
}

run().catch(console.error);
