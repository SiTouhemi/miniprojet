const admin = require('firebase-admin');

// Initialize Firebase Admin SDK for emulator
admin.initializeApp({
    projectId: 'mafirstclienta',
});

// Connect to Firestore emulator
const db = admin.firestore();
if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log('Using Firestore emulator');
} else {
    console.log('Setting Firestore emulator host');
    process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
}

async function addTestData() {
    try {
        console.log('Adding test data to Firestore emulator...');

        // Add test user
        const testUser = {
            uid: 'test-student-123',
            email: 'student@isetcom.tn',
            display_name: 'Test Student',
            nom: 'Test Student',
            role: 'student',
            classe: 'L3 INFO',
            pocket: 25.50,
            tickets: 3,
            cin: '12345678',
            phone_number: '+21612345678',
            created_time: admin.firestore.FieldValue.serverTimestamp(),
            last_login: admin.firestore.FieldValue.serverTimestamp(),
            language: 'fr',
            notifications_enabled: true
        };

        await db.collection('user').doc('test-student-123').set(testUser);
        console.log('✅ Test user added');

        // Add test menu items
        const menuItems = [
            {
                nom: 'Couscous Tunisien',
                description: 'Couscous traditionnel avec légumes et viande',
                prix: 8.50,
                categorie: 'Plat Principal',
                disponible: true,
                image_url: '',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                nom: 'Salade Mechouia',
                description: 'Salade grillée tunisienne traditionnelle',
                prix: 4.00,
                categorie: 'Entrée',
                disponible: true,
                image_url: '',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                nom: 'Makroudh',
                description: 'Pâtisserie tunisienne aux dattes',
                prix: 2.50,
                categorie: 'Dessert',
                disponible: true,
                image_url: '',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            }
        ];

        for (let i = 0; i < menuItems.length; i++) {
            await db.collection('plat').add(menuItems[i]);
        }
        console.log('✅ Menu items added');

        // Add test time slots
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const timeSlots = [
            {
                date: admin.firestore.Timestamp.fromDate(today),
                heure_debut: '12:00',
                heure_fin: '13:00',
                capacite_max: 50,
                reservations_count: 15,
                disponible: true,
                type_repas: 'dejeuner',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(today),
                heure_debut: '13:00',
                heure_fin: '14:00',
                capacite_max: 50,
                reservations_count: 32,
                disponible: true,
                type_repas: 'dejeuner',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            },
            {
                date: admin.firestore.Timestamp.fromDate(tomorrow),
                heure_debut: '12:00',
                heure_fin: '13:00',
                capacite_max: 50,
                reservations_count: 5,
                disponible: true,
                type_repas: 'dejeuner',
                created_time: admin.firestore.FieldValue.serverTimestamp()
            }
        ];

        for (let i = 0; i < timeSlots.length; i++) {
            await db.collection('time_slot').add(timeSlots[i]);
        }
        console.log('✅ Time slots added');

        // Add app settings
        const appSettings = {
            app_name: 'ISET Restaurant',
            version: '1.0.0',
            maintenance_mode: false,
            max_reservations_per_user: 3,
            reservation_deadline_hours: 2,
            welcome_message: 'Bienvenue au restaurant universitaire ISET Com',
            support_email: 'support@isetcom.tn',
            updated_at: admin.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('app_settings').doc('main').set(appSettings);
        console.log('✅ App settings added');

        console.log('🎉 Test data added successfully!');
        console.log('You can now test the app with:');
        console.log('Email: student@isetcom.tn');
        console.log('Password: (any password - emulator accepts any)');

    } catch (error) {
        console.error('Error adding test data:', error);
    }
}

// Run the script
addTestData().then(() => {
    console.log('Script completed');
    process.exit(0);
}).catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
});