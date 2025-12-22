const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addSampleMenus() {
    try {
        console.log('Adding sample menus to Firestore...');

        // Get today's date at midnight
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Sample menus for the next 7 days
        const menus = [
            {
                date: admin.firestore.Timestamp.fromDate(today),
                meal_type: 'lunch',
                main_dish: 'Couscous',
                accompaniments: ['Salade Mechwya', 'Cuisse de Poulet', 'Yaourt'],
                description: 'Couscous traditionnel tunisien avec légumes de saison, cuisse de poulet grillée, salade mechwya et yaourt nature',
                price: 3.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 86400000)),
                meal_type: 'lunch',
                main_dish: 'Spaghetti Bolognaise',
                accompaniments: ['Salade Verte', 'Pain', 'Fruit'],
                description: 'Spaghetti à la sauce bolognaise maison, salade verte fraîche, pain et fruit de saison',
                price: 3.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 2 * 86400000)),
                meal_type: 'lunch',
                main_dish: 'Poulet Rôti',
                accompaniments: ['Riz', 'Légumes Grillés', 'Salade'],
                description: 'Poulet rôti aux herbes avec riz basmati, légumes grillés de saison et salade mixte',
                price: 3.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 3 * 86400000)),
                meal_type: 'lunch',
                main_dish: 'Tajine de Viande',
                accompaniments: ['Pommes de Terre', 'Olives', 'Pain'],
                description: 'Tajine tunisien de viande aux pommes de terre, olives et épices, servi avec du pain frais',
                price: 3.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 4 * 86400000)),
                meal_type: 'lunch',
                main_dish: 'Poisson Grillé',
                accompaniments: ['Riz', 'Salade Tunisienne', 'Citron'],
                description: 'Poisson frais grillé avec riz blanc, salade tunisienne et quartiers de citron',
                price: 4.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 5 * 86400000)),
                meal_type: 'lunch',
                main_dish: 'Makrouna Bel Salsa',
                accompaniments: ['Thon', 'Fromage', 'Salade'],
                description: 'Pâtes tunisiennes à la sauce tomate, thon, fromage râpé et salade verte',
                price: 2.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(new Date(today.getTime() + 6 * 86400000)),
                meal_type: 'lunch',
                main_dish: 'Escalope Panée',
                accompaniments: ['Frites', 'Salade', 'Sauce'],
                description: 'Escalope de poulet panée croustillante avec frites maison, salade et sauce au choix',
                price: 3.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            }
        ];

        // Add each menu to Firestore
        for (const menu of menus) {
            const docRef = await db.collection('daily_menu').add(menu);
            console.log(`✓ Added menu: ${menu.main_dish} (${menu.date.toDate().toLocaleDateString()}) - ID: ${docRef.id}`);
        }

        console.log('\n✓ Successfully added all sample menus!');
        console.log(`Total menus added: ${menus.length}`);

    } catch (error) {
        console.error('Error adding sample menus:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run the script
addSampleMenus();
