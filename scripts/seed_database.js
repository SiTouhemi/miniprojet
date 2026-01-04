// Comprehensive database seeding script for ISETCOM Restaurant
// This script will populate the database with all necessary sample data

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
    projectId: 'mafirstclienta'
});

const db = admin.firestore();

// Sample weekly menus (Monday=1 to Saturday=6)
const weeklyMenus = [
    // Monday (1)
    {
        day_of_week: 1,
        meal_type: 'lunch',
        main_dish: 'Couscous aux légumes',
        accompaniments: ['Salade verte', 'Pain', 'Olives'],
        description: 'Couscous traditionnel tunisien avec légumes de saison',
        price: 3.5,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 1,
        meal_type: 'dinner',
        main_dish: 'Spaghetti Bolognaise',
        accompaniments: ['Fromage râpé', 'Pain à l\'ail', 'Salade'],
        description: 'Spaghetti avec sauce bolognaise maison',
        price: 4.0,
        available: true,
        image_url: '',
        created_by: 'system'
    },

    // Tuesday (2)
    {
        day_of_week: 2,
        meal_type: 'lunch',
        main_dish: 'Poulet grillé',
        accompaniments: ['Riz basmati', 'Légumes sautés', 'Sauce'],
        description: 'Poulet grillé aux herbes avec accompagnements',
        price: 4.5,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 2,
        meal_type: 'dinner',
        main_dish: 'Pizza Margherita',
        accompaniments: ['Salade mixte', 'Boisson'],
        description: 'Pizza fraîche avec mozzarella et basilic',
        price: 3.8,
        available: true,
        image_url: '',
        created_by: 'system'
    },

    // Wednesday (3)
    {
        day_of_week: 3,
        meal_type: 'lunch',
        main_dish: 'Poisson grillé',
        accompaniments: ['Pommes de terre', 'Ratatouille', 'Citron'],
        description: 'Poisson frais grillé avec légumes méditerranéens',
        price: 5.0,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 3,
        meal_type: 'dinner',
        main_dish: 'Tajine de légumes',
        accompaniments: ['Pain traditionnel', 'Olives', 'Salade'],
        description: 'Tajine végétarien aux légumes de saison',
        price: 3.2,
        available: true,
        image_url: '',
        created_by: 'system'
    },

    // Thursday (4)
    {
        day_of_week: 4,
        meal_type: 'lunch',
        main_dish: 'Escalope panée',
        accompaniments: ['Frites maison', 'Salade verte', 'Sauce'],
        description: 'Escalope de poulet panée avec frites croustillantes',
        price: 4.2,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 4,
        meal_type: 'dinner',
        main_dish: 'Lasagnes',
        accompaniments: ['Salade César', 'Pain à l\'ail', 'Parmesan'],
        description: 'Lasagnes à la viande avec béchamel onctueuse',
        price: 4.3,
        available: true,
        image_url: '',
        created_by: 'system'
    },

    // Friday (5)
    {
        day_of_week: 5,
        meal_type: 'lunch',
        main_dish: 'Kefta aux œufs',
        accompaniments: ['Pain frais', 'Salade de tomates', 'Harissa'],
        description: 'Kefta traditionnelle avec œufs et sauce tomate épicée',
        price: 3.8,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 5,
        meal_type: 'dinner',
        main_dish: 'Burger maison',
        accompaniments: ['Frites', 'Cornichons', 'Sauce spéciale'],
        description: 'Burger artisanal avec steak haché frais',
        price: 4.8,
        available: true,
        image_url: '',
        created_by: 'system'
    },

    // Saturday (6)
    {
        day_of_week: 6,
        meal_type: 'lunch',
        main_dish: 'Paella aux fruits de mer',
        accompaniments: ['Pain grillé', 'Citron', 'Aioli'],
        description: 'Paella valencienne aux fruits de mer frais',
        price: 5.5,
        available: true,
        image_url: '',
        created_by: 'system'
    },
    {
        day_of_week: 6,
        meal_type: 'dinner',
        main_dish: 'Gratin de pâtes',
        accompaniments: ['Salade verte', 'Pain', 'Fromage'],
        description: 'Gratin de pâtes au fromage et béchamel dorée',
        price: 3.5,
        available: true,
        image_url: '',
        created_by: 'system'
    }
];

// Generate time slots for the next 30 days
function generateTimeSlots() {
    const timeSlots = [];
    const today = new Date();

    // Generate slots for next 30 days
    for (let dayOffset = 0; dayOffset < 30; dayOffset++) {
        const currentDate = new Date(today);
        currentDate.setDate(today.getDate() + dayOffset);

        // Skip Sundays (day 0)
        if (currentDate.getDay() === 0) continue;

        // Lunch slots (12:00-14:00)
        const lunchSlots = [
            { start: '12:00', end: '12:30', capacity: 25 },
            { start: '12:30', end: '13:00', capacity: 25 },
            { start: '13:00', end: '13:30', capacity: 25 },
            { start: '13:30', end: '14:00', capacity: 25 }
        ];

        // Dinner slots (19:00-21:00)
        const dinnerSlots = [
            { start: '19:00', end: '19:30', capacity: 30 },
            { start: '19:30', end: '20:00', capacity: 30 },
            { start: '20:00', end: '20:30', capacity: 30 },
            { start: '20:30', end: '21:00', capacity: 30 }
        ];

        // Create lunch time slots
        lunchSlots.forEach(slot => {
            const startTime = new Date(currentDate);
            const [startHour, startMin] = slot.start.split(':');
            startTime.setHours(parseInt(startHour), parseInt(startMin), 0, 0);

            const endTime = new Date(currentDate);
            const [endHour, endMin] = slot.end.split(':');
            endTime.setHours(parseInt(endHour), parseInt(endMin), 0, 0);

            timeSlots.push({
                date: admin.firestore.Timestamp.fromDate(new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate())),
                start_time: admin.firestore.Timestamp.fromDate(startTime),
                end_time: admin.firestore.Timestamp.fromDate(endTime),
                meal_type: 'lunch',
                max_capacity: slot.capacity,
                current_reservations: Math.floor(Math.random() * 5), // Random current reservations (0-4)
                price: 3.5,
                is_active: true
            });
        });

        // Create dinner time slots
        dinnerSlots.forEach(slot => {
            const startTime = new Date(currentDate);
            const [startHour, startMin] = slot.start.split(':');
            startTime.setHours(parseInt(startHour), parseInt(startMin), 0, 0);

            const endTime = new Date(currentDate);
            const [endHour, endMin] = slot.end.split(':');
            endTime.setHours(parseInt(endHour), parseInt(endMin), 0, 0);

            timeSlots.push({
                date: admin.firestore.Timestamp.fromDate(new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate())),
                start_time: admin.firestore.Timestamp.fromDate(startTime),
                end_time: admin.firestore.Timestamp.fromDate(endTime),
                meal_type: 'dinner',
                max_capacity: slot.capacity,
                current_reservations: Math.floor(Math.random() * 8), // Random current reservations (0-7)
                price: 4.0,
                is_active: true
            });
        });
    }

    return timeSlots;
}

// Sample user data updates
const sampleUsers = [
    {
        email: 'student1.test@isetcom.tn',
        updates: {
            pocket: 25.0,
            role: 'student',
            display_name: 'Ahmed Ben Salem',
            class: 'L3 INFO'
        }
    },
    {
        email: 'student2.test@isetcom.tn',
        updates: {
            pocket: 30.0,
            role: 'student',
            display_name: 'Fatma Trabelsi',
            class: 'L2 MATH'
        }
    },
    {
        email: 'student3.test@isetcom.tn',
        updates: {
            pocket: 20.0,
            role: 'student',
            display_name: 'Mohamed Gharbi',
            class: 'L1 PHYS'
        }
    }
];

async function seedDatabase() {
    try {
        console.log('🚀 Starting database seeding...');

        // 1. Add weekly menus
        console.log('📋 Adding weekly menus...');
        const menuBatch = db.batch();
        let menuCount = 0;

        for (const menu of weeklyMenus) {
            const menuRef = db.collection('daily_menu').doc();
            menuBatch.set(menuRef, {
                ...menu,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });
            menuCount++;
        }

        await menuBatch.commit();
        console.log(`✅ Added ${menuCount} weekly menu items`);

        // 2. Add time slots
        console.log('⏰ Generating and adding time slots...');
        const timeSlots = generateTimeSlots();

        // Add time slots in batches of 500 (Firestore limit)
        const batchSize = 500;
        let slotCount = 0;

        for (let i = 0; i < timeSlots.length; i += batchSize) {
            const batch = db.batch();
            const batchSlots = timeSlots.slice(i, i + batchSize);

            for (const slot of batchSlots) {
                const slotRef = db.collection('time_slots').doc();
                batch.set(slotRef, slot);
                slotCount++;
            }

            await batch.commit();
            console.log(`📦 Added batch of ${batchSlots.length} time slots (${slotCount}/${timeSlots.length})`);
        }

        console.log(`✅ Added ${slotCount} time slots for next 30 days`);

        // 3. Update user data
        console.log('👥 Updating user data...');
        let userCount = 0;

        for (const userData of sampleUsers) {
            try {
                const userQuery = await db.collection('users')
                    .where('email', '==', userData.email)
                    .limit(1)
                    .get();

                if (!userQuery.empty) {
                    const userDoc = userQuery.docs[0];
                    await userDoc.ref.update({
                        ...userData.updates,
                        updated_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                    userCount++;
                    console.log(`✅ Updated user: ${userData.email}`);
                } else {
                    // Create new user if doesn't exist
                    await db.collection('users').add({
                        email: userData.email,
                        ...userData.updates,
                        created_at: admin.firestore.FieldValue.serverTimestamp(),
                        updated_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                    userCount++;
                    console.log(`✅ Created user: ${userData.email}`);
                }
            } catch (userError) {
                console.log(`⚠️ Could not update user ${userData.email}:`, userError.message);
            }
        }

        console.log(`✅ Processed ${userCount} users`);

        // 4. Summary
        console.log('\n🎉 Database seeding completed successfully!');
        console.log('📊 Summary:');
        console.log(`   • ${menuCount} weekly menu items added`);
        console.log(`   • ${slotCount} time slots created (30 days)`);
        console.log(`   • ${userCount} users updated`);
        console.log('\n🔍 What was added:');
        console.log('   • Monday-Saturday: 2 meals per day (lunch + dinner)');
        console.log('   • Sunday: Restaurant closed (no meals)');
        console.log('   • Time slots: 4 lunch slots + 4 dinner slots per day');
        console.log('   • User balances: 20-30 DT per student');
        console.log('\n✨ The app should now show:');
        console.log('   • Daily menus for each weekday');
        console.log('   • Available time slots for reservations');
        console.log('   • Student balances in home page');
        console.log('   • Functional reservation system');

    } catch (error) {
        console.error('❌ Error seeding database:', error);
        process.exit(1);
    }
}

// Run the seeding
seedDatabase()
    .then(() => {
        console.log('\n🚀 Ready to test the app!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Seeding failed:', error);
        process.exit(1);
    });