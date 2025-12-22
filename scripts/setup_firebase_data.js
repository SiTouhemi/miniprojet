#!/usr/bin/env node

/**
 * Firebase Data Setup Script for ISET Com Restaurant
 * Automatically populates Firestore with sample data
 * 
 * Usage: node scripts/setup_firebase_data.js
 * 
 * Prerequisites:
 * 1. Firebase CLI installed and logged in
 * 2. Firebase project initialized
 * 3. Service account key (optional for admin SDK)
 */

const admin = require('firebase-admin');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

// Load service account key
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ serviceAccountKey.json not found in scripts/ folder');
    console.log('Please download it from:');
    console.log('https://console.firebase.google.com/project/mafirstclienta/settings/serviceaccounts/adminsdk');
    process.exit(1);
}

const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log(`✅ Firebase Admin SDK initialized successfully for project: ${serviceAccount.project_id}`);
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    console.log('Make sure the serviceAccountKey.json file is valid');
    process.exit(1);
}

const db = admin.firestore();

// Sample data from firebase_setup_data.js
const setupData = {
    // 1. APP SETTINGS
    appSettings: {
        collection: 'app_settings',
        document: 'default',
        data: {
            app_name: 'ISET Com Restaurant',
            welcome_message: 'Bienvenue au restaurant universitaire ISET Com',
            contact_email: 'restaurant@isetcom.tn',
            contact_phone: '+216 71 XXX XXX',
            restaurant_address: 'Institut Supérieur des Études Technologiques de Communications, Tunis',
            default_meal_price: 0.2,
            currency: 'TND',
            subsidy_rate: 0.95,
            lunch_start_time: '11:40',
            lunch_end_time: '14:00',
            dinner_start_time: '17:40',
            dinner_end_time: '19:00',
            max_reservations_per_user: 2,
            reservation_deadline_hours: 1,
            notification_enabled: true,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        }
    },

    // 2. DAILY MENUS
    dailyMenus: [
        {
            date: new Date('2024-12-22'),
            meal_type: 'lunch',
            main_dish: 'Couscous Tunisien aux Légumes',
            accompaniments: [
                'Roti (Pain tunisien)',
                'Salade mixte (tomates, concombres)',
                'Yaourt nature',
                'Harissa'
            ],
            description: 'Menu complet: Couscous traditionnel aux légumes de saison avec roti frais, salade mixte et yaourt',
            price: 0.2,
            available: true,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            created_by: 'admin'
        },
        {
            date: new Date('2024-12-22'),
            meal_type: 'dinner',
            main_dish: 'Makrouna (Pâtes Tunisiennes)',
            accompaniments: [
                'Salade de tomates',
                'Pain blanc',
                'Fromage blanc',
                'Olives vertes'
            ],
            description: 'Pâtes tunisiennes à la sauce tomate avec salade fraîche, pain et fromage blanc',
            price: 0.2,
            available: true,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            created_by: 'admin'
        },
        {
            date: new Date('2024-12-23'),
            meal_type: 'lunch',
            main_dish: 'Riz aux Légumes',
            accompaniments: [
                'Escalope de poulet',
                'Salade verte',
                'Pain',
                'Compote de fruits'
            ],
            description: 'Riz basmati aux légumes avec escalope de poulet grillée, salade verte et compote',
            price: 0.2,
            available: true,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            created_by: 'admin'
        },
        {
            date: new Date('2024-12-23'),
            meal_type: 'dinner',
            main_dish: 'Lablabi (Soupe de Pois Chiches)',
            accompaniments: [
                'Pain tabouna',
                'Œuf dur',
                'Thon',
                'Harissa',
                'Citron'
            ],
            description: 'Lablabi traditionnel tunisien avec pain tabouna, œuf dur et thon',
            price: 0.2,
            available: true,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            created_by: 'admin'
        }
    ],

    // 3. TIME SLOTS
    timeSlots: [
        // Today's slots
        {
            date: admin.firestore.Timestamp.fromDate(new Date()),
            start_time: admin.firestore.Timestamp.fromDate(new Date(new Date().setHours(12, 0, 0, 0))),
            end_time: admin.firestore.Timestamp.fromDate(new Date(new Date().setHours(14, 0, 0, 0))),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'lunch'
        },
        {
            date: admin.firestore.Timestamp.fromDate(new Date()),
            start_time: admin.firestore.Timestamp.fromDate(new Date(new Date().setHours(19, 0, 0, 0))),
            end_time: admin.firestore.Timestamp.fromDate(new Date(new Date().setHours(21, 0, 0, 0))),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'dinner'
        },
        // Tomorrow's slots
        {
            date: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000)),
            start_time: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000 + 12 * 60 * 60 * 1000)),
            end_time: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000 + 14 * 60 * 60 * 1000)),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'lunch'
        },
        {
            date: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000)),
            start_time: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000 + 19 * 60 * 60 * 1000)),
            end_time: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000 + 21 * 60 * 60 * 1000)),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'dinner'
        }
    ],

    // 4. SAMPLE USERS
    users: [
        {
            id: 'admin_isetcom',
            data: {
                email: 'admin@isetcom.tn',
                display_name: 'Administrateur ISET Com',
                nom: 'Administrateur',
                role: 'admin',
                language: 'fr',
                notifications_enabled: true,
                created_time: admin.firestore.FieldValue.serverTimestamp(),
                last_login: admin.firestore.FieldValue.serverTimestamp(),
                pocket: 100.0,
                tickets: 0,
                classe: 'Administration'
            }
        },
        {
            id: 'staff_restaurant',
            data: {
                email: 'staff@isetcom.tn',
                display_name: 'Personnel Restaurant',
                nom: 'Personnel',
                role: 'staff',
                language: 'fr',
                notifications_enabled: true,
                created_time: admin.firestore.FieldValue.serverTimestamp(),
                last_login: admin.firestore.FieldValue.serverTimestamp(),
                pocket: 50.0,
                tickets: 0,
                classe: 'Personnel'
            }
        },
        {
            id: 'student_sample',
            data: {
                email: 'etudiant@isetcom.tn',
                display_name: 'Ahmed Ben Ali',
                nom: 'Ahmed Ben Ali',
                cin: 12345678,
                role: 'student',
                language: 'fr',
                notifications_enabled: true,
                created_time: admin.firestore.FieldValue.serverTimestamp(),
                last_login: admin.firestore.FieldValue.serverTimestamp(),
                pocket: 10.0,
                tickets: 0,
                classe: 'L3 INFO',
                phone_number: '+216 XX XXX XXX'
            }
        }
    ]
};

// Helper function to ask user confirmation
function askQuestion(question) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer.toLowerCase().trim());
        });
    });
}

// Main setup function
async function setupFirebaseData() {
    console.log('\n🔥 Firebase Data Setup for ISET Com Restaurant');
    console.log('================================================\n');

    try {
        // Check if data already exists
        const appSettingsDoc = await db.collection('app_settings').doc('default').get();

        if (appSettingsDoc.exists) {
            console.log('⚠️  Warning: App settings already exist in Firestore');
            const answer = await askQuestion('Do you want to overwrite existing data? (y/N): ');

            if (answer !== 'y' && answer !== 'yes') {
                console.log('❌ Setup cancelled by user');
                process.exit(0);
            }
        }

        console.log('📝 Starting data insertion...\n');

        // 1. Setup App Settings
        console.log('1️⃣  Setting up app settings...');
        await db.collection(setupData.appSettings.collection)
            .doc(setupData.appSettings.document)
            .set(setupData.appSettings.data);
        console.log('   ✅ App settings created');

        // 2. Setup Daily Menus
        console.log('2️⃣  Setting up daily menus...');
        for (let i = 0; i < setupData.dailyMenus.length; i++) {
            await db.collection('daily_menu').add(setupData.dailyMenus[i]);
        }
        console.log(`   ✅ ${setupData.dailyMenus.length} daily menus created`);

        // 3. Setup Time Slots
        console.log('3️⃣  Setting up time slots...');
        for (let i = 0; i < setupData.timeSlots.length; i++) {
            await db.collection('time_slots').add(setupData.timeSlots[i]);
        }
        console.log(`   ✅ ${setupData.timeSlots.length} time slots created`);

        // 4. Setup Users (Firestore documents)
        console.log('4️⃣  Setting up sample users in Firestore...');
        for (let i = 0; i < setupData.users.length; i++) {
            const user = setupData.users[i];
            await db.collection('user').doc(user.id).set(user.data);
        }
        console.log(`   ✅ ${setupData.users.length} Firestore user documents created`);

        // 5. Setup Authentication Users (with passwords)
        console.log('5️⃣  Setting up Firebase Authentication users...');
        const defaultPassword = 'Admin123!'; // Default password for all test accounts

        for (let i = 0; i < setupData.users.length; i++) {
            const user = setupData.users[i];
            try {
                // Check if user already exists
                let authUser;
                try {
                    authUser = await admin.auth().getUserByEmail(user.data.email);
                    console.log(`   ⚠️  User ${user.data.email} already exists in Authentication`);
                } catch (error) {
                    // User doesn't exist, create new one
                    authUser = await admin.auth().createUser({
                        uid: user.id,
                        email: user.data.email,
                        password: defaultPassword,
                        displayName: user.data.display_name,
                        emailVerified: true
                    });
                    console.log(`   ✅ Created auth user: ${user.data.email}`);
                }

                // Set custom claims for role-based access
                await admin.auth().setCustomUserClaims(authUser.uid, {
                    role: user.data.role,
                    classe: user.data.classe || null
                });
                console.log(`   ✅ Set role "${user.data.role}" for ${user.data.email}`);

            } catch (error) {
                console.log(`   ❌ Failed to create auth user ${user.data.email}: ${error.message}`);
            }
        }
        console.log(`   ✅ Firebase Authentication setup completed`);

        console.log('\n🎉 Firebase setup completed successfully!');
        console.log('\n📋 Summary:');
        console.log(`   • App settings: 1 document`);
        console.log(`   • Daily menus: ${setupData.dailyMenus.length} documents`);
        console.log(`   • Time slots: ${setupData.timeSlots.length} documents`);
        console.log(`   • Firestore users: ${setupData.users.length} documents`);
        console.log(`   • Authentication users: ${setupData.users.length} accounts`);

        console.log('\n🔐 Test Accounts Created (with passwords):');
        console.log('   • Admin: admin@isetcom.tn (password: Admin123!)');
        console.log('   • Staff: staff@isetcom.tn (password: Admin123!)');
        console.log('   • Student: etudiant@isetcom.tn (password: Admin123!)');

        console.log('\n🚀 Next Steps:');
        console.log('   1. Go to Firebase Console > Authentication to verify users');
        console.log('   2. Test login with any of the accounts above');
        console.log('   3. Users have role-based custom claims set up');
        console.log('   4. Test your app with the sample data!');
        console.log('\n💡 You can change passwords later in Firebase Console > Authentication > Users');

    } catch (error) {
        console.error('\n❌ Error during setup:', error);
        console.log('\nTroubleshooting:');
        console.log('1. Make sure you are logged in: firebase login');
        console.log('2. Check your Firebase project ID: firebase projects:list');
        console.log('3. Ensure Firestore is enabled in your project');
        process.exit(1);
    }
}

// Run the setup
if (require.main === module) {
    setupFirebaseData().then(() => {
        process.exit(0);
    });
}

module.exports = { setupFirebaseData };