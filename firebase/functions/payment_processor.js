const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to process D17 payment confirmations
 * This function can be triggered by webhooks or scheduled tasks
 */
exports.processD17Payment = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { paymentRequestId, transactionId, status } = data;

    if (!paymentRequestId || !transactionId || !status) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    try {
        // Get payment request
        const paymentRef = db.collection('payment_requests').doc(paymentRequestId);
        const paymentDoc = await paymentRef.get();

        if (!paymentDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Payment request not found');
        }

        const paymentData = paymentDoc.data();

        // Verify payment is still pending
        if (paymentData.status !== 'pending') {
            throw new functions.https.HttpsError('failed-precondition', 'Payment is not pending');
        }

        // Check if payment has expired
        const now = admin.firestore.Timestamp.now();
        if (paymentData.expiresAt && paymentData.expiresAt < now) {
            await paymentRef.update({
                status: 'expired',
                updatedAt: now
            });
            throw new functions.https.HttpsError('deadline-exceeded', 'Payment has expired');
        }

        // Update payment status
        await paymentRef.update({
            status: status,
            transactionId: transactionId,
            completedAt: now,
            updatedAt: now
        });

        // Create notification
        await db.collection('notifications').add({
            userId: paymentData.userId,
            title: status === 'completed' ? 'Payment Successful' : 'Payment Failed',
            message: `Your payment of ${paymentData.amount.toFixed(3)} TND has been ${status}.`,
            type: `payment_${status}`,
            paymentId: paymentRequestId,
            amount: paymentData.amount,
            description: paymentData.description,
            isRead: false,
            createdAt: now
        });

        // If payment is successful, process the reservation
        if (status === 'completed') {
            await processReservationAfterPayment(paymentData);
        }

        return {
            success: true,
            message: `Payment ${status} successfully`,
            paymentId: paymentRequestId,
            transactionId: transactionId
        };

    } catch (error) {
        console.error('Error processing D17 payment:', error);
        throw new functions.https.HttpsError('internal', 'Failed to process payment');
    }
});

/**
 * Scheduled function to check for expired payments
 */
exports.checkExpiredPayments = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    try {
        const now = admin.firestore.Timestamp.now();

        // Query for pending payments that have expired
        const expiredPaymentsQuery = await db.collection('payment_requests')
            .where('status', '==', 'pending')
            .where('expiresAt', '<', now)
            .get();

        const batch = db.batch();
        const notifications = [];

        expiredPaymentsQuery.forEach((doc) => {
            const data = doc.data();

            // Update payment status to expired
            batch.update(doc.ref, {
                status: 'expired',
                updatedAt: now
            });

            // Prepare notification
            notifications.push({
                userId: data.userId,
                title: 'Payment Expired',
                message: `Your payment request for ${data.amount.toFixed(3)} TND has expired.`,
                type: 'payment_expired',
                paymentId: doc.id,
                amount: data.amount,
                description: data.description,
                isRead: false,
                createdAt: now
            });
        });

        // Commit batch update
        if (!expiredPaymentsQuery.empty) {
            await batch.commit();

            // Create notifications
            for (const notification of notifications) {
                await db.collection('notifications').add(notification);
            }

            console.log(`Expired ${expiredPaymentsQuery.size} payments`);
        }

        return null;
    } catch (error) {
        console.error('Error checking expired payments:', error);
        return null;
    }
});

/**
 * Helper function to process reservation after successful payment
 */
async function processReservationAfterPayment(paymentData) {
    try {
        // This would integrate with your existing reservation creation logic
        // For now, we'll just log the successful payment
        console.log(`Processing reservation for payment: ${paymentData.orderId}`);

        // You can add logic here to:
        // 1. Create the reservation
        // 2. Update user's ticket count
        // 3. Send confirmation email/SMS
        // 4. Update time slot capacity

        return true;
    } catch (error) {
        console.error('Error processing reservation after payment:', error);
        throw error;
    }
}

/**
 * HTTP endpoint for D17 webhooks (if available)
 */
exports.d17Webhook = functions.https.onRequest(async (req, res) => {
    // Verify webhook signature (implement based on D17 documentation)
    // const signature = req.headers['x-d17-signature'];
    // if (!verifyWebhookSignature(req.body, signature)) {
    //   return res.status(401).send('Unauthorized');
    // }

    try {
        const { paymentId, status, transactionId, amount } = req.body;

        if (!paymentId || !status) {
            return res.status(400).send('Missing required parameters');
        }

        // Find payment request by external payment ID
        const paymentQuery = await db.collection('payment_requests')
            .where('orderId', '==', paymentId)
            .where('status', '==', 'pending')
            .limit(1)
            .get();

        if (paymentQuery.empty) {
            return res.status(404).send('Payment not found');
        }

        const paymentDoc = paymentQuery.docs[0];
        const now = admin.firestore.Timestamp.now();

        // Update payment status
        await paymentDoc.ref.update({
            status: status,
            transactionId: transactionId,
            completedAt: now,
            updatedAt: now,
            webhookReceived: true
        });

        // Create notification
        const paymentData = paymentDoc.data();
        await db.collection('notifications').add({
            userId: paymentData.userId,
            title: status === 'completed' ? 'Payment Successful' : 'Payment Failed',
            message: `Your payment of ${amount.toFixed(3)} TND has been ${status}.`,
            type: `payment_${status}`,
            paymentId: paymentDoc.id,
            amount: amount,
            description: paymentData.description,
            isRead: false,
            createdAt: now
        });

        res.status(200).send('Webhook processed successfully');
    } catch (error) {
        console.error('Error processing D17 webhook:', error);
        res.status(500).send('Internal server error');
    }
});

/**
 * Function to get payment analytics
 */
exports.getPaymentAnalytics = functions.https.onCall(async (data, context) => {
    // Verify admin authentication
    if (!context.auth || !context.auth.token.role || context.auth.token.role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    try {
        const { startDate, endDate } = data;
        const start = startDate ? admin.firestore.Timestamp.fromDate(new Date(startDate)) : null;
        const end = endDate ? admin.firestore.Timestamp.fromDate(new Date(endDate)) : null;

        let query = db.collection('payment_requests');

        if (start) {
            query = query.where('createdAt', '>=', start);
        }
        if (end) {
            query = query.where('createdAt', '<=', end);
        }

        const snapshot = await query.get();

        let totalAmount = 0;
        let totalTransactions = 0;
        let successfulPayments = 0;
        let d17Payments = 0;
        let walletPayments = 0;
        let pendingPayments = 0;
        let expiredPayments = 0;

        snapshot.forEach((doc) => {
            const data = doc.data();
            totalTransactions++;

            switch (data.status) {
                case 'completed':
                    successfulPayments++;
                    totalAmount += data.amount;
                    break;
                case 'pending':
                    pendingPayments++;
                    break;
                case 'expired':
                    expiredPayments++;
                    break;
            }

            if (data.paymentMethod === 'd17') {
                d17Payments++;
            } else if (data.paymentMethod === 'wallet') {
                walletPayments++;
            }
        });

        return {
            totalAmount,
            totalTransactions,
            successfulPayments,
            successRate: totalTransactions > 0 ? (successfulPayments / totalTransactions) * 100 : 0,
            d17Payments,
            walletPayments,
            pendingPayments,
            expiredPayments,
            period: {
                startDate: start?.toDate().toISOString(),
                endDate: end?.toDate().toISOString()
            }
        };
    } catch (error) {
        console.error('Error getting payment analytics:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get analytics');
    }
});