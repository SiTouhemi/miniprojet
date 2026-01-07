/**
 * Script to fix existing reservation documents in Firestore
 * 
 * This script converts prix and total fields from double (TND) to int (millimes)
 * to match the updated ReservationRecord schema.
 * 
 * Usage:
 *   node scripts/fix_reservation_documents.js
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

async function fixReservationDocuments() {
    console.log('🔧 Fixing Reservation Documents');
    console.log('================================\n');

    try {
        // Get all reservation documents
        const reservationsSnapshot = await db.collection('reservation').get();

        console.log(`📊 Found ${reservationsSnapshot.size} reservation documents`);

        if (reservationsSnapshot.empty) {
            console.log('ℹ️ No reservation documents to fix');
            return;
        }

        const batch = db.batch();
        let fixedCount = 0;
        let alreadyCorrectCount = 0;

        for (const doc of reservationsSnapshot.docs) {
            const data = doc.data();
            const updates = {};
            let needsUpdate = false;

            // Check prix field
            if (typeof data.prix === 'number') {
                if (data.prix < 100 && data.prix > 0) {
                    // Likely in TND, convert to millimes
                    updates.prix = Math.round(data.prix * 1000);
                    needsUpdate = true;
                    console.log(`   📝 ${doc.id}: prix ${data.prix} TND → ${updates.prix} millimes`);
                } else if (Number.isInteger(data.prix) && data.prix >= 100) {
                    // Already in millimes, no change needed
                    alreadyCorrectCount++;
                }
            }

            // Check total field
            if (typeof data.total === 'number') {
                if (data.total < 100 && data.total > 0) {
                    // Likely in TND, convert to millimes
                    updates.total = Math.round(data.total * 1000);
                    needsUpdate = true;
                    console.log(`   📝 ${doc.id}: total ${data.total} TND → ${updates.total} millimes`);
                } else if (Number.isInteger(data.total) && data.total >= 100) {
                    // Already in millimes, no change needed
                    alreadyCorrectCount++;
                }
            }

            if (needsUpdate) {
                batch.update(doc.ref, updates);
                fixedCount++;
            }
        }

        if (fixedCount > 0) {
            console.log(`\n🔄 Applying ${fixedCount} updates...`);
            await batch.commit();
            console.log('✅ Updates applied successfully');
        } else {
            console.log('\n✅ All documents are already in correct format');
        }

        console.log(`\n📈 Summary:`);
        console.log(`   - Documents fixed: ${fixedCount}`);
        console.log(`   - Already correct: ${alreadyCorrectCount}`);
        console.log(`   - Total processed: ${reservationsSnapshot.size}`);

    } catch (error) {
        console.error('❌ Error fixing reservation documents:', error);
        throw error;
    }
}

async function verifyReservationDocuments() {
    console.log('\n🔍 Verifying Reservation Documents');
    console.log('==================================\n');

    try {
        const reservationsSnapshot = await db.collection('reservation').get();

        for (const doc of reservationsSnapshot.docs) {
            const data = doc.data();

            console.log(`📄 ${doc.id}:`);
            console.log(`   - prix: ${data.prix} (${typeof data.prix})`);
            console.log(`   - total: ${data.total} (${typeof data.total})`);
            console.log(`   - status: ${data.status}`);
            console.log(`   - user_id: ${data.user_id}`);
            console.log(`   - meal_type: ${data.meal_type}`);

            // Convert back to TND for display verification
            if (typeof data.prix === 'number' && data.prix >= 100) {
                console.log(`   - prix display: ${(data.prix / 1000).toFixed(2)} TND`);
            }
            if (typeof data.total === 'number' && data.total >= 100) {
                console.log(`   - total display: ${(data.total / 1000).toFixed(2)} TND`);
            }

            console.log('');
        }

    } catch (error) {
        console.error('❌ Error verifying reservation documents:', error);
    }
}

async function main() {
    console.log('🚀 Reservation Document Fix Script');
    console.log('===================================\n');

    try {
        await fixReservationDocuments();
        await verifyReservationDocuments();

        console.log('\n✅ Script completed successfully!');
        console.log('\n📝 Next steps:');
        console.log('   1. Test the history page in the app');
        console.log('   2. Verify reservations display correctly');
        console.log('   3. Check that prices show in TND format');

    } catch (error) {
        console.error('❌ Script failed:', error);
        process.exit(1);
    }

    process.exit(0);
}

main();