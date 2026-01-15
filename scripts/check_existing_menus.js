const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with service account
const serviceAccountPath = path.join(__dirname, '..', 'firebase', 'service-account-key.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkExistingMenus() {
    try {
        console.log('🔍 Checking existing menus in Firestore...');

        // Get all existing menus
        const menusSnapshot = await db.collection('daily_menu').get();

        if (menusSnapshot.empty) {
            console.log('❌ No menus found in database');
            return;
        }

        console.log(`📊 Found ${menusSnapshot.docs.length} menus in database`);
        console.log('\n📋 Menu Details:');
        console.log('================');

        menusSnapshot.docs.forEach((doc, index) => {
            const data = doc.data();
            console.log(`\n${index + 1}. Menu ID: ${doc.id}`);
            console.log(`   Day of Week: ${data.day_of_week || 'NOT SET'}`);
            console.log(`   Meal Type: ${data.meal_type || 'NOT SET'}`);
            console.log(`   Main Dish: "${data.main_dish || 'EMPTY'}"`);
            console.log(`   Salad: "${data.salad || 'EMPTY'}"`);
            console.log(`   Dessert: "${data.dessert || 'EMPTY'}"`);
            console.log(`   Accompaniments: ${JSON.stringify(data.accompaniments || [])}`);
            console.log(`   Description: "${data.description || 'EMPTY'}"`);
            console.log(`   Price: ${data.price || 'NOT SET'}`);
            console.log(`   Available: ${data.available !== undefined ? data.available : 'NOT SET'}`);
        });

        // Check for empty fields
        const emptyMainDish = menusSnapshot.docs.filter(doc => !doc.data().main_dish || doc.data().main_dish.trim() === '');
        const emptySalad = menusSnapshot.docs.filter(doc => !doc.data().salad || doc.data().salad.trim() === '');
        const emptyDessert = menusSnapshot.docs.filter(doc => !doc.data().dessert || doc.data().dessert.trim() === '');

        console.log('\n🔍 Analysis:');
        console.log('============');
        console.log(`📊 Total menus: ${menusSnapshot.docs.length}`);
        console.log(`🍽️ Menus with empty main_dish: ${emptyMainDish.length}`);
        console.log(`🥗 Menus with empty salad: ${emptySalad.length}`);
        console.log(`🍰 Menus with empty dessert: ${emptyDessert.length}`);

        if (emptyMainDish.length > 0 || emptySalad.length > 0 || emptyDessert.length > 0) {
            console.log('\n⚠️ ISSUE FOUND: Some menus have empty dish fields!');
            console.log('This is why you only see icons (🍴, 🥗, 🍰) but no dish names.');
            console.log('\n💡 SOLUTION: You need to either:');
            console.log('1. Edit each menu through the UI (pen icon) and add dish names');
            console.log('2. Or run a script to populate the missing fields');
        } else {
            console.log('\n✅ All menus have proper dish names - the issue might be elsewhere');
        }

    } catch (error) {
        console.error('❌ Error checking menus:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run the script
checkExistingMenus();