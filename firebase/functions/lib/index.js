"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserUpdate = exports.onUserCreate = exports.validateQRCode = exports.generateQRToken = exports.createReservation = exports.createUserWithRole = exports.setUserRole = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const jwt = __importStar(require("jsonwebtoken"));
// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();
// Configuration
const JWT_SECRET = ((_a = functions.config().app) === null || _a === void 0 ? void 0 : _a.jwt_secret) || 'default-secret-change-in-production';
// Helper Functions
async function validateAuth(context) {
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
async function createAuditLog(logData) {
    try {
        const auditLog = {
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
    }
    catch (error) {
        console.error('Failed to create audit log:', error);
    }
}
function createQRToken(reservationId, userId, timeSlot, capacity) {
    const now = Math.floor(Date.now() / 1000);
    const expiration = now + (2 * 60 * 60); // 2 hours from now
    const payload = {
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
function validateQRToken(token) {
    try {
        const decoded = jwt.verify(token, JWT_SECRET, {
            algorithms: ['HS256'],
            issuer: 'isetcom-restaurant',
            audience: 'restaurant-entry'
        });
        return decoded;
    }
    catch (error) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid QR token');
    }
}
// Authentication Functions
/**
 * Set custom claims for user role
 */
exports.setUserRole = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
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
    }
    catch (error) {
        console.error('Error setting user role:', error);
        await createAuditLog({
            userId: ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'unknown',
            userRole: ((_c = (_b = context.auth) === null || _b === void 0 ? void 0 : _b.token) === null || _c === void 0 ? void 0 : _c.role) || 'unknown',
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
exports.createUserWithRole = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
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
    }
    catch (error) {
        console.error('Error creating user:', error);
        await createAuditLog({
            userId: ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'unknown',
            userRole: ((_c = (_b = context.auth) === null || _b === void 0 ? void 0 : _b.token) === null || _c === void 0 ? void 0 : _c.role) || 'unknown',
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
exports.createReservation = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
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
            const timeSlot = timeSlotDoc.data();
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
    }
    catch (error) {
        console.error('Error creating reservation:', error);
        await createAuditLog({
            userId: ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'unknown',
            userRole: ((_c = (_b = context.auth) === null || _b === void 0 ? void 0 : _b.token) === null || _c === void 0 ? void 0 : _c.role) || 'unknown',
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
exports.generateQRToken = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
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
        const reservation = reservationDoc.data();
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
        const timeSlot = timeSlotDoc.data();
        // Generate QR token
        const qrToken = createQRToken(reservationId, reservation.userId, timeSlot.startTime.toDate().toISOString(), reservation.capacity);
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
    }
    catch (error) {
        console.error('Error generating QR token:', error);
        await createAuditLog({
            userId: ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'unknown',
            userRole: ((_c = (_b = context.auth) === null || _b === void 0 ? void 0 : _b.token) === null || _c === void 0 ? void 0 : _c.role) || 'unknown',
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
 * Validate QR token for staff
 */
exports.validateQRCode = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d;
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
        const reservation = reservationDoc.data();
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
                studentName: (user === null || user === void 0 ? void 0 : user.displayName) || 'Unknown'
            },
            result: 'success'
        });
        return {
            success: true,
            message: 'Ticket validated successfully',
            userInfo: {
                name: (user === null || user === void 0 ? void 0 : user.displayName) || 'Unknown Student',
                email: (user === null || user === void 0 ? void 0 : user.email) || '',
                classe: (user === null || user === void 0 ? void 0 : user.classe) || '',
                capacity: reservation.capacity
            },
            reservationInfo: {
                timeSlot: tokenPayload.timeSlot,
                amount: reservation.amount
            }
        };
    }
    catch (error) {
        console.error('Error validating QR code:', error);
        await createAuditLog({
            userId: ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'unknown',
            userRole: ((_c = (_b = context.auth) === null || _b === void 0 ? void 0 : _b.token) === null || _c === void 0 ? void 0 : _c.role) || 'unknown',
            action: 'validate_qr_code',
            resource: 'reservation',
            details: { qrToken: ((_d = data.qrToken) === null || _d === void 0 ? void 0 : _d.substring(0, 20)) + '...' },
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
exports.onUserCreate = functions.firestore
    .document('user/{userId}')
    .onCreate(async (snap, context) => {
    try {
        const userData = snap.data();
        const userId = context.params.userId;
        if (userData.role) {
            await auth.setCustomUserClaims(userId, { role: userData.role });
            console.log(`Set custom claims for user ${userId} with role ${userData.role}`);
        }
    }
    catch (error) {
        console.error('Error setting custom claims on user creation:', error);
    }
});
/**
 * Update custom claims when user role is updated
 */
exports.onUserUpdate = functions.firestore
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
    }
    catch (error) {
        console.error('Error updating custom claims on user update:', error);
    }
});
//# sourceMappingURL=index.js.map