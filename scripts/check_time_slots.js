/**
 * Script to check existing time slots in Firestore
 * 
 * This script helps debug why time slots aren't showing in the modification dialog.
 * 
 * Usage:
 *   node scripts/check_time_slots.js
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

async function checkTimeSlots() {
    console.log('🕐 Checking Time Slots');
    console.log('=====================\n');

    try {
        // Get all time slots
        const timeSlotsSnapshot = await db.collection('time_slots').get();

        console.log(`📊 Found ${timeSlotsSnapshot.size} time slot documents`);

        if (timeSlotsSnapshot.empty) {
            console.log('⚠️ No time slots found in database');
            console.log('   This explains why the modification dialog is empty');
            console.log('   You need to create time slots first');
            return;
        }

        console.log('\n📋 Time Slot Details:');
        console.log('=====================\n');

        for (const doc of timeSlotsSnapshot.docs) {
            const data = doc.data();

            console.log(`📄 ${doc.id}:`);
            console.log(`   - date: ${data.date ? new Date(data.date.seconds * 1000).toLocaleDateString() : 'N/A'}`);
            console.log(`   - start_time: ${data.start_time ? new Date(data.start_time.seconds * 1000).toLocaleString() : 'N/A'}`);
            console.log(`   - end_time: ${data.end_time ? new Date(data.end_time.seconds * 1000).toLocaleString() : 'N/A'}`);
            console.log(`   - meal_type: ${data.meal_type || 'N/A'}`);
            console.log(`   - is_active: ${data.is_active !== undefined ? data.is_active : 'N/A'}`);
            console.log(`   - max_capacity: ${data.max_capacity || 'N/A'}`);
            console.log(`   - current_reservations: ${data.current_reservations || 0}`);
            console.log(`   - price: ${data.price || 'N/A'} TND`);
            console.log('');
        }

        // Check for today's slots specifically
        const today = new Date();
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);

        console.log(`🔍 Checking for today's slots (${startOfDay.toLocaleDateString()}):`);
        console.log('='.repeat(60));

        const todaySlots = await db.collection('time_slots')
            .where('date', '>=', startOfDay)
            .where('date', '<', endOfDay)
            .where('is_active', '==', true)
            .get();

        console.log(`📊 Found ${todaySlots.size} active slots for today`);

        if (todaySlots.empty) {
            console.log('⚠️ No active time slots for today');
            console.log('   This is why the modification dialog shows no slots');

            // Check if there are any slots for future dates
            const futureSlots = await db.collection('time_slots')
                .where('date', '>=', today)
                .where('is_active', '==', true)
                .limit(5)
                .get();

            if (!futureSlots.empty) {
                console.log(`\n📅 Found ${futureSlots.size} future slots:`);
                futureSlots.forEach(doc => {
                    const data = doc.data();
                    const slotDate = new Date(data.date.seconds * 1000);
                    console.log(`   - ${slotDate.toLocaleDateString()} at ${new Date(data.start_time.seconds * 1000).toLocaleTimeString()}`);
                });
            }
        } else {
            console.log('\n✅ Today\'s active slots:');
            todaySlots.forEach(doc => {
                const data = doc.data();
                const startTime = new Date(data.start_time.seconds * 1000);
                console.log(`   - ${startTime.toLocaleTimeString()} (${data.meal_type}) - ${data.current_reservations}/${data.max_capacity}`);
            });
        }

    } catch (error) {
        console.error('❌ Error checking time slots:', error);
        throw error;
    }
}

async function main() {
    console.log('🚀 Time Slots Check Script');
    console.log('===========================\n');

    try {
        await checkTimeSlots();

        console.log('\n✅ Script completed!');
        console.log('\n📝 Next steps:');
        console.log('   1. If no time slots exist, create them using the admin panel');
        console.log('   2. If time slots exist but none for today, create today\'s slots');
        console.log('   3. Make sure time slots have is_active = true');
        console.log('   4. Test the modification dialog again');

    } catch (error) {
        console.error('❌ Script failed:', error);
        process.exit(1);
    }

    process.exit(0);
}

main();