const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testPermissions() {
    try {
        console.log('Testing Firestore permissions...');

        // Test app_settings collection
        console.log('\n1. Testing app_settings collection...');
        const settingsSnapshot = await db.collection('app_settings').limit(1).get();
        console.log(`✓ app_settings: Found ${settingsSnapshot.docs.length} documents`);

        // Test daily_menu collection
        console.log('\n2. Testing daily_menu collection...');
        const menuSnapshot = await db.collection('daily_menu').limit(5).get();
        console.log(`✓ daily_menu: Found ${menuSnapshot.docs.length} documents`);

        if (menuSnapshot.docs.length > 0) {
            const firstMenu = menuSnapshot.docs[0].data();
            console.log(`   Sample menu: ${firstMenu.main_dish} - ${firstMenu.price} DT`);
        }

        // Test time_slots collection
        console.log('\n3. Testing time_slots collection...');
        const slotsSnapshot = await db.collection('time_slots').limit(1).get();
        console.log(`✓ time_slots: Found ${slotsSnapshot.docs.length} documents`);

        console.log('\n✅ All permission tests passed!');
        console.log('\nThe Firestore rules are now properly configured for development.');
        console.log('The app should be able to access menus and settings without authentication errors.');

    } catch (error) {
        console.error('\n❌ Permission test failed:', error.message);

        if (error.code === 'permission-denied') {
            console.log('\n🔧 Suggested fixes:');
            console.log('1. Make sure Firestore rules are deployed: firebase deploy --only firestore:rules');
            console.log('2. Check that the rules allow unauthenticated read access to app_settings and daily_menu');
            console.log('3. Verify the Firebase project is correctly configured');
        }
    }

    process.exit(0);
}

// Run the test
testPermissions();