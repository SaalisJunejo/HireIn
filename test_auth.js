const admin = require('firebase-admin');
admin.initializeApp({
  projectId: 'hirein-4'
});
const db = admin.firestore();
db.collection('providers').get()
  .then(snapshot => {
    console.log('Successfully connected! Document count:', snapshot.size);
    process.exit(0);
  })
  .catch(err => {
    console.error('Connection failed:', err);
    process.exit(1);
  });
