// Firebase Setup Data for ISET Com Restaurant - Tunisian University System
// Run this in Firebase Console > Firestore > Start collection

// 1. APP SETTINGS - Tunisian University Restaurant Configuration
const appSettings = {
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
        lunch_start_time: '12:00',
        lunch_end_time: '14:00',
        dinner_start_time: '19:00',
        dinner_end_time: '21:00',
        max_reservations_per_user: 2,
        reservation_deadline_hours: 1,
        notification_enabled: true,
        created_at: new Date()
    }
};

// 2. SAMPLE DAILY MENUS - Authentic Tunisian University Meals
const dailyMenus = [
    {
        collection: 'daily_menu',
        document: 'auto', // Auto-generate ID
        data: {
            date: new Date('2024-01-15'),
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
            created_at: new Date(),
            created_by: 'admin'
        }
    },
    {
        collection: 'daily_menu',
        document: 'auto',
        data: {
            date: new Date('2024-01-15'),
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
            created_at: new Date(),
            created_by: 'admin'
        }
    },
    {
        collection: 'daily_menu',
        document: 'auto',
        data: {
            date: new Date('2024-01-16'),
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
            created_at: new Date(),
            created_by: 'admin'
        }
    },
    {
        collection: 'daily_menu',
        document: 'auto',
        data: {
            date: new Date('2024-01-16'),
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
            created_at: new Date(),
            created_by: 'admin'
        }
    }
];

// 3. TIME SLOTS - Standard University Meal Times
const timeSlots = [
    // Today's slots
    {
        collection: 'time_slots',
        document: 'auto',
        data: {
            date: new Date(),
            start_time: new Date(new Date().setHours(12, 0, 0, 0)),
            end_time: new Date(new Date().setHours(14, 0, 0, 0)),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'lunch'
        }
    },
    {
        collection: 'time_slots',
        document: 'auto',
        data: {
            date: new Date(),
            start_time: new Date(new Date().setHours(19, 0, 0, 0)),
            end_time: new Date(new Date().setHours(21, 0, 0, 0)),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'dinner'
        }
    },
    // Tomorrow's slots
    {
        collection: 'time_slots',
        document: 'auto',
        data: {
            date: new Date(Date.now() + 24 * 60 * 60 * 1000),
            start_time: new Date(Date.now() + 24 * 60 * 60 * 1000 + 12 * 60 * 60 * 1000),
            end_time: new Date(Date.now() + 24 * 60 * 60 * 1000 + 14 * 60 * 60 * 1000),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'lunch'
        }
    },
    {
        collection: 'time_slots',
        document: 'auto',
        data: {
            date: new Date(Date.now() + 24 * 60 * 60 * 1000),
            start_time: new Date(Date.now() + 24 * 60 * 60 * 1000 + 19 * 60 * 60 * 1000),
            end_time: new Date(Date.now() + 24 * 60 * 60 * 1000 + 21 * 60 * 60 * 1000),
            max_capacity: 200,
            current_reservations: 0,
            price: 0.2,
            is_active: true,
            meal_type: 'dinner'
        }
    }
];

// 4. SAMPLE ADMIN USER
const adminUser = {
    collection: 'user',
    document: 'admin_isetcom', // Use specific ID for admin
    data: {
        email: 'admin@isetcom.tn',
        display_name: 'Administrateur ISET Com',
        nom: 'Administrateur',
        role: 'admin',
        language: 'fr',
        notifications_enabled: true,
        created_time: new Date(),
        last_login: new Date(),
        pocket: 100.0, // Admin balance
        tickets: 0,
        classe: 'Administration'
    }
};

// 5. SAMPLE STAFF USER
const staffUser = {
    collection: 'user',
    document: 'staff_restaurant',
    data: {
        email: 'staff@isetcom.tn',
        display_name: 'Personnel Restaurant',
        nom: 'Personnel',
        role: 'staff',
        language: 'fr',
        notifications_enabled: true,
        created_time: new Date(),
        last_login: new Date(),
        pocket: 50.0,
        tickets: 0,
        classe: 'Personnel'
    }
};

// 6. SAMPLE STUDENT USER
const studentUser = {
    collection: 'user',
    document: 'student_sample',
    data: {
        email: 'etudiant@isetcom.tn',
        display_name: 'Ahmed Ben Ali',
        nom: 'Ahmed Ben Ali',
        cin: 12345678,
        role: 'student',
        language: 'fr',
        notifications_enabled: true,
        created_time: new Date(),
        last_login: new Date(),
        pocket: 10.0, // 50 meals worth
        tickets: 0,
        classe: 'L3 INFO',
        phone_number: '+216 XX XXX XXX'
    }
};

console.log('=== FIREBASE SETUP DATA FOR ISET COM RESTAURANT ===');
console.log('Copy and paste each section into Firebase Console > Firestore');
console.log('');
console.log('1. APP SETTINGS:');
console.log(JSON.stringify(appSettings, null, 2));
console.log('');
console.log('2. DAILY MENUS:');
dailyMenus.forEach((menu, index) => {
    console.log(`Menu ${index + 1}:`);
    console.log(JSON.stringify(menu, null, 2));
});
console.log('');
console.log('3. TIME SLOTS:');
timeSlots.forEach((slot, index) => {
    console.log(`Slot ${index + 1}:`);
    console.log(JSON.stringify(slot, null, 2));
});
console.log('');
console.log('4. USERS:');
console.log('Admin:', JSON.stringify(adminUser, null, 2));
console.log('Staff:', JSON.stringify(staffUser, null, 2));
console.log('Student:', JSON.stringify(studentUser, null, 2));

// Instructions for Firebase Console
console.log('');
console.log('=== INSTRUCTIONS ===');
console.log('1. Go to Firebase Console > Firestore Database');
console.log('2. Click "Start collection"');
console.log('3. Use collection name and document ID from above');
console.log('4. Add fields manually or import JSON');
console.log('5. Repeat for each collection');
console.log('');
console.log('=== AUTHENTICATION SETUP ===');
console.log('1. Go to Authentication > Sign-in method');
console.log('2. Enable Email/Password');
console.log('3. Go to Users tab');
console.log('4. Add users with emails from above');
console.log('5. Use password: Admin123! for all test accounts');