// Simple script to add sample menu data
const admin = require('firebase-admin');

// Initialize with project ID
admin.initializeApp({
    projectId: 'mafirstclienta'
});

const db = admin.firestore();

const sampleMenus = [
    {
        day_of_week: 1,
        meal_type: 'lunch',
        main_dish: 'Couscous aux légumes',
        accompaniments: ['Salade verte', 'Pain'],
        description: 'Couscous traditionnel avec légumes de saison',
        price: 3.5,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 1,
        meal_type: 'dinner',
        main_dish: 'Spaghetti Bolognaise',
        accompaniments: ['Fromage râpé', 'Pain à l\'ail'],
        description: 'Spaghetti avec sauce bolognaise maison',
        price: 4.0,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 6,
        meal_type: 'lunch',
        main_dish: 'Paella aux fruits de mer',
        accompaniments: ['Pain', 'Citron'],
        description: 'Paella traditionnelle aux fruits de mer',
        price: 5.5,
        available: true,
        created_by: 'system'
    }
];

async function addSampleData() {
    try {
        console.log('Adding sample menu data...');

        for (const menu of sampleMenus) {
            await db.collection('daily_menu').add({
                ...menu,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`Added menu: ${menu.main_dish} for day ${menu.day_of_week} (${menu.meal_type})`);
        }

        console.log('Sample data added successfully!');
        process.exit(0);
    } catch (error) {
        console.error('Error adding sample data:', error);
        process.exit(1);
    }
}

addSampleData();