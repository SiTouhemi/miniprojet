#!/usr/bin/env node

/**
 * Verify Test Users Script
 * Checks if test users were created correctly in Firebase Auth and Firestore
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const testEmails = [
    'admin.test@isetcom.tn',
    'staff.test@isetcom.tn',
    'student1.test@isetcom.tn',
    'student2.test@isetcom.tn'
];

async function verifyTestUsers() {
    console.log('🔍 Verifying Test Users...\n');

    for (const email of testEmails) {
        try {
            console.log(`Checking: ${email}`);

            // Check Firebase Auth
            const authUser = await auth.getUserByEmail(email);
            console.log(`  ✅ Auth: Found user (UID: ${authUser.uid})`);

            // Check custom claims
            const customClaims = authUser.customClaims || {};
            if (customClaims.role) {
                console.log(`  ✅ Claims: Role = ${customClaims.role}`);
            } else {
                console.log(`  ❌ Claims: No role found`);
            }

            // Check Firestore document
            const userDoc = await db.collection('user').doc(authUser.uid).get();
            if (userDoc.exists) {
                const userData = userDoc.data();
                console.log(`  ✅ Firestore: Document exists (Role: ${userData.role})`);
                console.log(`  📝 Details: ${userData.displayName} - ${userData.classe}`);
            } else {
                console.log(`  ❌ Firestore: Document not found`);
            }

            console.log('');

        } catch (error) {
            console.log(`  ❌ Error: ${error.message}\n`);
        }
    }

    console.log('🎯 Verification complete!');
    console.log('\nNext steps:');
    console.log('1. Run: flutter run');
    console.log('2. Test login with any of the accounts above');
    console.log('3. Password for all accounts: Test123!');
}

verifyTestUsers().then(() => process.exit(0));