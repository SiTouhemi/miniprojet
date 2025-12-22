#!/usr/bin/env node

/**
 * Simple Firebase Data Setup Script for ISET Com Restaurant
 * Uses Firebase CLI to populate Firestore with sample data
 * 
 * Usage: node scripts/setup_firebase_data_simple.js
 * 
 * Prerequisites:
 * 1. Firebase CLI installed and logged in
 * 2. Firebase project initialized
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('\n🔥 Firebase Data Setup for ISET Com Restaurant');
console.log('================================================\n');

// Sample data
const sampleData = {
    appSettings: {
        app_name: 'ISET Com Restaurant',
        welcome_message: 'Bienvenue au restaurant universitaire ISET Com',
        contact_email: 'restaurant@isetcom.tn',
        contact_phone: '+216 71 XXX XXX',
        restaurant_address: 'Institut Supérieur des Études Technologiques de Communications, Tunis',
        default_meal_price: 0.2,
        currency: 'TND',
        subsidy_rate: 0.95,
        lunch_start_time: '12:00',
        lunch_end_time: '14:00',
        dinner_start_time: '19:00',
        dinner_end_time: '21:00',
        max_reservations_per_user: 2,
        reservation_deadline_hours: 1,
        notification_enabled: true
    },

    dailyMenus: [
        {
            date: '2024-12-22',
            meal_type: 'lunch',
            main_dish: 'Couscous Tunisien aux Légumes',
            accompaniments: ['Roti (Pain tunisien)', 'Salade mixte (tomates, concombres)', 'Yaourt nature', 'Harissa'],
            description: 'Menu complet: Couscous traditionnel aux légumes de saison avec roti frais, salade mixte et yaourt',
            price: 0.2,
            available: true,
            created_by: 'admin'
        },
        {
            date: '2024-12-22',
            meal_type: 'dinner',
            main_dish: 'Makrouna (Pâtes Tunisiennes)',
            accompaniments: ['Salade de tomates', 'Pain blanc', 'Fromage blanc', 'Olives vertes'],
            description: 'Pâtes tunisiennes à la sauce tomate avec salade fraîche, pain et fromage blanc',
            price: 0.2,
            available: true,
            created_by: 'admin'
        },
        {
            date: '2024-12-23',
            meal_type: 'lunch',
            main_dish: 'Riz aux Légumes',
            accompaniments: ['Escalope de poulet', 'Salade verte', 'Pain', 'Compote de fruits'],
            description: 'Riz basmati aux légumes avec escalope de poulet grillée, salade verte et compote',
            price: 0.2,
            available: true,
            created_by: 'admin'
        },
        {
            date: '2024-12-23',
            meal_type: 'dinner',
            main_dish: 'Lablabi (Soupe de Pois Chiches)',
            accompaniments: ['Pain tabouna', 'Œuf dur', 'Thon', 'Harissa', 'Citron'],
            description: 'Lablabi traditionnel tunisien avec pain tabouna, œuf dur et thon',
            price: 0.2,
            available: true,
            created_by: 'admin'
        }
    ],

    users: [
        {
            id: 'admin_isetcom',
            email: 'admin@isetcom.tn',
            display_name: 'Administrateur ISET Com',
            nom: 'Administrateur',
            role: 'admin',
            language: 'fr',
            notifications_enabled: true,
            pocket: 100.0,
            tickets: 0,
            classe: 'Administration'
        },
        {
            id: 'staff_restaurant',
            email: 'staff@isetcom.tn',
            display_name: 'Personnel Restaurant',
            nom: 'Personnel',
            role: 'staff',
            language: 'fr',
            notifications_enabled: true,
            pocket: 50.0,
            tickets: 0,
            classe: 'Personnel'
        },
        {
            id: 'student_sample',
            email: 'etudiant@isetcom.tn',
            display_name: 'Ahmed Ben Ali',
            nom: 'Ahmed Ben Ali',
            cin: 12345678,
            role: 'student',
            language: 'fr',
            notifications_enabled: true,
            pocket: 10.0,
            tickets: 0,
            classe: 'L3 INFO',
            phone_number: '+216 XX XXX XXX'
        }
    ]
};

function runFirebaseCommand(command) {
    try {
        console.log(`Running: ${command}`);
        const result = execSync(command, {
            encoding: 'utf8',
            cwd: path.join(__dirname, '..'),
            stdio: 'pipe'
        });
        return result;
    } catch (error) {
        console.error(`❌ Command failed: ${command}`);
        console.error(error.message);
        throw error;
    }
}

function createTempDataFile(data, filename) {
    const tempDir = path.join(__dirname, 'temp');
    if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir);
    }

    const filePath = path.join(tempDir, filename);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    return filePath;
}

async function setupFirebaseData() {
    try {
        console.log('📝 Starting data insertion...\n');

        // Check Firebase login
        console.log('🔐 Checking Firebase authentication...');
        try {
            runFirebaseCommand('firebase projects:list');
            console.log('   ✅ Firebase authentication verified');
        } catch (error) {
            console.log('   ❌ Not logged in to Firebase');
            console.log('   Please run: firebase login');
            process.exit(1);
        }

        // 1. Setup App Settings
        console.log('\n1️⃣  Setting up app settings...');
        const appSettingsFile = createTempDataFile(sampleData.appSettings, 'app_settings.json');
        runFirebaseCommand(`firebase firestore:delete app_settings/default --yes || echo "Document may not exist"`);
        runFirebaseCommand(`firebase firestore:set app_settings/default "${appSettingsFile}"`);
        console.log('   ✅ App settings created');

        // 2. Setup Users
        console.log('\n2️⃣  Setting up sample users...');
        for (const user of sampleData.users) {
            const userFile = createTempDataFile(user, `user_${user.id}.json`);
            runFirebaseCommand(`firebase firestore:delete user/${user.id} --yes || echo "Document may not exist"`);
            runFirebaseCommand(`firebase firestore:set user/${user.id} "${userFile}"`);
        }
        console.log(`   ✅ ${sampleData.users.length} users created`);

        // 3. Setup Daily Menus
        console.log('\n3️⃣  Setting up daily menus...');
        for (let i = 0; i < sampleData.dailyMenus.length; i++) {
            const menu = sampleData.dailyMenus[i];
            const menuFile = createTempDataFile(menu, `menu_${i}.json`);
            runFirebaseCommand(`firebase firestore:add daily_menu "${menuFile}"`);
        }
        console.log(`   ✅ ${sampleData.dailyMenus.length} daily menus created`);

        // 4. Create sample time slots for today and tomorrow
        console.log('\n4️⃣  Setting up time slots...');
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const timeSlots = [
            // Today
            {
                date: today.toISOString().split('T')[0],
                start_time: '12:00',
                end_time: '14:00',
                max_capacity: 200,
                current_reservations: 0,
                price: 0.2,
                is_active: true,
                meal_type: 'lunch'
            },
            {
                date: today.toISOString().split('T')[0],
                start_time: '19:00',
                end_time: '21:00',
                max_capacity: 200,
                current_reservations: 0,
                price: 0.2,
                is_active: true,
                meal_type: 'dinner'
            },
            // Tomorrow
            {
                date: tomorrow.toISOString().split('T')[0],
                start_time: '12:00',
                end_time: '14:00',
                max_capacity: 200,
                current_reservations: 0,
                price: 0.2,
                is_active: true,
                meal_type: 'lunch'
            },
            {
                date: tomorrow.toISOString().split('T')[0],
                start_time: '19:00',
                end_time: '21:00',
                max_capacity: 200,
                current_reservations: 0,
                price: 0.2,
                is_active: true,
                meal_type: 'dinner'
            }
        ];

        for (let i = 0; i < timeSlots.length; i++) {
            const slot = timeSlots[i];
            const slotFile = createTempDataFile(slot, `slot_${i}.json`);
            runFirebaseCommand(`firebase firestore:add time_slots "${slotFile}"`);
        }
        console.log(`   ✅ ${timeSlots.length} time slots created`);

        // Cleanup temp files
        const tempDir = path.join(__dirname, 'temp');
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true });
        }

        console.log('\n🎉 Firebase setup completed successfully!');
        console.log('\n📋 Summary:');
        console.log(`   • App settings: 1 document`);
        console.log(`   • Daily menus: ${sampleData.dailyMenus.length} documents`);
        console.log(`   • Time slots: ${timeSlots.length} documents`);
        console.log(`   • Users: ${sampleData.users.length} documents`);

        console.log('\n🔐 Test Accounts Created:');
        console.log('   • Admin: admin@isetcom.tn');
        console.log('   • Staff: staff@isetcom.tn');
        console.log('   • Student: etudiant@isetcom.tn');

        console.log('\n🚀 Next Steps:');
        console.log('   1. Go to Firebase Console > Authentication');
        console.log('   2. Enable Email/Password sign-in method');
        console.log('   3. Add the test users with their emails');
        console.log('   4. Set passwords for the test accounts');
        console.log('   5. Test your app with the sample data!');

    } catch (error) {
        console.error('\n❌ Error during setup:', error.message);
        console.log('\nTroubleshooting:');
        console.log('1. Make sure you are logged in: firebase login');
        console.log('2. Check your Firebase project: firebase use --add');
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