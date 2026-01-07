/**
 * Script to verify and fix user documents in Firestore
 * 
 * This script ensures:
 * 1. User documents exist with correct document IDs (matching auth UID)
 * 2. User documents have all required fields
 * 3. Custom claims are set correctly in Firebase Auth
 * 
 * Usage:
 *   node scripts/fix_user_documents_cli.js
 * 
 * Prerequisites:
 *   - Firebase Admin SDK service account key at firebase/service-account-key.json
 *   - Node.js installed
 *   - Run: npm install firebase-admin
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '..', 'firebase', 'service-account-key.json');

try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK');
    console.error('   Make sure firebase/service-account-key.json exists');
    console.error('   Error:', error.message);
    process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

// Test user data from the prompt
const TEST_USERS = [
    {
        email: 'ahmed.zouari@etudiant.isetcom.tn',
        uid: 'student_ahmed_zouari',
        role: 'student',
        displayName: 'Ahmed Zouari',
        pocket: 35.75,
        tickets: 0
    },
    {
        email: 'karim.khelifi@isetcom.tn',
        uid: 'admin_karim_khelifi',
        role: 'admin',
        displayName: 'Karim Khelifi',
        pocket: 0,
        tickets: 0
    }
];

async function verifyAndFixUserDocument(userData) {
    console.log(`\n📋 Processing user: ${userData.email}`);

    try {
        // Step 1: Check if Firebase Auth user exists
        let authUser;
        try {
            authUser = await auth.getUserByEmail(userData.email);
            console.log(`   ✅ Auth user exists: ${authUser.uid}`);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                console.log(`   ⚠️ Auth user not found, creating...`);
                authUser = await auth.createUser({
                    email: userData.email,
                    password: 'Test123!',
                    displayName: userData.displayName,
                    uid: userData.uid
                });
                console.log(`   ✅ Auth user created: ${authUser.uid}`);
            } else {
                throw error;
            }
        }

        // Step 2: Set custom claims for role
        console.log(`   📝 Setting custom claims (role: ${userData.role})...`);
        await auth.setCustomUserClaims(authUser.uid, { role: userData.role });
        console.log(`   ✅ Custom claims set`);

        // Step 3: Check/create Firestore user document
        // Document ID should match the auth UID
        const userDocRef = db.collection('user').doc(authUser.uid);
        const userDoc = await userDocRef.get();

        if (!userDoc.exists) {
            console.log(`   ⚠️ Firestore document not found, creating...`);
            await userDocRef.set({
                email: userData.email,
                uid: authUser.uid,
                display_name: userData.displayName,
                nom: userData.displayName,
                role: userData.role,
                pocket: userData.pocket,
                tickets: userData.tickets,
                created_time: admin.firestore.FieldValue.serverTimestamp(),
                language: 'fr',
                notifications_enabled: true
            });
            console.log(`   ✅ Firestore document created`);
        } else {
            console.log(`   ✅ Firestore document exists`);

            // Verify required fields
            const data = userDoc.data();
            const updates = {};

            if (!data.uid) updates.uid = authUser.uid;
            if (!data.role) updates.role = userData.role;
            if (data.pocket === undefined) updates.pocket = userData.pocket;
            if (data.tickets === undefined) updates.tickets = userData.tickets;

            if (Object.keys(updates).length > 0) {
                console.log(`   📝 Updating missing fields:`, Object.keys(updates));
                await userDocRef.update(updates);
                console.log(`   ✅ Fields updated`);
            } else {
                console.log(`   ✅ All required fields present`);
            }

            // Log current data
            console.log(`   📊 Current data:`);
            console.log(`      - pocket: ${data.pocket}`);
            console.log(`      - role: ${data.role}`);
            console.log(`      - uid: ${data.uid}`);
        }

        return { success: true, uid: authUser.uid };

    } catch (error) {
        console.error(`   ❌ Error processing user: ${error.message}`);
        return { success: false, error: error.message };
    }
}

async function verifyFirestoreRules() {
    console.log('\n🔒 Verifying Firestore access...');

    try {
        // Try to read from collections
        const collections = ['user', 'reservation', 'time_slots', 'daily_reservation_counters', 'payment_transactions'];

        for (const collection of collections) {
            try {
                const snapshot = await db.collection(collection).limit(1).get();
                console.log(`   ✅ ${collection}: accessible (${snapshot.size} docs)`);
            } catch (error) {
                console.log(`   ❌ ${collection}: ${error.message}`);
            }
        }
    } catch (error) {
        console.error('   ❌ Error verifying rules:', error.message);
    }
}

async function checkExistingReservations(userId) {
    console.log(`\n📅 Checking existing reservations for ${userId}...`);

    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const reservations = await db.collection('reservation')
            .where('user_id', '==', userId)
            .get();

        console.log(`   Found ${reservations.size} total reservations`);

        reservations.forEach(doc => {
            const data = doc.data();
            console.log(`   - ${doc.id}: ${data.meal_type} - ${data.status}`);
        });

    } catch (error) {
        console.error(`   ❌ Error checking reservations: ${error.message}`);
    }
}

async function checkDailyCounters(userId) {
    console.log(`\n📊 Checking daily counters for ${userId}...`);

    try {
        const today = new Date();
        const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
        const counterId = `${userId}_${dateStr}`;

        const counterDoc = await db.collection('daily_reservation_counters').doc(counterId).get();

        if (counterDoc.exists) {
            const data = counterDoc.data();
            console.log(`   ✅ Counter exists:`);
            console.log(`      - lunch_count: ${data.lunch_count || 0}`);
            console.log(`      - dinner_count: ${data.dinner_count || 0}`);
        } else {
            console.log(`   ℹ️ No counter for today (user hasn't made reservations)`);
        }

    } catch (error) {
        console.error(`   ❌ Error checking counters: ${error.message}`);
    }
}

async function main() {
    console.log('🚀 User Document Verification and Fix Script');
    console.log('============================================\n');

    // Process test users
    for (const user of TEST_USERS) {
        const result = await verifyAndFixUserDocument(user);

        if (result.success) {
            await checkExistingReservations(result.uid);
            await checkDailyCounters(result.uid);
        }
    }

    // Verify Firestore rules
    await verifyFirestoreRules();

    console.log('\n✅ Script completed!');
    console.log('\n📝 Next steps:');
    console.log('   1. Deploy Firestore rules: firebase deploy --only firestore:rules');
    console.log('   2. Test reservation flow in the app');
    console.log('   3. Check Firebase Console for any remaining issues');

    process.exit(0);
}

main().catch(error => {
    console.error('❌ Script failed:', error);
    process.exit(1);
});
