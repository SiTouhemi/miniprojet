const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// UC19: Calculate Total Tickets Sold
exports.calculateTotalTickets = functions.https.onCall(async (data, context) => {
    try {
        const { startDate, endDate } = data;

        let query = db.collection('reservation').where('status', '==', 'confirmed');

        if (startDate) {
            query = query.where('created_at', '>=', new Date(startDate));
        }
        if (endDate) {
            query = query.where('created_at', '<=', new Date(endDate));
        }

        const snapshot = await query.get();
        const totalTickets = snapshot.size;
        const totalRevenue = snapshot.docs.reduce((sum, doc) => sum + (doc.data().prix || 0), 0);

        return {
            success: true,
            totalTickets,
            totalRevenue,
            period: { startDate, endDate }
        };
    } catch (error) {
        console.error('Error calculating tickets:', error);
        return { success: false, error: error.message };
    }
});

// UC22: D17 Payment Verification
exports.verifyD17Payment = functions.https.onCall(async (data, context) => {
    try {
        const { paymentId, amount, userId } = data;

        // Simulate D17 API call (replace with actual D17 integration)
        const d17Response = await simulateD17Verification(paymentId, amount);

        if (d17Response.success) {
            // Update user's pocket money
            await db.collection('user').doc(userId).update({
                pocket: admin.firestore.FieldValue.increment(-amount)
            });

            return {
                success: true,
                transactionId: d17Response.transactionId,
                verifiedAmount: amount
            };
        } else {
            return {
                success: false,
                error: 'Payment verification failed'
            };
        }
    } catch (error) {
        console.error('Error verifying payment:', error);
        return { success: false, error: error.message };
    }
});

// UC20: Create Reservation with QR Code
exports.createReservation = functions.https.onCall(async (data, context) => {
    try {
        const { userId, timeSlotId, mealType, paymentId } = data;

        // Check time slot availability
        const timeSlotDoc = await db.collection('time_slots').doc(timeSlotId).get();
        const timeSlot = timeSlotDoc.data();

        if (!timeSlot || timeSlot.current_reservations >= timeSlot.max_capacity) {
            return { success: false, error: 'Time slot is full' };
        }

        // Generate QR code data
        const qrCode = generateQRCode(userId, timeSlotId);

        // Create reservation
        const reservationData = {
            user_id: userId,
            type: mealType,
            prix: timeSlot.price,
            total: timeSlot.price,
            creneaux: timeSlot.start_time,
            status: 'confirmed',
            qr_code: qrCode,
            payment_id: paymentId,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            capacity: 1
        };

        const reservationRef = await db.collection('reservation').add(reservationData);

        // Update time slot capacity
        await db.collection('time_slots').doc(timeSlotId).update({
            current_reservations: admin.firestore.FieldValue.increment(1)
        });

        // Update user tickets
        await db.collection('user').doc(userId).update({
            tickets: admin.firestore.FieldValue.increment(1)
        });

        return {
            success: true,
            reservationId: reservationRef.id,
            qrCode: qrCode
        };
    } catch (error) {
        console.error('Error creating reservation:', error);
        return { success: false, error: error.message };
    }
});

// QR Code Validation for Staff
exports.validateQRCode = functions.https.onCall(async (data, context) => {
    try {
        const { qrCode, staffId } = data;

        // Find reservation by QR code
        const reservationSnapshot = await db.collection('reservation')
            .where('qr_code', '==', qrCode)
            .where('status', '==', 'confirmed')
            .get();

        if (reservationSnapshot.empty) {
            return { success: false, error: 'Invalid or already used ticket' };
        }

        const reservationDoc = reservationSnapshot.docs[0];
        const reservation = reservationDoc.data();

        // Check if ticket is for today
        const today = new Date();
        const reservationDate = reservation.creneaux.toDate();

        if (reservationDate.toDateString() !== today.toDateString()) {
            return { success: false, error: 'Ticket is not valid for today' };
        }

        // Mark ticket as used
        await reservationDoc.ref.update({
            status: 'used',
            used_at: admin.firestore.FieldValue.serverTimestamp(),
            validated_by: staffId
        });

        return {
            success: true,
            message: 'Ticket validated successfully',
            userInfo: {
                name: reservation.user_name || 'Student',
                mealType: reservation.type
            }
        };
    } catch (error) {
        console.error('Error validating QR code:', error);
        return { success: false, error: error.message };
    }
});

// UC27: Analytics and Peak Time Analysis
exports.generateAnalytics = functions.pubsub.schedule('0 1 * * *').onRun(async (context) => {
    try {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        yesterday.setHours(0, 0, 0, 0);

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Get reservations for yesterday
        const reservationsSnapshot = await db.collection('reservation')
            .where('created_at', '>=', yesterday)
            .where('created_at', '<', today)
            .get();

        const reservations = reservationsSnapshot.docs.map(doc => doc.data());

        // Calculate analytics
        const totalReservations = reservations.length;
        const totalRevenue = reservations.reduce((sum, res) => sum + (res.prix || 0), 0);
        const cancellationRate = reservations.filter(res => res.status === 'cancelled').length / totalReservations;

        // Find peak hour
        const hourCounts = {};
        reservations.forEach(res => {
            if (res.creneaux) {
                const hour = res.creneaux.toDate().getHours();
                hourCounts[hour] = (hourCounts[hour] || 0) + 1;
            }
        });

        const peakHour = Object.keys(hourCounts).reduce((a, b) =>
            hourCounts[a] > hourCounts[b] ? a : b, '12');

        // Save analytics
        await db.collection('analytics').add({
            date: yesterday,
            total_reservations: totalReservations,
            total_revenue: totalRevenue,
            peak_hour: `${peakHour}:00`,
            cancellation_rate: cancellationRate,
            average_occupancy: totalReservations / 100 // Assuming 100 total capacity
        });

        console.log('Analytics generated for', yesterday.toDateString());
    } catch (error) {
        console.error('Error generating analytics:', error);
    }
});

// Send Notifications
exports.sendReservationReminder = functions.pubsub.schedule('0 10 * * *').onRun(async (context) => {
    try {
        const today = new Date();
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);

        // Get reservations for today
        const reservationsSnapshot = await db.collection('reservation')
            .where('creneaux', '>=', today)
            .where('creneaux', '<', tomorrow)
            .where('status', '==', 'confirmed')
            .get();

        const notifications = [];

        for (const doc of reservationsSnapshot.docs) {
            const reservation = doc.data();
            const userDoc = await db.collection('user').doc(reservation.user_id).get();
            const user = userDoc.data();

            if (user && user.notifications_enabled) {
                notifications.push({
                    userId: reservation.user_id,
                    title: 'Reservation Reminder',
                    message: `Don't forget your ${reservation.type} reservation today!`,
                    reservationId: doc.id
                });
            }
        }

        // Here you would integrate with your notification service (FCM, OneSignal, etc.)
        console.log(`Sent ${notifications.length} reminder notifications`);

    } catch (error) {
        console.error('Error sending notifications:', error);
    }
});

// Helper Functions
function generateQRCode(userId, timeSlotId) {
    const timestamp = Date.now();
    return `${userId}_${timeSlotId}_${timestamp}`;
}

async function simulateD17Verification(paymentId, amount) {
    // Simulate D17 API response
    // In production, replace with actual D17 API integration
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve({
                success: Math.random() > 0.1, // 90% success rate for simulation
                transactionId: `D17_${Date.now()}`
            });
        }, 1000);
    });
}
