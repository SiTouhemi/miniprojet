import * as functions from 'firebase-functions';
/**
 * Set custom claims for user role
 */
export declare const setUserRole: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Create user with role (admin only)
 */
export declare const createUserWithRole: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Create reservation with atomic operations
 */
export declare const createReservation: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Generate QR token for confirmed reservation
 */
export declare const generateQRToken: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Validate QR token for staff
 */
export declare const validateQRCode: functions.HttpsFunction & functions.Runnable<any>;
/**
 * Set custom claims when user document is created
 */
export declare const onUserCreate: functions.CloudFunction<functions.firestore.QueryDocumentSnapshot>;
/**
 * Update custom claims when user role is updated
 */
export declare const onUserUpdate: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
//# sourceMappingURL=index.d.ts.map