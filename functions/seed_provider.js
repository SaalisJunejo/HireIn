const https = require('https');
const fs = require('fs');
const path = require('path');

async function run() {
  console.log("Reading firebase-tools credentials...");
  
  // Path to firebase-tools config
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
  
  console.log("Access token found! Using Firestore REST API to write provider document...");

  // Firestore REST API expects documents in specific format
  const docData = {
    fields: {
      id: { stringValue: "provider_g13_ac_001" },
      name: { stringValue: "Ali AC Services" },
      category: { stringValue: "AC Technician" },
      lat: { doubleValue: 33.6350 },
      lng: { doubleValue: 73.0200 },
      rating: { doubleValue: 4.7 },
      baseRatePkr: { integerValue: "1500" },
      pkrPerKm: { integerValue: "50" },
      urgentSurcharge: { integerValue: "500" },
      approvalStatus: { stringValue: "approved" },
      available: { booleanValue: true }
    }
  };

  const body = JSON.stringify(docData);

  // Firestore REST API Endpoint for write (PATCH to update or create)
  const url = "https://firestore.googleapis.com/v1/projects/hirein-4/databases/(default)/documents/providers/provider_g13_ac_001";
  
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
          console.log("SUCCESS: Provider seeded successfully to production Firestore!");
          console.log("Verified Document URI:", responseJson.name);
          console.log("Verified Fields:", JSON.stringify(responseJson.fields, null, 2));
          process.exit(0);
        } else {
          console.error("ERROR: Firestore REST API failed with:", responseJson);
          process.exit(1);
        }
      } catch (e) {
        console.error("ERROR: Failed to parse response JSON. Raw response:", data);
        process.exit(1);
      }
    });
  });

  req.on('error', (err) => {
    console.error("HTTP request error:", err);
    process.exit(1);
  });

  req.on('timeout', () => {
    req.destroy();
    console.error("HTTP request timed out!");
    process.exit(1);
  });

  req.write(body);
  req.end();
}

run().catch(console.error);
