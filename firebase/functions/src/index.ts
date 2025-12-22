import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// Types
interface ReservationData {
    userId: string;
    timeSlotId: string;
    capacity: number;
    amount: number;
}

interface QRTokenPayload {
    iss: string;
    sub: string;
    aud: string;
    exp: number;
    iat: number;
    userId: string;
    timeSlot: string;
    capacity: number;
}

interface AuditLogData {
    timestamp: admin.firestore.Timestamp;
    userId: string;
    userRole: string;
    action: string;
    resource: string;
    resourceId?: string;
    details: Record<string, any>;
    ipAddress?: string;
    userAgent?: string;
    result: 'success' | 'failure';
    errorMessage?: string;
}

// Configuration
const JWT_SECRET = functions.config().app?.jwt_secret || 'default-secret-change-in-production';

// Helper Functions
async function validateAuth(context: functions.https.CallableContext): Promise<{ uid: string; role: string }> {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const role = context.auth.token.role;

    if (!role) {
        throw new functions.https.HttpsError('permission-denied', 'User role not found');
    }

    return { uid, role };
}

async function createAuditLog(logData: Partial<AuditLogData>): Promise<void> {
    try {
        const auditLog: AuditLogData = {
            timestamp: admin.firestore.Timestamp.now(),
            userId: logData.userId || 'system',
            userRole: logData.userRole || 'system',
            action: logData.action || 'unknown',
            resource: logData.resource || 'unknown',
            resourceId: logData.resourceId,
            details: logData.details || {},
            ipAddress: logData.ipAddress,
            userAgent: logData.userAgent,
            result: logData.result || 'success',
            errorMessage: logData.errorMessage
        };

        await db.collection('audit_logs').add(auditLog);
    } catch (error) {
        console.error('Failed to create audit log:', error);
    }
}

function createQRToken(reservationId: string, userId: string, timeSlot: string, capacity: number): string {
    const now = Math.floor(Date.now() / 1000);
    const expiration = now + (2 * 60 * 60); // 2 hours from now

    const payload: QRTokenPayload = {
        iss: 'isetcom-restaurant',
        sub: reservationId,
        aud: 'restaurant-entry',
        exp: expiration,
        iat: now,
        userId,
        timeSlot,
        capacity
    };

    return jwt.sign(payload, JWT_SECRET, { algorithm: 'HS256' });
}

function validateQRToken(token: string): QRTokenPayload {
    try {
        const decoded = jwt.verify(token, JWT_SECRET, {
            algorithms: ['HS256'],
            issuer: 'isetcom-restaurant',
            audience: 'restaurant-entry'
        }) as QRTokenPayload;

        return decoded;
    } catch (error) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid QR token');
    }
}

// Authentication Functions

/**
 * Set custom claims for user role
 */
export const setUserRole = functions.https.onCall(async (data: { uid: string; role: string }, context) => {
    try {
        const { uid: adminUid, role: adminRole } = await validateAuth(context);

        if (adminRole !== 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can set user roles');
        }

        const { uid, role } = data;

        if (!uid || !role || !['student', 'staff', 'admin'].includes(role)) {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid uid or role');
        }

        // Set custom claims
        await auth.setCustomUserClaims(uid, { role });

        // Update user document
        await db.collection('user').doc(uid).update({
            role,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await createAuditLog({
            userId: adminUid,
            userRole: adminRole,
            action: 'set_user_role',
            resource: 'user',
            resourceId: uid,
            details: { newRole: role },
            result: 'success'
        });

        return { success: true, message: 'User role updated successfully' };
    } catch (error) {
        console.error('Error setting user role:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'set_user_role',
            resource: 'user',
            resourceId: data.uid,
            details: { attemptedRole: data.role },
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to set user role');
    }
});

/**
 * Create user with role (admin only)
 */
export const createUserWithRole = functions.https.onCall(async (data: {
    email: string;
    password: string;
    displayName: string;
    role: string;
    cin?: number;
    classe?: string;
    phoneNumber?: string;
}, context) => {
    try {
        const { uid: adminUid, role: adminRole } = await validateAuth(context);

        if (adminRole !== 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can create users');
        }

        const { email, password, displayName, role, cin, classe, phoneNumber } = data;

        if (!email || !password || !displayName || !role) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
        }

        if (!['student', 'staff', 'admin'].includes(role)) {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
        }

        // Create Firebase Auth user
        const userRecord = await auth.createUser({
            email,
            password,
            displayName
        });

        // Set custom claims
        await auth.setCustomUserClaims(userRecord.uid, { role });

        // Create Firestore user document
        const userData = {
            uid: userRecord.uid,
            email,
            displayName,
            role,
            cin: cin || null,
            classe: classe || null,
            phoneNumber: phoneNumber || null,
            pocket: 0,
            tickets: 0,
            language: 'fr',
            notificationsEnabled: true,
            createdTime: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: adminUid
        };

        await db.collection('user').doc(userRecord.uid).set(userData);

        await createAuditLog({
            userId: adminUid,
            userRole: adminRole,
            action: 'create_user',
            resource: 'user',
            resourceId: userRecord.uid,
            details: { email, role, displayName },
            result: 'success'
        });

        return {
            success: true,
            uid: userRecord.uid,
            message: 'User created successfully'
        };
    } catch (error) {
        console.error('Error creating user:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'create_user',
            resource: 'user',
            details: { email: data.email, role: data.role },
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to create user');
    }
});

// Reservation Functions

/**
 * Create reservation with atomic operations
 */
export const createReservation = functions.https.onCall(async (data: ReservationData, context) => {
    try {
        const { uid, role } = await validateAuth(context);

        if (role !== 'student') {
            throw new functions.https.HttpsError('permission-denied', 'Only students can create reservations');
        }

        const { timeSlotId, capacity = 1, amount } = data;

        if (!timeSlotId || capacity <= 0 || amount <= 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid reservation data');
        }

        // Use transaction for atomic operations
        const result = await db.runTransaction(async (transaction) => {
            // Get time slot
            const timeSlotRef = db.collection('time_slots').doc(timeSlotId);
            const timeSlotDoc = await transaction.get(timeSlotRef);

            if (!timeSlotDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Time slot not found');
            }

            const timeSlot = timeSlotDoc.data()!;

            // Check availability
            if (!timeSlot.isActive) {
                throw new functions.https.HttpsError('failed-precondition', 'Time slot is not active');
            }

            if (timeSlot.currentReservations + capacity > timeSlot.maxCapacity) {
                throw new functions.https.HttpsError('failed-precondition', 'Time slot is full');
            }

            // Check if user already has reservation for this slot
            const existingReservation = await db.collection('reservation')
                .where('userId', '==', uid)
                .where('timeSlotId', '==', timeSlotId)
                .where('status', 'in', ['pending', 'confirmed'])
                .get();

            if (!existingReservation.empty) {
                throw new functions.https.HttpsError('already-exists', 'User already has a reservation for this time slot');
            }

            // Create reservation
            const reservationRef = db.collection('reservation').doc();
            const reservationData = {
                id: reservationRef.id,
                userId: uid,
                timeSlotId,
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                capacity,
                amount,
                paymentId: null,
                qrToken: null
            };

            transaction.set(reservationRef, reservationData);

            // Update time slot capacity
            transaction.update(timeSlotRef, {
                currentReservations: admin.firestore.FieldValue.increment(capacity)
            });

            return { reservationId: reservationRef.id, timeSlot };
        });

        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'create_reservation',
            resource: 'reservation',
            resourceId: result.reservationId,
            details: { timeSlotId, capacity, amount },
            result: 'success'
        });

        return {
            success: true,
            reservationId: result.reservationId,
            message: 'Reservation created successfully'
        };
    } catch (error) {
        console.error('Error creating reservation:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'create_reservation',
            resource: 'reservation',
            details: data,
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to create reservation');
    }
});

// QR Code Functions

/**
 * Generate QR token for confirmed reservation
 */
export const generateQRToken = functions.https.onCall(async (data: { reservationId: string }, context) => {
    try {
        const { uid, role } = await validateAuth(context);
        const { reservationId } = data;

        if (!reservationId) {
            throw new functions.https.HttpsError('invalid-argument', 'Reservation ID is required');
        }

        // Get reservation
        const reservationDoc = await db.collection('reservation').doc(reservationId).get();

        if (!reservationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Reservation not found');
        }

        const reservation = reservationDoc.data()!;

        // Verify ownership or admin/staff access
        if (reservation.userId !== uid && !['admin', 'staff'].includes(role)) {
            throw new functions.https.HttpsError('permission-denied', 'Access denied');
        }

        // Check reservation status
        if (reservation.status !== 'confirmed') {
            throw new functions.https.HttpsError('failed-precondition', 'Reservation must be confirmed to generate QR code');
        }

        // Get time slot for token
        const timeSlotDoc = await db.collection('time_slots').doc(reservation.timeSlotId).get();
        const timeSlot = timeSlotDoc.data()!;

        // Generate QR token
        const qrToken = createQRToken(
            reservationId,
            reservation.userId,
            timeSlot.startTime.toDate().toISOString(),
            reservation.capacity
        );

        // Update reservation with QR token
        await db.collection('reservation').doc(reservationId).update({
            qrToken,
            qrGeneratedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'generate_qr_token',
            resource: 'reservation',
            resourceId: reservationId,
            details: { reservationId },
            result: 'success'
        });

        return {
            success: true,
            qrToken,
            message: 'QR token generated successfully'
        };
    } catch (error) {
        console.error('Error generating QR token:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'generate_qr_token',
            resource: 'reservation',
            resourceId: data.reservationId,
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to generate QR token');
    }
});

/**
 * Cancel reservation with atomic operations
 */
export const cancelReservation = functions.https.onCall(async (data: { reservationId: string, reason?: string }, context) => {
    try {
        const { uid, role } = await validateAuth(context);
        const { reservationId, reason } = data;

        if (!reservationId) {
            throw new functions.https.HttpsError('invalid-argument', 'Reservation ID is required');
        }

        // Use transaction for atomic operations
        const result = await db.runTransaction(async (transaction) => {
            // Get reservation
            const reservationRef = db.collection('reservation').doc(reservationId);
            const reservationDoc = await transaction.get(reservationRef);

            if (!reservationDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Reservation not found');
            }

            const reservation = reservationDoc.data()!;

            // Check ownership (unless admin/staff)
            if (reservation.userId !== uid && !['admin', 'staff'].includes(role)) {
                throw new functions.https.HttpsError('permission-denied', 'Access denied');
            }

            // Check if reservation can be cancelled
            if (reservation.status === 'cancelled') {
                throw new functions.https.HttpsError('failed-precondition', 'Reservation is already cancelled');
            }

            if (reservation.status === 'used') {
                throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel used reservation');
            }

            // Check timing - prevent cancellation of past reservations
            const now = admin.firestore.Timestamp.now();
            const reservationTime = reservation.creneaux;

            if (reservationTime && reservationTime.toDate() < now.toDate()) {
                throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel past reservations');
            }

            // Check if cancellation is too close to meal time (2 hours minimum)
            if (reservationTime) {
                const hoursUntilMeal = (reservationTime.toDate().getTime() - now.toDate().getTime()) / (1000 * 60 * 60);
                if (hoursUntilMeal < 2) {
                    throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel reservation less than 2 hours before meal time');
                }
            }

            // Find time slot to update capacity
            const timeSlotsQuery = await db.collection('time_slots')
                .where('start_time', '==', reservationTime)
                .limit(1)
                .get();

            if (timeSlotsQuery.empty) {
                throw new functions.https.HttpsError('not-found', 'Associated time slot not found');
            }

            const timeSlotDoc = timeSlotsQuery.docs[0];
            const capacity = reservation.capacity || 1;

            // Update reservation status
            transaction.update(reservationRef, {
                status: 'cancelled',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                cancellationReason: reason || 'User cancelled',
                modifiedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Atomically decrement time slot capacity
            transaction.update(timeSlotDoc.ref, {
                currentReservations: admin.firestore.FieldValue.increment(-capacity)
            });

            return { reservationId, capacity };
        });

        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'cancel_reservation',
            resource: 'reservation',
            resourceId: reservationId,
            details: { reason: reason || 'User cancelled' },
            result: 'success'
        });

        return {
            success: true,
            message: 'Reservation cancelled successfully',
            reservationId: result.reservationId
        };
    } catch (error) {
        console.error('Error cancelling reservation:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'cancel_reservation',
            resource: 'reservation',
            resourceId: data.reservationId,
            details: { reason: data.reason },
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to cancel reservation');
    }
});

/**
 * Modify reservation (change time slot) with atomic operations
 */
export const modifyReservation = functions.https.onCall(async (data: {
    reservationId: string,
    newTimeSlotId: string
}, context) => {
    try {
        const { uid, role } = await validateAuth(context);
        const { reservationId, newTimeSlotId } = data;

        if (!reservationId || !newTimeSlotId) {
            throw new functions.https.HttpsError('invalid-argument', 'Reservation ID and new time slot ID are required');
        }

        // Use transaction for atomic operations
        const result = await db.runTransaction(async (transaction) => {
            // Get current reservation
            const reservationRef = db.collection('reservation').doc(reservationId);
            const reservationDoc = await transaction.get(reservationRef);

            if (!reservationDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'Reservation not found');
            }

            const reservation = reservationDoc.data()!;

            // Check ownership (unless admin/staff)
            if (reservation.userId !== uid && !['admin', 'staff'].includes(role)) {
                throw new functions.https.HttpsError('permission-denied', 'Access denied');
            }

            // Check if reservation can be modified
            if (reservation.status !== 'confirmed' && reservation.status !== 'pending') {
                throw new functions.https.HttpsError('failed-precondition', 'Only confirmed or pending reservations can be modified');
            }

            const now = admin.firestore.Timestamp.now();
            const currentReservationTime = reservation.creneaux;

            // Prevent modification of past reservations
            if (currentReservationTime && currentReservationTime.toDate() < now.toDate()) {
                throw new functions.https.HttpsError('failed-precondition', 'Cannot modify past reservations');
            }

            // Check if modification is too close to meal time (2 hours minimum)
            if (currentReservationTime) {
                const hoursUntilMeal = (currentReservationTime.toDate().getTime() - now.toDate().getTime()) / (1000 * 60 * 60);
                if (hoursUntilMeal < 2) {
                    throw new functions.https.HttpsError('failed-precondition', 'Cannot modify reservation less than 2 hours before meal time');
                }
            }

            // Get new time slot
            const newTimeSlotRef = db.collection('time_slots').doc(newTimeSlotId);
            const newTimeSlotDoc = await transaction.get(newTimeSlotRef);

            if (!newTimeSlotDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'New time slot not found');
            }

            const newTimeSlot = newTimeSlotDoc.data()!;

            // Check if new time slot is in the future
            if (newTimeSlot.startTime && newTimeSlot.startTime.toDate() < now.toDate()) {
                throw new functions.https.HttpsError('failed-precondition', 'Cannot modify to a past time slot');
            }

            const capacity = reservation.capacity || 1;

            // Check availability in new time slot
            if (newTimeSlot.currentReservations + capacity > newTimeSlot.maxCapacity) {
                throw new functions.https.HttpsError('failed-precondition', 'New time slot does not have enough capacity');
            }

            // Find old time slot
            const oldTimeSlotsQuery = await db.collection('time_slots')
                .where('start_time', '==', currentReservationTime)
                .limit(1)
                .get();

            if (oldTimeSlotsQuery.empty) {
                throw new functions.https.HttpsError('not-found', 'Original time slot not found');
            }

            const oldTimeSlotDoc = oldTimeSlotsQuery.docs[0];

            // Update reservation
            transaction.update(reservationRef, {
                creneaux: newTimeSlot.startTime,
                prix: newTimeSlot.price,
                total: newTimeSlot.price * capacity,
                modifiedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Update old time slot (increase capacity)
            transaction.update(oldTimeSlotDoc.ref, {
                currentReservations: admin.firestore.FieldValue.increment(-capacity)
            });

            // Update new time slot (decrease capacity)
            transaction.update(newTimeSlotRef, {
                currentReservations: admin.firestore.FieldValue.increment(capacity)
            });

            return {
                reservationId,
                newTimeSlot: {
                    id: newTimeSlotId,
                    startTime: newTimeSlot.startTime,
                    endTime: newTimeSlot.endTime,
                    price: newTimeSlot.price
                }
            };
        });

        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'modify_reservation',
            resource: 'reservation',
            resourceId: reservationId,
            details: {
                newTimeSlotId,
                oldTimeSlot: result.newTimeSlot.startTime,
                newTimeSlot: result.newTimeSlot.startTime
            },
            result: 'success'
        });

        return {
            success: true,
            message: 'Reservation modified successfully',
            reservationId: result.reservationId,
            newTimeSlot: result.newTimeSlot
        };
    } catch (error) {
        console.error('Error modifying reservation:', error);

        await createAuditLog({
            userId: context.auth?.uid || 'unknown',
            userRole: context.auth?.token?.role || 'unknown',
            action: 'modify_reservation',
            resource: 'reservation',
            resourceId: data.reservationId,
            details: { newTimeSlotId: data.newTimeSlotId },
            result: 'failure',
            errorMessage: error instanceof Error ? error.message : 'Unknown error'
        });

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to modify reservation');
    }
});
try {
    const { uid, role } = await validateAuth(context);

    if (!['staff', 'admin'].includes(role)) {
        throw new functions.https.HttpsError('permission-denied', 'Only staff and admins can validate QR codes');
    }

    const { qrToken } = data;

    if (!qrToken) {
        throw new functions.https.HttpsError('invalid-argument', 'QR token is required');
    }

    // Validate and decode token
    const tokenPayload = validateQRToken(qrToken);

    // Get reservation
    const reservationDoc = await db.collection('reservation').doc(tokenPayload.sub).get();

    if (!reservationDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Reservation not found');
    }

    const reservation = reservationDoc.data()!;

    // Check reservation status
    if (reservation.status === 'used') {
        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'validate_qr_code',
            resource: 'reservation',
            resourceId: tokenPayload.sub,
            details: { qrToken: qrToken.substring(0, 20) + '...', result: 'already_used' },
            result: 'failure',
            errorMessage: 'Ticket already used'
        });

        return {
            success: false,
            error: 'already_used',
            message: 'Ticket has already been used',
            usedAt: reservation.usedAt
        };
    }

    if (reservation.status !== 'confirmed') {
        await createAuditLog({
            userId: uid,
            userRole: role,
            action: 'validate_qr_code',
            resource: 'reservation',
            resourceId: tokenPayload.sub,
            details: { qrToken: qrToken.substring(0, 20) + '...', status: reservation.status },
            result: 'failure',
            errorMessage: 'Invalid reservation status'
        });

        return {
            success: false,
            error: 'invalid_status',
            message: 'Reservation is not confirmed'
        };
    }

    // Get user info
    const userDoc = await db.collection('user').doc(reservation.userId).get();
    const user = userDoc.data();

    // Mark as used
    await db.collection('reservation').doc(tokenPayload.sub).update({
        status: 'used',
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        validatedBy: uid
    });

    await createAuditLog({
        userId: uid,
        userRole: role,
        action: 'validate_qr_code',
        resource: 'reservation',
        resourceId: tokenPayload.sub,
        details: {
            qrToken: qrToken.substring(0, 20) + '...',
            studentId: reservation.userId,
            studentName: user?.displayName || 'Unknown'
        },
        result: 'success'
    });

    return {
        success: true,
        message: 'Ticket validated successfully',
        userInfo: {
            name: user?.displayName || 'Unknown Student',
            email: user?.email || '',
            classe: user?.classe || '',
            capacity: reservation.capacity
        },
        reservationInfo: {
            timeSlot: tokenPayload.timeSlot,
            amount: reservation.amount
        }
    };
} catch (error) {
    console.error('Error validating QR code:', error);

    await createAuditLog({
        userId: context.auth?.uid || 'unknown',
        userRole: context.auth?.token?.role || 'unknown',
        action: 'validate_qr_code',
        resource: 'reservation',
        details: { qrToken: data.qrToken?.substring(0, 20) + '...' },
        result: 'failure',
        errorMessage: error instanceof Error ? error.message : 'Unknown error'
    });

    if (error instanceof functions.https.HttpsError) {
        throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to validate QR code');
}
});

// Trigger Functions

/**
 * Set custom claims when user document is created
 */
export const onUserCreate = functions.firestore
    .document('user/{userId}')
    .onCreate(async (snap, context) => {
        try {
            const userData = snap.data();
            const userId = context.params.userId;

            if (userData.role) {
                await auth.setCustomUserClaims(userId, { role: userData.role });
                console.log(`Set custom claims for user ${userId} with role ${userData.role}`);
            }
        } catch (error) {
            console.error('Error setting custom claims on user creation:', error);
        }
    });

/**
 * Update custom claims when user role is updated
 */
export const onUserUpdate = functions.firestore
    .document('user/{userId}')
    .onUpdate(async (change, context) => {
        try {
            const beforeData = change.before.data();
            const afterData = change.after.data();
            const userId = context.params.userId;

            if (beforeData.role !== afterData.role) {
                await auth.setCustomUserClaims(userId, { role: afterData.role });
                console.log(`Updated custom claims for user ${userId} from ${beforeData.role} to ${afterData.role}`);
            }
        } catch (error) {
            console.error('Error updating custom claims on user update:', error);
        }
    });