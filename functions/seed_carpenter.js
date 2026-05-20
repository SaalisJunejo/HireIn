const https = require('https');
const fs = require('fs');
const path = require('path');

async function run() {
  console.log("Reading firebase-tools credentials...");
  
  const configPath = path.join('C:', 'Users', 'Saalis Junejo', '.config', 'configstore', 'firebase-tools.json');
  
  if (!fs.existsSync(configPath)) {
    console.error("Firebase tools config not found at:", configPath);
    process.exit(1);
  }
  
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const accessToken = config.tokens.access_token;
  
  if (!accessToken) {
    console.error("Access token not found in firebase-tools.json");
    process.exit(1);
  }
  
  console.log("Access token found! Seeding Carpenter provider near Shahi Bazar, Hyderabad...");

  const docData = {
    fields: {
      id: { stringValue: "provider_shahi_carp_001" },
      name: { stringValue: "Ustad Ghulam Carpentry" },
      category: { stringValue: "Carpenter" },
      lat: { doubleValue: 25.3810 },
      lng: { doubleValue: 68.3670 },
      rating: { doubleValue: 4.6 },
      baseRatePkr: { integerValue: "1200" },
      pkrPerKm: { integerValue: "40" },
      urgentSurcharge: { integerValue: "400" },
      approvalStatus: { stringValue: "approved" },
      available: { booleanValue: true }
    }
  };

  const body = JSON.stringify(docData);

  const url = "https://firestore.googleapis.com/v1/projects/hirein-4/databases/(default)/documents/providers/provider_shahi_carp_001";
  
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
      console.log(`Firestore REST API responded with status code: ${res.statusCode}`);
      try {
        const responseJson = JSON.parse(data);
        if (res.statusCode === 200) {
          console.log("✅ SUCCESS: Carpenter provider seeded to production Firestore!");
          console.log("Document URI:", responseJson.name);
          console.log("Fields:", JSON.stringify(responseJson.fields, null, 2));
          process.exit(0);
        } else {
          console.error("ERROR:", responseJson);
          process.exit(1);
        }
      } catch (e) {
        console.error("ERROR: Raw response:", data);
        process.exit(1);
      }
    });
  });

  req.on('error', (err) => {
    console.error("HTTP error:", err);
    process.exit(1);
  });

  req.on('timeout', () => {
    req.destroy();
    console.error("Timeout!");
    process.exit(1);
  });

  req.write(body);
  req.end();
}

run().catch(console.error);
