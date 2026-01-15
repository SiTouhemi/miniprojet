const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with service account
const serviceAccountPath = path.join(__dirname, '..', 'firebase', 'service-account-key.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixMenuData() {
    try {
        console.log('🔧 Fixing menu data in Firestore...');

        // First, let's clear existing menus to avoid conflicts
        console.log('📝 Clearing existing menus...');
        const existingMenus = await db.collection('daily_menu').get();
        const batch = db.batch();

        existingMenus.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        if (existingMenus.docs.length > 0) {
            await batch.commit();
            console.log(`✓ Cleared ${existingMenus.docs.length} existing menus`);
        }

        // Sample menus with proper day_of_week format (1=Monday, 2=Tuesday, etc.)
        const sampleMenus = [
            // Monday Lunch
            {
                day_of_week: 1,
                meal_type: 'lunch',
                main_dish: 'Couscous Traditionnel',
                salad: 'Salade Mechwya',
                dessert: 'Yaourt Nature',
                accompaniments: ['Pain Arabe', 'Cuisse de Poulet'],
                description: 'Couscous traditionnel tunisien avec légumes de saison et cuisse de poulet grillée',
                price: 8.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Monday Dinner
            {
                day_of_week: 1,
                meal_type: 'dinner',
                main_dish: 'Spaghetti Bolognaise',
                salad: 'Salade Verte',
                dessert: 'Fruit de Saison',
                accompaniments: ['Pain Français', 'Fromage Râpé'],
                description: 'Spaghetti à la sauce bolognaise maison avec salade fraîche',
                price: 7.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Tuesday Lunch
            {
                day_of_week: 2,
                meal_type: 'lunch',
                main_dish: 'Poulet Rôti aux Herbes',
                salad: 'Salade Tunisienne',
                dessert: 'Crème Caramel',
                accompaniments: ['Riz Basmati', 'Légumes Grillés'],
                description: 'Poulet rôti aux herbes avec riz parfumé et légumes de saison',
                price: 9.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Tuesday Dinner
            {
                day_of_week: 2,
                meal_type: 'dinner',
                main_dish: 'Tajine de Viande',
                salad: 'Salade Mixte',
                dessert: 'Makroudh',
                accompaniments: ['Pommes de Terre', 'Olives Vertes'],
                description: 'Tajine tunisien de viande aux pommes de terre et épices',
                price: 8.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Wednesday Lunch
            {
                day_of_week: 3,
                meal_type: 'lunch',
                main_dish: 'Poisson Grillé',
                salad: 'Salade de Concombre',
                dessert: 'Baklawa',
                accompaniments: ['Riz Blanc', 'Quartiers de Citron'],
                description: 'Poisson frais grillé avec riz et salade rafraîchissante',
                price: 10.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Wednesday Dinner
            {
                day_of_week: 3,
                meal_type: 'dinner',
                main_dish: 'Makrouna Bel Salsa',
                salad: 'Salade Verte',
                dessert: 'Yaourt aux Fruits',
                accompaniments: ['Thon', 'Fromage'],
                description: 'Pâtes tunisiennes à la sauce tomate avec thon et fromage',
                price: 6.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Thursday Lunch
            {
                day_of_week: 4,
                meal_type: 'lunch',
                main_dish: 'Escalope Panée',
                salad: 'Salade de Tomates',
                dessert: 'Mousse au Chocolat',
                accompaniments: ['Frites Maison', 'Sauce Tartare'],
                description: 'Escalope de poulet panée croustillante avec frites et sauce',
                price: 8.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Thursday Dinner
            {
                day_of_week: 4,
                meal_type: 'dinner',
                main_dish: 'Kefta aux Œufs',
                salad: 'Salade Mechwya',
                dessert: 'Halwa Chamia',
                accompaniments: ['Pain Arabe', 'Harissa'],
                description: 'Kefta tunisienne aux œufs avec pain frais et harissa',
                price: 7.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Friday Lunch
            {
                day_of_week: 5,
                meal_type: 'lunch',
                main_dish: 'Couscous au Poisson',
                salad: 'Salade de Betteraves',
                dessert: 'Zlabia',
                accompaniments: ['Légumes Variés', 'Bouillon'],
                description: 'Couscous au poisson frais avec légumes et bouillon parfumé',
                price: 11.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Friday Dinner
            {
                day_of_week: 5,
                meal_type: 'dinner',
                main_dish: 'Pizza Margherita',
                salad: 'Salade César',
                dessert: 'Tiramisu',
                accompaniments: ['Olives Noires', 'Huile d\'Olive'],
                description: 'Pizza margherita fraîche avec salade césar et tiramisu',
                price: 9.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Saturday Lunch
            {
                day_of_week: 6,
                meal_type: 'lunch',
                main_dish: 'Agneau aux Légumes',
                salad: 'Salade Orientale',
                dessert: 'Basboussa',
                accompaniments: ['Riz Pilaf', 'Menthe Fraîche'],
                description: 'Agneau tendre aux légumes avec riz pilaf et menthe',
                price: 12.0,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            },
            // Saturday Dinner
            {
                day_of_week: 6,
                meal_type: 'dinner',
                main_dish: 'Sandwich Tunisien',
                salad: 'Salade de Radis',
                dessert: 'Fruit Frais',
                accompaniments: ['Thon', 'Œuf Dur', 'Harissa'],
                description: 'Sandwich tunisien traditionnel avec thon, œuf et harissa',
                price: 5.5,
                available: true,
                image_url: '',
                created_by: 'admin',
                created_at: admin.firestore.FieldValue.serverTimestamp()
            }
        ];

        // Add each menu to Firestore
        console.log('📝 Adding sample menus...');
        for (const menu of sampleMenus) {
            const docRef = await db.collection('daily_menu').add(menu);
            const dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][menu.day_of_week];
            console.log(`✓ Added ${dayName} ${menu.meal_type}: ${menu.main_dish} - ID: ${docRef.id}`);
        }

        console.log('\n🎉 Successfully fixed menu data!');
        console.log(`📊 Total menus added: ${sampleMenus.length}`);
        console.log('📅 Coverage: Monday-Saturday, Lunch & Dinner');
        console.log('\n💡 You can now see the menu details in the daily menu management page!');

    } catch (error) {
        console.error('❌ Error fixing menu data:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run the script
fixMenuData();