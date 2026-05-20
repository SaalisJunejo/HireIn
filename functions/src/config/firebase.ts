import * as admin from 'firebase-admin';

// Generic Firebase initialization
admin.initializeApp();

export const db = admin.firestore();
