// Quick script to add sample data with correct pricing (0.2 TND)
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'mafirstclienta'
});

const db = admin.firestore();

async function quickSeed() {
    try {
        console.log('🚀 Adding sample data with correct pricing (0.2 TND)...');

        // Weekly menus - all priced at 0.2 TND
        const menus = [
            { day_of_week: 1, meal_type: 'lunch', main_dish: 'Couscous aux légumes', accompaniments: ['Salade', 'Pain'], description: 'Couscous traditionnel', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 1, meal_type: 'dinner', main_dish: 'Spaghetti Bolognaise', accompaniments: ['Fromage', 'Pain'], description: 'Spaghetti sauce maison', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 2, meal_type: 'lunch', main_dish: 'Poulet grillé', accompaniments: ['Riz', 'Légumes'], description: 'Poulet aux herbes', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 2, meal_type: 'dinner', main_dish: 'Pizza Margherita', accompaniments: ['Salade'], description: 'Pizza fraîche', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 3, meal_type: 'lunch', main_dish: 'Poisson grillé', accompaniments: ['Pommes de terre', 'Légumes'], description: 'Poisson frais', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 3, meal_type: 'dinner', main_dish: 'Tajine de légumes', accompaniments: ['Pain', 'Olives'], description: 'Tajine végétarien', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 4, meal_type: 'lunch', main_dish: 'Escalope panée', accompaniments: ['Frites', 'Salade'], description: 'Escalope croustillante', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 4, meal_type: 'dinner', main_dish: 'Lasagnes', accompaniments: ['Salade César', 'Pain'], description: 'Lasagnes à la viande', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 5, meal_type: 'lunch', main_dish: 'Kefta aux œufs', accompaniments: ['Pain', 'Salade'], description: 'Kefta traditionnelle', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 5, meal_type: 'dinner', main_dish: 'Burger maison', accompaniments: ['Frites', 'Cornichons'], description: 'Burger artisanal', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 6, meal_type: 'lunch', main_dish: 'Paella aux fruits de mer', accompaniments: ['Pain', 'Citron'], description: 'Paella valencienne', price: 0.2, available: true, created_by: 'system' },
            { day_of_week: 6, meal_type: 'dinner', main_dish: 'Gratin de pâtes', accompaniments: ['Salade', 'Pain'], description: 'Gratin au fromage', price: 0.2, available: true, created_by: 'system' }
        ];

        // Add menus
        const menuBatch = db.batch();
        menus.forEach(menu => {
            const ref = db.collection('daily_menu').doc();
            menuBatch.set(ref, {
                ...menu,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        await menuBatch.commit();
        console.log(`✅ Added ${menus.length} menu items`);

        // Add time slots for next 7 days
        const today = new Date();
        const timeSlots = [];

        for (let day = 0; day < 7; day++) {
            const date = new Date(today);
            date.setDate(today.getDate() + day);

            // Skip Sundays
            if (date.getDay() === 0) continue;

            // Lunch slots
            for (let hour = 12; hour < 14; hour++) {
                for (let min = 0; min < 60; min += 30) {
                    const startTime = new Date(date);
                    startTime.setHours(hour, min, 0, 0);
                    const endTime = new Date(startTime);
                    endTime.setMinutes(endTime.getMinutes() + 30);

                    timeSlots.push({
                        date: admin.firestore.Timestamp.fromDate(new Date(date.getFullYear(), date.getMonth(), date.getDate())),
                        start_time: admin.firestore.Timestamp.fromDate(startTime),
                        end_time: admin.firestore.Timestamp.fromDate(endTime),
                        meal_type: 'lunch',
                        max_capacity: 25,
                        current_reservations: 0,
                        price: 0.2,
                        is_active: true
                    });
                }
            }

            // Dinner slots
            for (let hour = 19; hour < 21; hour++) {
                for (let min = 0; min < 60; min += 30) {
                    const startTime = new Date(date);
                    startTime.setHours(hour, min, 0, 0);
                    const endTime = new Date(startTime);
                    endTime.setMinutes(endTime.getMinutes() + 30);

                    timeSlots.push({
                        date: admin.firestore.Timestamp.fromDate(new Date(date.getFullYear(), date.getMonth(), date.getDate())),
                        start_time: admin.firestore.Timestamp.fromDate(startTime),
                        end_time: admin.firestore.Timestamp.fromDate(endTime),
                        meal_type: 'dinner',
                        max_capacity: 30,
                        current_reservations: 0,
                        price: 0.2,
                        is_active: true
                    });
                }
            }
        }

        // Add time slots in batches
        for (let i = 0; i < timeSlots.length; i += 500) {
            const batch = db.batch();
            const batchSlots = timeSlots.slice(i, i + 500);

            batchSlots.forEach(slot => {
                const ref = db.collection('time_slots').doc();
                batch.set(ref, slot);
            });

            await batch.commit();
        }

        console.log(`✅ Added ${timeSlots.length} time slots`);
        console.log('\n🎉 Sample data added successfully!');
        console.log('📋 Summary:');
        console.log(`   • ${menus.length} weekly menu items (Monday-Saturday)`);
        console.log(`   • ${timeSlots.length} time slots (next 7 days)`);
        console.log('   • All prices set to 0.2 TND');
        console.log('\n✨ Students can now:');
        console.log('   • See daily menus');
        console.log('   • View available time slots');
        console.log('   • Make reservations');

    } catch (error) {
        console.error('❌ Error:', error);
    }

    process.exit(0);
}

quickSeed();