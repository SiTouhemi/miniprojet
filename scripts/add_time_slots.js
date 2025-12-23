const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

// Function to create time slots for a specific date
function createTimeSlots(date) {
    const timeSlots = [];

    // Restaurant hours: 11:40 - 14:00 (every 20 minutes)
    const startHour = 11;
    const startMinute = 40;
    const endHour = 14;
    const endMinute = 0;

    // Create base date for the given date
    const baseDate = new Date(date);
    baseDate.setHours(0, 0, 0, 0);

    // Generate time slots every 20 minutes
    let currentTime = new Date(baseDate);
    currentTime.setHours(startHour, startMinute, 0, 0);

    const endTime = new Date(baseDate);
    endTime.setHours(endHour, endMinute, 0, 0);

    while (currentTime < endTime) {
        const slotEndTime = new Date(currentTime.getTime() + 20 * 60 * 1000); // Add 20 minutes

        // Don't create slot if it goes beyond restaurant closing time
        if (slotEndTime > endTime) {
            break;
        }

        timeSlots.push({
            start_time: admin.firestore.Timestamp.fromDate(currentTime),
            end_time: admin.firestore.Timestamp.fromDate(slotEndTime),
            date: admin.firestore.Timestamp.fromDate(baseDate),
            max_capacity: 30, // Maximum 30 people per slot
            current_reservations: 0,
            price: 8.50, // Price in TND
            is_active: true,
            meal_type: 'lunch'
        });

        // Move to next slot (20 minutes later)
        currentTime = new Date(slotEndTime);
    }

    return timeSlots;
}

// Function to add time slots to Firestore
async function addTimeSlots() {
    try {
        console.log('🕐 Adding time slots to database...');

        // Get today's date
        const today = new Date();

        // Add time slots for the next 7 days
        for (let i = 0; i < 7; i++) {
            const targetDate = new Date(today);
            targetDate.setDate(today.getDate() + i);

            console.log(`📅 Creating time slots for ${targetDate.toDateString()}`);

            const timeSlots = createTimeSlots(targetDate);

            // Add each time slot to Firestore
            for (const slot of timeSlots) {
                const startTime = slot.start_time.toDate();
                const endTime = slot.end_time.toDate();

                const timeString = `${startTime.getHours().toString().padStart(2, '0')}:${startTime.getMinutes().toString().padStart(2, '0')}-${endTime.getHours().toString().padStart(2, '0')}:${endTime.getMinutes().toString().padStart(2, '0')}`;

                await db.collection('time_slots').add(slot);
                console.log(`  ✅ Added slot: ${timeString}`);
            }
        }

        console.log('🎉 Time slots added successfully!');

        // Display summary
        const totalSlots = await db.collection('time_slots').get();
        console.log(`📊 Total time slots in database: ${totalSlots.size}`);

    } catch (error) {
        console.error('❌ Error adding time slots:', error);
    }
}

// Function to display existing time slots
async function displayTimeSlots() {
    try {
        console.log('📋 Current time slots in database:');

        const snapshot = await db.collection('time_slots')
            .orderBy('date')
            .orderBy('start_time')
            .get();

        if (snapshot.empty) {
            console.log('  No time slots found.');
            return;
        }

        let currentDate = null;
        snapshot.forEach(doc => {
            const data = doc.data();
            const date = data.date.toDate();
            const startTime = data.start_time.toDate();
            const endTime = data.end_time.toDate();

            const dateString = date.toDateString();
            if (currentDate !== dateString) {
                console.log(`\n📅 ${dateString}:`);
                currentDate = dateString;
            }

            const timeString = `${startTime.getHours().toString().padStart(2, '0')}:${startTime.getMinutes().toString().padStart(2, '0')}-${endTime.getHours().toString().padStart(2, '0')}:${endTime.getMinutes().toString().padStart(2, '0')}`;
            console.log(`  🕐 ${timeString} | Capacity: ${data.max_capacity} | Reserved: ${data.current_reservations} | Price: ${data.price} TND`);
        });

    } catch (error) {
        console.error('❌ Error displaying time slots:', error);
    }
}

// Main execution
async function main() {
    const args = process.argv.slice(2);

    if (args.includes('--display') || args.includes('-d')) {
        await displayTimeSlots();
    } else {
        await addTimeSlots();
        console.log('\n');
        await displayTimeSlots();
    }

    process.exit(0);
}

main();