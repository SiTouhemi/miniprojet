// Script to update existing daily_menu documents to use day_of_week instead of date
// Run this with Firebase Admin SDK

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

// Initialize Firebase Admin with service account
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'mafirstclienta'
});

const db = admin.firestore();

async function updateMenusToWeekly() {
    try {
        console.log('Starting menu update to weekly system...');

        // Get all existing daily_menu documents
        const snapshot = await db.collection('daily_menu').get();

        if (snapshot.empty) {
            console.log('No menus found to update');
            return;
        }

        console.log(`Found ${snapshot.docs.length} menus to update`);

        const batch = db.batch();
        let updateCount = 0;

        snapshot.docs.forEach((doc) => {
            const data = doc.data();

            // Skip if already has day_of_week
            if (data.day_of_week) {
                console.log(`Menu ${doc.id} already has day_of_week: ${data.day_of_week}`);
                return;
            }

            let dayOfWeek = 1; // Default to Monday

            // If there's a date field, extract day of week from it
            if (data.date && data.date.toDate) {
                const date = data.date.toDate();
                dayOfWeek = date.getDay(); // 0=Sunday, 1=Monday, ..., 6=Saturday

                // Convert JavaScript day (0=Sunday) to our system (1=Monday, 7=Sunday)
                if (dayOfWeek === 0) {
                    dayOfWeek = 7; // Sunday
                }
            }

            // Update the document
            batch.update(doc.ref, {
                day_of_week: dayOfWeek,
                updated_at: admin.firestore.FieldValue.serverTimestamp()
            });

            updateCount++;
            console.log(`Queued update for menu ${doc.id}: day_of_week = ${dayOfWeek}`);
        });

        if (updateCount > 0) {
            await batch.commit();
            console.log(`Successfully updated ${updateCount} menus with day_of_week field`);
        } else {
            console.log('No menus needed updating');
        }

        // Create sample weekly menus if none exist
        await createSampleWeeklyMenus();

    } catch (error) {
        console.error('Error updating menus:', error);
    }
}

async function createSampleWeeklyMenus() {
    try {
        console.log('Creating sample weekly menus...');

        const sampleMenus = [
            // Monday
            {
                day_of_week: 1,
                meal_type: 'lunch',
                main_dish: 'Couscous aux légumes',
                accompaniments: ['Salade verte', 'Pain'],
                description: 'Couscous traditionnel avec légumes de saison',
                price: 3.5,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 1,
                meal_type: 'dinner',
                main_dish: 'Spaghetti Bolognaise',
                accompaniments: ['Fromage râpé', 'Pain à l\'ail'],
                description: 'Spaghetti avec sauce bolognaise maison',
                price: 4.0,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Tuesday
            {
                day_of_week: 2,
                meal_type: 'lunch',
                main_dish: 'Poulet grillé',
                accompaniments: ['Riz', 'Légumes sautés'],
                description: 'Poulet grillé avec accompagnements',
                price: 4.5,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 2,
                meal_type: 'dinner',
                main_dish: 'Pizza Margherita',
                accompaniments: ['Salade mixte'],
                description: 'Pizza fraîche avec mozzarella et basilic',
                price: 3.8,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Wednesday
            {
                day_of_week: 3,
                meal_type: 'lunch',
                main_dish: 'Poisson grillé',
                accompaniments: ['Pommes de terre', 'Ratatouille'],
                description: 'Poisson frais grillé avec légumes méditerranéens',
                price: 5.0,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 3,
                meal_type: 'dinner',
                main_dish: 'Tajine de légumes',
                accompaniments: ['Pain', 'Olives'],
                description: 'Tajine végétarien aux légumes de saison',
                price: 3.2,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Thursday
            {
                day_of_week: 4,
                meal_type: 'lunch',
                main_dish: 'Escalope panée',
                accompaniments: ['Frites', 'Salade verte'],
                description: 'Escalope de poulet panée avec frites maison',
                price: 4.2,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 4,
                meal_type: 'dinner',
                main_dish: 'Lasagnes',
                accompaniments: ['Salade César', 'Pain à l\'ail'],
                description: 'Lasagnes à la viande avec béchamel',
                price: 4.3,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Friday
            {
                day_of_week: 5,
                meal_type: 'lunch',
                main_dish: 'Kefta aux œufs',
                accompaniments: ['Pain', 'Salade de tomates'],
                description: 'Kefta traditionnelle avec œufs et sauce tomate',
                price: 3.8,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 5,
                meal_type: 'dinner',
                main_dish: 'Burger maison',
                accompaniments: ['Frites', 'Cornichons'],
                description: 'Burger fait maison avec steak haché frais',
                price: 4.8,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Saturday
            {
                day_of_week: 6,
                meal_type: 'lunch',
                main_dish: 'Paella aux fruits de mer',
                accompaniments: ['Pain', 'Citron'],
                description: 'Paella traditionnelle aux fruits de mer',
                price: 5.5,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                day_of_week: 6,
                meal_type: 'dinner',
                main_dish: 'Gratin de pâtes',
                accompaniments: ['Salade verte', 'Pain'],
                description: 'Gratin de pâtes au fromage et béchamel',
                price: 3.5,
                available: true,
                created_by: 'system',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            }
        ];

        // Check if sample menus already exist
        const existingMenus = await db.collection('daily_menu')
            .where('created_by', '==', 'system')
            .limit(1)
            .get();

        if (!existingMenus.empty) {
            console.log('Sample menus already exist, skipping creation');
            return;
        }

        // Create sample menus
        const batch = db.batch();
        sampleMenus.forEach((menu) => {
            const docRef = db.collection('daily_menu').doc();
            batch.set(docRef, menu);
        });

        await batch.commit();
        console.log(`Created ${sampleMenus.length} sample weekly menus`);

    } catch (error) {
        console.error('Error creating sample menus:', error);
    }
}

// Run the update
updateMenusToWeekly()
    .then(() => {
        console.log('Menu update completed successfully');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Menu update failed:', error);
        process.exit(1);
    });