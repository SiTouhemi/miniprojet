# Payment System Fix - Wallet Deduction for Reservations

## Problem
The reservation system was using **direct D17 payment** instead of **deducting from student's wallet/pocket** when students reserve time slots (creneaux). This caused confusion as students expected the 0.2 TND to be deducted from their existing wallet balance.

## Root Causes Identified

1. **Wrong Payment Method**: `ReservationService.createReservation()` was calling D17 payment service
2. **Price Inconsistency**: Hardcoded 0.2 TND vs configured 5.0 TND in app settings
3. **Missing Atomic Transactions**: No transaction safety for wallet deductions
4. **Incomplete Payment Flow**: No wallet deduction logging

## Changes Made

### 1. Updated ReservationService (`lib/backend/services/reservation_service.dart`)

**Before:**
```dart
// Called D17 payment service
final result = await makeCloudCall('createReservation', {
  'timeSlotId': timeSlotId,
  'capacity': capacity,
  'amount': amount ?? 0.2, // Hardcoded price
});
```

**After:**
```dart
// Uses wallet deduction with atomic transactions
return await FirebaseFirestore.instance.runTransaction((transaction) async {
  // Validate balance
  // Deduct from user.pocket using FieldValue.increment(-amount)
  // Create reservation with payment_method: 'wallet'
  // Log transaction for audit
});
```

### 2. Updated ReservationcreneauModel (`lib/student/reservationcreneau/reservationcreneau_model.dart`)

**Before:**
```dart
// Processed D17 payment first
final paymentResult = await PaymentService.instance.processD17Payment(
  userId: userId,
  amount: amount,
  description: 'Restaurant reservation',
);
```

**After:**
```dart
// Direct reservation creation with wallet deduction
final reservationResult = await _reservationService.createReservation(
  userId: userId,
  timeSlotId: timeSlotId,
  mealType: selectedTimeSlot!.mealType,
  amount: amount,
  capacity: 1,
);
```

### 3. Enhanced PaymentService (`lib/backend/services/payment_service.dart`)

- Added atomic transaction support for `deductFromBalance()`
- Improved error handling and balance validation
- Added transaction logging for audit trails

### 4. Fixed Price Configuration (`lib/backend/services/time_slot_service.dart`)

**Before:**
```dart
'price': 0.2, // Hardcoded
```

**After:**
```dart
final appSettings = await AppService.instance.getAppSettings();
final mealPrice = appSettings.defaultMealPrice; // Uses configured price
'price': mealPrice,
```

## Key Features Added

### ✅ Atomic Transactions
- All wallet deductions use Firestore transactions
- Prevents race conditions and double-spending
- Ensures data consistency

### ✅ Balance Validation
- Pre-validation before attempting deduction
- Clear error messages for insufficient funds
- Real-time balance checking

### ✅ Transaction Logging
- All payments logged in `payment_transactions` collection
- Includes before/after balance for audit
- Transaction type and description tracking

### ✅ Proper Error Handling
- Specific error codes (INSUFFICIENT_FUNDS, USER_NOT_FOUND)
- User-friendly error messages
- Graceful failure handling

## Payment Flow Now

1. **Student selects time slot** → System shows current wallet balance
2. **Validation** → Check if wallet balance ≥ meal price
3. **Atomic Deduction** → Use Firestore transaction to deduct from `user.pocket`
4. **Reservation Creation** → Create reservation with `payment_method: 'wallet'`
5. **Transaction Log** → Record deduction in `payment_transactions`
6. **Success Message** → Show new balance to student

## Configuration

The meal price is now properly configured in:
- **App Settings**: `defaultMealPrice: 5.0` (configurable)
- **Fallback**: `0.2` TND if settings not available

## Testing

Created test file `test_wallet_deduction.dart` to verify:
- ✅ Sufficient balance scenarios
- ❌ Insufficient balance scenarios  
- 🔄 Atomic transaction behavior

## Benefits

1. **Consistent Payment Method**: All reservations use wallet deduction
2. **Better User Experience**: Clear balance display and deduction messages
3. **Data Integrity**: Atomic transactions prevent corruption
4. **Audit Trail**: Complete transaction logging
5. **Configurable Pricing**: Uses app settings instead of hardcoded values

## Next Steps

1. Test the changes in development environment
2. Verify wallet top-up flow still works correctly
3. Update any remaining hardcoded 0.2 prices in other files
4. Consider adding balance alerts when wallet is low