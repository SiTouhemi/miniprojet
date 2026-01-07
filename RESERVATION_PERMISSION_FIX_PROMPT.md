# 🚨 CRITICAL: Fix Student Reservation Permission Error

## Problem Statement
Students cannot make meal reservations due to Firestore permission errors. The system shows two distinct errors:

1. **Firestore Index Error**: `[cloud_firestore/failed-precondition] The query requires an index`
2. **Permission Denied Error**: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

### Error Logs
```
❌ [13:47:56.185] ERROR: [ReservationService] Error checking existing meal reservation
└─ Error: [cloud_firestore/failed-precondition] The query requires an index

❌ [13:47:59.130] ERROR: [ReservationService] Error creating reservation
└─ Error: [cloud_firestore/permission-denied] Missing or insufficient permissions
```

### User Context
- **User**: Ahmed Zouari (student_ahmed_zouari)
- **Role**: student
- **Balance**: 35.75 DT
- **Action**: Attempting to make a meal reservation
- **Expected**: Reservation should be created, 0.20 TND deducted from wallet
- **Actual**: Permission denied error blocks the reservation

## System Architecture

### Database: Cloud Firestore
- **Project**: mafirstclienta
- **Collections**:
  - `user` - Student profiles with pocket money
  - `reservation` - Meal reservations
  - `time_slots` - Available meal time slots
  - `daily_reservation_counters` - Daily meal reservation limits
  - `payment_transactions` - Transaction logs

### Business Rules
1. **One reservation per meal type per day**: Max 1 lunch + 1 dinner per student per day
2. **Capacity validation**: Only allow reservation if time slot has available places
3. **Wallet deduction**: 0.20 TND deducted from student's pocket field
4. **Atomic operations**: Reservation + wallet deduction must be atomic

### Current Firestore Rules
```javascript
// Reservations - require authentication
match /reservation/{document} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isAuthenticated() && (isOwner(resource.data.userId) || getUserRole() in ['admin', 'staff']);
  allow delete: if isAuthenticated() && getUserRole() == 'admin';
}

// Daily reservation counters - for tracking daily meal limits
match /daily_reservation_counters/{document} {
  allow read, write: if isAuthenticated();
}

// Payment transactions - for wallet transaction logs  
match /payment_transactions/{document} {
  allow read, write: if isAuthenticated();
}
```

## Root Causes to Investigate

### 1. Firestore Index Missing
The query in `_checkExistingMealReservation()` requires a composite index:
```dart
.where('user_id', isEqualTo: userId)
.where('meal_type', isEqualTo: mealType)
.where('creneaux', isGreaterThanOrEqualTo: startOfDay)
.where('creneaux', isLessThan: endOfDay)
.where('status', whereIn: ['confirmed', 'pending'])
```

**Solution Options**:
- Option A: Create the composite index in Firebase Console
- Option B: Use simplified query-based approach (already implemented)
- Option C: Use counter-based validation (already implemented)

### 2. Permission Denied on Reservation Creation
Even after the index error is bypassed, permission denied occurs when creating the reservation.

**Possible Causes**:
- User document doesn't exist in Firestore
- User document has incorrect structure
- Firestore rules don't allow student role to create reservations
- Transaction is trying to access collections without proper permissions
- Custom claims (role) not properly set in Firebase Auth

### 3. Transaction Scope Issues
The reservation creation uses a Firestore transaction that accesses multiple collections:
```dart
// Accesses these collections in transaction:
- /user/{userId}
- /time_slots/{timeSlotId}
- /reservation/{newDocId}
- /payment_transactions/{newDocId}
```

Each collection access must have proper permissions.

## Files to Review/Modify

### 1. Firestore Rules (`firebase/firestore.rules`)
- Verify `reservation` collection allows student create
- Verify `user` collection allows student read/write to own document
- Verify `time_slots` collection allows student read
- Verify `payment_transactions` collection allows student create
- Check if role-based access is working correctly

### 2. Reservation Service (`lib/backend/services/reservation_service.dart`)
- Method: `createReservation()`
- Check: All Firestore references use correct collection paths
- Check: Transaction properly handles all collection accesses
- Check: Error handling and fallback mechanisms

### 3. Configuration (`lib/config/reservation_config.dart`)
- Current: `ValidationMethod.QUERY_BASED`
- Should be: `ValidationMethod.COUNTER_BASED` (after fixing permissions)

### 4. Daily Counter Service (`lib/backend/services/daily_reservation_counter_service.dart`)
- Verify permissions for `daily_reservation_counters` collection
- Check document ID format: `{userId}_{dateStr}`

## Step-by-Step Fix Process

### Step 1: Verify User Document Exists
- Check if user document exists in Firestore for `student_ahmed_zouari`
- Verify document has required fields: `pocket`, `role`, `uid`
- Verify user has `role: 'student'` in custom claims

### Step 2: Fix Firestore Rules
Update rules to explicitly allow students to:
- Read their own user document
- Create reservation documents
- Create payment_transaction documents
- Read time_slots

### Step 3: Create Composite Index (if needed)
If using query-based validation, create index:
- Collection: `reservation`
- Fields: `user_id` (Asc), `meal_type` (Asc), `creneaux` (Asc)

### Step 4: Test Reservation Flow
1. Login as student
2. Attempt to make reservation
3. Verify:
   - No index errors
   - No permission errors
   - Reservation created successfully
   - Wallet deducted correctly
   - Daily counter incremented

### Step 5: Switch to Counter-Based (Recommended)
After fixing permissions:
- Change `ValidationMethod.COUNTER_BASED` in config
- Deploy and test
- Monitor for any issues

## Expected Behavior After Fix

### Success Scenario
```
1. Student logs in ✅
2. Selects time slot ✅
3. Confirms reservation ✅
4. System checks:
   - User has sufficient balance ✅
   - Time slot has available capacity ✅
   - Student hasn't already reserved this meal type today ✅
5. Reservation created ✅
6. Wallet deducted 0.20 TND ✅
7. Success message shown ✅
```

### Error Scenarios
```
- Insufficient balance → Show error message
- Slot full → Show error message
- Already reserved this meal → Show error message
- Permission denied → FIX THIS
- Index missing → FIX THIS
```

## Testing Credentials

### Student Account
```
Email: ahmed.zouari@etudiant.isetcom.tn
Password: Test123!
UID: student_ahmed_zouari
Role: student
Pocket: 35.75 DT
```

### Admin Account (for verification)
```
Email: karim.khelifi@isetcom.tn
Password: Test123!
UID: admin_karim_khelifi
Role: admin
```

## Debugging Commands

### Check Firestore Rules Compilation
```bash
firebase deploy --only firestore:rules --dry-run
```

### View Firestore Indexes
```bash
firebase firestore:indexes
```

### Export Users to Check Custom Claims
```bash
firebase auth:export users.json --project mafirstclienta
```

### Check Firestore Console
1. Go to: https://console.firebase.google.com/project/mafirstclienta/firestore
2. Check Collections:
   - `user` → Verify student document exists
   - `reservation` → Check if any reservations exist
   - `daily_reservation_counters` → Check structure
3. Check Indexes:
   - Look for composite indexes on `reservation` collection
4. Check Rules:
   - Verify rules are deployed correctly

## Success Criteria

- ✅ Student can create reservation without permission errors
- ✅ Reservation is created in Firestore
- ✅ Wallet is deducted correctly (0.20 TND)
- ✅ Daily counter is incremented
- ✅ Capacity validation works (no overbooking)
- ✅ Error messages are user-friendly (in French)
- ✅ No Firestore index errors
- ✅ No permission denied errors

## Additional Notes

### Current Implementation Status
- ✅ Counter-based validation implemented
- ✅ Query-based validation implemented with fallback
- ✅ Capacity validation added
- ✅ Atomic transactions implemented
- ✅ Error handling with fallback mechanisms
- ❌ Permission errors still blocking students
- ❌ Index errors still occurring

### Known Issues
1. Firestore rules might not properly recognize student role
2. User document might not exist or have wrong structure
3. Transaction might be accessing collections without proper permissions
4. Custom claims might not be properly set in Firebase Auth

### Recommendations
1. Verify all user documents exist in Firestore
2. Verify custom claims are properly set in Firebase Auth
3. Test Firestore rules with specific user UID
4. Use Firebase Console to manually test permissions
5. Check Firebase logs for detailed error information

---

**Priority**: 🚨 CRITICAL - Blocking all student reservations
**Status**: ❌ NOT WORKING - Permission errors
**Next Step**: Fix Firestore permissions and verify user documents