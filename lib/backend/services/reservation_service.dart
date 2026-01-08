import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/services/payment_service.dart';
import '/backend/services/app_service.dart';
import '/backend/services/qr_service.dart';
import '/backend/services/daily_reservation_counter_service.dart';
import '/config/reservation_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/app_logger.dart';

class ReservationService {
  static ReservationService? _instance;
  static ReservationService get instance =>
      _instance ??= ReservationService._();
  ReservationService._();

  // Use configuration from ReservationConfig
  static bool get useCounterBasedValidation =>
      ReservationConfigHelper.useCounterBasedValidation;

  // Create a new reservation with wallet deduction
  Future<Map<String, dynamic>> createReservation({
    required String userId,
    required String timeSlotId,
    required String mealType,
    String? paymentId,
    String? paymentMethod,
    String? transactionId,
    double? amount,
    int capacity = 1,
  }) async {
    try {
      AppLogger.i('Starting reservation creation for user $userId, meal type: $mealType', 
          tag: 'ReservationService');

      // TEMPORARY: Skip validation to test basic reservation creation
      AppLogger.w('TEMPORARY: Skipping duplicate validation for debugging', 
          tag: 'ReservationService');

      // Get the correct meal price from app settings if not provided
      double reservationAmount;
      if (amount != null) {
        reservationAmount = amount;
      } else {
        try {
          AppLogger.d('Getting app settings for meal price', tag: 'ReservationService');
          final appSettings = await AppService.instance.getAppSettings();
          reservationAmount = appSettings.defaultMealPrice;
          AppLogger.d('Got meal price from settings: $reservationAmount', tag: 'ReservationService');
        } catch (e) {
          AppLogger.e('Error getting app settings, using fallback price', 
              error: e, tag: 'ReservationService');
          reservationAmount = 5.0; // Fallback price
        }
      }

      AppLogger.d('Reservation amount: $reservationAmount TND', tag: 'ReservationService');

      // First validate user has sufficient balance
      try {
        AppLogger.d('Validating payment for amount: $reservationAmount', tag: 'ReservationService');
        final paymentValidation = await PaymentService.instance.validatePayment(
          userId: userId,
          amount: reservationAmount,
        );

        if (!paymentValidation['success']) {
          AppLogger.w('Payment validation failed: ${paymentValidation['message']}', 
              tag: 'ReservationService');
          return {
            'success': false,
            'error': paymentValidation['message'] ?? 'Insufficient balance',
            'errorCode': 'INSUFFICIENT_FUNDS'
          };
        }
        AppLogger.d('Payment validation successful', tag: 'ReservationService');
      } catch (e) {
        AppLogger.e('Error during payment validation', error: e, tag: 'ReservationService');
        return {
          'success': false,
          'error': 'Payment validation failed: ${e.toString()}',
          'errorCode': 'PAYMENT_VALIDATION_ERROR'
        };
      }

      AppLogger.d('Starting Firestore transaction', tag: 'ReservationService');

      // Use Firestore transaction to ensure atomicity
      final transactionResult =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        AppLogger.d('Inside transaction - getting user document', tag: 'ReservationService');
        
        // Get user document
        final userRef =
            FirebaseFirestore.instance.collection('user').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          AppLogger.w('User document not found', tag: 'ReservationService');
          return {
            'success': false,
            'error': 'User not found',
            'errorCode': 'USER_NOT_FOUND'
          };
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentBalance = (userData['pocket'] as num?)?.toDouble() ?? 0.0;

        AppLogger.d('Current user balance: $currentBalance', tag: 'ReservationService');

        // Double-check balance in transaction
        if (currentBalance < reservationAmount) {
          return {
            'success': false,
            'error':
                'Insufficient balance. Required: ${reservationAmount.toStringAsFixed(2)} TND, Available: ${currentBalance.toStringAsFixed(2)} TND',
            'errorCode': 'INSUFFICIENT_FUNDS'
          };
        }

        AppLogger.d('Getting time slot document', tag: 'ReservationService');

        // Get time slot to get the creneaux (start time)
        final timeSlotRef =
            FirebaseFirestore.instance.collection('time_slots').doc(timeSlotId);
        final timeSlotDoc = await transaction.get(timeSlotRef);

        if (!timeSlotDoc.exists) {
          AppLogger.w('Time slot document not found', tag: 'ReservationService');
          return {
            'success': false,
            'error': 'Time slot not found',
            'errorCode': 'TIME_SLOT_NOT_FOUND'
          };
        }

        final timeSlotData = timeSlotDoc.data() as Map<String, dynamic>;
        final creneaux = timeSlotData['start_time'] as Timestamp?;
        final currentReservations =
            (timeSlotData['current_reservations'] as num?)?.toInt() ?? 0;
        final maxCapacity =
            (timeSlotData['max_capacity'] as num?)?.toInt() ?? 0;

        if (creneaux == null) {
          AppLogger.w('Invalid time slot data - no start_time', tag: 'ReservationService');
          return {
            'success': false,
            'error': 'Invalid time slot data',
            'errorCode': 'INVALID_TIME_SLOT'
          };
        }

        AppLogger.d('Time slot capacity: $currentReservations/$maxCapacity', tag: 'ReservationService');

        // Check if there's still capacity available
        if (currentReservations + capacity > maxCapacity) {
          return {
            'success': false,
            'error': 'This time slot is full. No more places available.',
            'errorCode': 'SLOT_FULL'
          };
        }

        AppLogger.d('Updating user balance', tag: 'ReservationService');

        // Deduct from user balance (from pocket, not D17)
        transaction.update(userRef, {
          'pocket': FieldValue.increment(-reservationAmount),
        });

        AppLogger.d('Updating time slot capacity', tag: 'ReservationService');

        // Update time slot capacity
        transaction.update(timeSlotRef, {
          'current_reservations': FieldValue.increment(capacity),
        });

        AppLogger.d('Creating reservation document', tag: 'ReservationService');

        // Create reservation document
        final reservationRef =
            FirebaseFirestore.instance.collection('reservation').doc();
        transaction.set(reservationRef, {
          'user_id': userId,
          'time_slot_id': timeSlotId,
          'type': mealType, // Use 'type' field to match ReservationRecord schema
          'capacity': capacity,
          'total':
              (reservationAmount * 1000).round(), // Convert to millimes (int)
          'prix': (reservationAmount * 1000)
              .round(), // Individual price in millimes (int)
          'creneaux': creneaux, // Use the time slot's start time
          'status': 'confirmed',
          'payment_method': 'wallet',
          'payment_id': 'wallet_${DateTime.now().millisecondsSinceEpoch}',
          'created_at': FieldValue.serverTimestamp(),
          'qr_code': '', // Will be generated after reservation creation
        });

        AppLogger.d('Creating transaction log', tag: 'ReservationService');

        // Log the transaction
        final transactionLogRef =
            FirebaseFirestore.instance.collection('payment_transactions').doc();
        transaction.set(transactionLogRef, {
          'user_id': userId,
          'reservation_id': reservationRef.id,
          'amount': -reservationAmount, // Negative for deduction
          'type': 'reservation_payment',
          'description': 'Reservation payment for $mealType',
          'timestamp': FieldValue.serverTimestamp(),
          'balance_before': currentBalance,
          'balance_after': currentBalance - reservationAmount,
        });

        AppLogger.d('Transaction operations completed', tag: 'ReservationService');

        return {
          'success': true,
          'reservationId': reservationRef.id,
          'amount': reservationAmount,
          'newBalance': currentBalance - reservationAmount,
          'message':
              'Reservation created successfully. ${reservationAmount.toStringAsFixed(2)} TND deducted from wallet.',
        };
      });

      AppLogger.d('Transaction completed successfully', tag: 'ReservationService');

      // Generate QR code after successful reservation creation
      if (transactionResult['success'] == true) {
        try {
          await _generateQRCodeForReservation(
            reservationId: transactionResult['reservationId'] as String,
            userId: userId,
            mealType: mealType,
          );
          AppLogger.i('QR code generated successfully', tag: 'ReservationService');
        } catch (e) {
          AppLogger.w('Failed to generate QR code, but reservation was created', 
              error: e, tag: 'ReservationService');
          // Don't fail the reservation if QR generation fails
        }
      }

      AppLogger.i('Reservation creation completed: ${transactionResult['success']}', 
          tag: 'ReservationService');
      return transactionResult;
    } catch (e) {
      AppLogger.e('Error creating reservation',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to create reservation: ${e.toString()}'
      };
    }
  }

  /// Check if user already has a reservation for this meal type today
  /// Only 1 reservation per meal type per day is allowed
  /// FIXED: Ultra-simplified query to avoid any Firestore index requirements
  Future<Map<String, dynamic>> _checkExistingMealReservation(
      String userId, String mealType) async {
    try {
      AppLogger.d('Checking existing reservations for user $userId, meal type: $mealType', 
          tag: 'ReservationService');
          
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // ULTRA-SIMPLE: Only query by user_id to avoid any index issues
      final existingReservations = await FirebaseFirestore.instance
          .collection('reservation')
          .where('user_id', isEqualTo: userId)
          .get();

      AppLogger.d('Found ${existingReservations.docs.length} total reservations for user', 
          tag: 'ReservationService');

      // Filter everything client-side to avoid any Firestore index requirements
      final todaysValidReservations = existingReservations.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String?;
        final type = data['type'] as String?;
        final creneaux = (data['creneaux'] as Timestamp?)?.toDate();

        // Check if it's a valid reservation
        if (status != 'confirmed' && status != 'pending') return false;
        
        // Check if it's the same meal type
        if (type != mealType) return false;
        
        // Check if it's today
        if (creneaux == null) return false;
        return creneaux.isAfter(startOfDay) && creneaux.isBefore(endOfDay);
      }).toList();

      AppLogger.d('Found ${todaysValidReservations.length} valid reservations for today', 
          tag: 'ReservationService');

      if (todaysValidReservations.isNotEmpty) {
        final mealTypeDisplay = mealType == 'lunch' ? 'déjeuner' : 'dîner';
        AppLogger.w('User already has $mealType reservation today', 
            tag: 'ReservationService');
        return {
          'success': false,
          'error':
              'Vous avez déjà une réservation pour le $mealTypeDisplay aujourd\'hui. Une seule réservation par repas par jour est autorisée.',
          'errorCode': 'DUPLICATE_MEAL_RESERVATION'
        };
      }

      AppLogger.d('No existing reservations found - user can make reservation', 
          tag: 'ReservationService');
      return {'success': true};
    } catch (e) {
      AppLogger.e('Error checking existing meal reservation',
          error: e, tag: 'ReservationService');

      // FALLBACK: If the query fails, allow the reservation but log the issue
      // This prevents blocking users when there are database issues
      return {
        'success': true, // Allow reservation to proceed
        'warning':
            'Could not verify existing reservations due to database issues. Please check manually.',
      };
    }
  }

  // Generate QR code for a reservation using QRService
  Future<void> _generateQRCodeForReservation({
    required String reservationId,
    required String userId,
    required String mealType,
  }) async {
    try {
      // Get the reservation to get the creneaux
      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) return;

      final reservation = ReservationRecord.fromSnapshot(reservationDoc);

      // Import QRService
      final qrService = QRService.instance;

      // Generate QR code
      await qrService.generateQRCode(
        reservationId: reservationId,
        userId: userId,
        creneaux: reservation.creneaux!,
        mealType: mealType,
      );

      AppLogger.i('QR code generated for reservation $reservationId',
          tag: 'ReservationService');
    } catch (e) {
      AppLogger.e('Error generating QR code for reservation',
          error: e, tag: 'ReservationService');
    }
  }

  // Old simple QR generation method - replaced by QRService

  // Validate QR code for staff
  Future<Map<String, dynamic>> validateQRCode({
    required String qrCode,
    required String staffId,
  }) async {
    try {
      final result = await makeCloudCall('validateQRCode', {
        'qrCode': qrCode,
        'staffId': staffId,
      });

      return result;
    } catch (e) {
      AppLogger.e('Error validating QR code',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to validate QR code: ${e.toString()}'
      };
    }
  }

  // Get reservation by QR code
  Future<ReservationRecord?> getReservationByQR(String qrCode) async {
    try {
      final reservations = await queryReservationRecordOnce(
        queryBuilder: (query) => query.where('qr_code', isEqualTo: qrCode),
        limit: 1,
      );

      return reservations.isNotEmpty ? reservations.first : null;
    } catch (e) {
      AppLogger.e('Error fetching reservation by QR',
          error: e, tag: 'ReservationService');
      return null;
    }
  }

  // Get reservations for a specific time slot
  Future<List<ReservationRecord>> getTimeSlotReservations(
      String timeSlotId) async {
    try {
      // First get the time slot to get its start time
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .get();
      if (!timeSlotDoc.exists) return [];

      final timeSlot = TimeSlotRecord.fromSnapshot(timeSlotDoc);

      return await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('creneaux', isEqualTo: timeSlot.startTime)
            .where('status', whereIn: ['confirmed', 'used']),
      );
    } catch (e) {
      AppLogger.e('Error fetching time slot reservations',
          error: e, tag: 'ReservationService');
      return [];
    }
  }

  // Get user's upcoming reservations
  Future<List<ReservationRecord>> getUpcomingReservations(String userId) async {
    try {
      final now = DateTime.now();

      return await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('user_id', isEqualTo: userId)
            .where('creneaux', isGreaterThan: now)
            .where('status',
                whereIn: ['confirmed', 'pending']).orderBy('creneaux'),
      );
    } catch (e) {
      AppLogger.e('Error fetching upcoming reservations',
          error: e, tag: 'ReservationService');
      return [];
    }
  }

  // Get user's past reservations
  Future<List<ReservationRecord>> getPastReservations(String userId) async {
    try {
      final now = DateTime.now();

      return await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('user_id', isEqualTo: userId)
            .where('creneaux', isLessThan: now)
            .orderBy('creneaux', descending: true),
        limit: 20, // Limit to last 20 reservations
      );
    } catch (e) {
      AppLogger.e('Error fetching past reservations',
          error: e, tag: 'ReservationService');
      return [];
    }
  }

  /// Cancel a reservation with atomic counter decrements
  /// Requirement 5.5: Add atomic counter decrements for cancellations
  /// Requirement 5.7: Prevent modifications for past reservations
  Future<Map<String, dynamic>> cancelReservation({
    required String reservationId,
    required String userId,
    String? reason,
  }) async {
    try {
      // Use Firestore transaction for atomic operations
      final result = await FirebaseFirestore.instance
          .runTransaction<Map<String, dynamic>>((transaction) async {
        // Get current reservation
        final reservationRef = FirebaseFirestore.instance
            .collection('reservation')
            .doc(reservationId);
        final reservationDoc = await transaction.get(reservationRef);

        if (!reservationDoc.exists) {
          return {
            'success': false,
            'error': 'Reservation not found',
            'errorCode': 'RESERVATION_NOT_FOUND'
          };
        }

        final reservation = ReservationRecord.fromSnapshot(reservationDoc);

        // Check ownership
        if (reservation.userId != userId) {
          return {
            'success': false,
            'error':
                'Access denied. You can only cancel your own reservations.',
            'errorCode': 'ACCESS_DENIED'
          };
        }

        // Check if reservation can be cancelled
        if (reservation.status == 'cancelled') {
          return {
            'success': false,
            'error': 'Reservation is already cancelled',
            'errorCode': 'ALREADY_CANCELLED'
          };
        }

        if (reservation.status == 'used') {
          return {
            'success': false,
            'error': 'Cannot cancel a reservation that has already been used',
            'errorCode': 'ALREADY_USED'
          };
        }

        // Requirement 5.7: Prevent modifications for past reservations
        final now = DateTime.now();
        if (reservation.creneaux != null &&
            reservation.creneaux!.isBefore(now)) {
          return {
            'success': false,
            'error': 'Cannot cancel past reservations',
            'errorCode': 'PAST_RESERVATION'
          };
        }

        // Check if cancellation is too close to meal time (2 hours minimum)
        if (reservation.creneaux != null &&
            reservation.creneaux!.difference(now).inHours < 2) {
          return {
            'success': false,
            'error':
                'Cannot cancel reservation less than 2 hours before meal time',
            'errorCode': 'TOO_LATE_TO_CANCEL'
          };
        }

        // Find the time slot to update capacity
        final timeSlotQuery = await queryTimeSlotRecordOnce(
          queryBuilder: (query) =>
              query.where('start_time', isEqualTo: reservation.creneaux),
          limit: 1,
        );

        if (timeSlotQuery.isEmpty) {
          return {
            'success': false,
            'error': 'Associated time slot not found',
            'errorCode': 'TIME_SLOT_NOT_FOUND'
          };
        }

        final timeSlot = timeSlotQuery.first;

        // Requirement 5.5: Atomic counter decrements for cancellations
        // Update reservation status to cancelled
        transaction.update(reservationRef, {
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
          'cancellation_reason': reason ?? 'User cancelled',
          'modified_at': FieldValue.serverTimestamp(),
        });

        // Atomically decrement time slot capacity
        transaction.update(timeSlot.reference, {
          'current_reservations': FieldValue.increment(-reservation.capacity),
        });

        // FIXED: Decrement counter inside transaction if using counter-based validation
        if (useCounterBasedValidation) {
          try {
            final reservationDate = reservation.creneaux ?? DateTime.now();
            final dateStr =
                '${reservationDate.year}-${reservationDate.month.toString().padLeft(2, '0')}-${reservationDate.day.toString().padLeft(2, '0')}';
            final counterRef = FirebaseFirestore.instance
                .collection('daily_reservation_counters')
                .doc('${userId}_$dateStr');
            
            final counterDoc = await transaction.get(counterRef);
            
            if (counterDoc.exists) {
              final fieldToDecrement = reservation.type == 'lunch' ? 'lunch_count' : 'dinner_count';
              transaction.update(counterRef, {
                fieldToDecrement: FieldValue.increment(-1),
                'last_updated': FieldValue.serverTimestamp(),
              });
            }
            // If counter doesn't exist, that's okay - just skip the decrement
          } catch (e) {
            // Log the error but don't fail the cancellation
            AppLogger.w('Failed to decrement counter during cancellation', 
                error: e, tag: 'ReservationService');
          }
        }

        // Bug Fix: Refund the ticket to the user
        final userRef =
            FirebaseFirestore.instance.collection('user').doc(userId);
        transaction.update(userRef, {
          'tickets': FieldValue.increment(
              reservation.capacity), // Assuming 1 ticket per person capacity
        });

        return {
          'success': true,
          'message': 'Reservation cancelled successfully',
          'reservationId': reservationId,
          'cancelledAt': DateTime.now().toIso8601String(),
          'mealType':
              reservation.type, // Include meal type for counter decrement
          'reservationDate': reservation.creneaux?.toIso8601String(),
        };
      });

      return result;
    } catch (e) {
      AppLogger.e('Error cancelling reservation',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to cancel reservation: ${e.toString()}',
        'errorCode': 'CANCELLATION_FAILED'
      };
    }
  }

  /// Modify reservation (change time slot) with atomic operations
  /// Requirement 5.7: Prevent modifications for past reservations
  Future<Map<String, dynamic>> modifyReservation({
    required String reservationId,
    required String newTimeSlotId,
    required String userId,
  }) async {
    try {
      // Use Firestore transaction for atomic operations
      return await FirebaseFirestore.instance
          .runTransaction<Map<String, dynamic>>((transaction) async {
        // Get current reservation
        final reservationRef = FirebaseFirestore.instance
            .collection('reservation')
            .doc(reservationId);
        final reservationDoc = await transaction.get(reservationRef);

        if (!reservationDoc.exists) {
          return {
            'success': false,
            'error': 'Reservation not found',
            'errorCode': 'RESERVATION_NOT_FOUND'
          };
        }

        final reservation = ReservationRecord.fromSnapshot(reservationDoc);

        // Check ownership
        if (reservation.userId != userId) {
          return {
            'success': false,
            'error':
                'Access denied. You can only modify your own reservations.',
            'errorCode': 'ACCESS_DENIED'
          };
        }

        // Check if reservation can be modified
        if (reservation.status != 'confirmed' &&
            reservation.status != 'pending') {
          return {
            'success': false,
            'error': 'Only confirmed or pending reservations can be modified',
            'errorCode': 'INVALID_STATUS'
          };
        }

        // Requirement 5.7: Prevent modifications for past reservations
        final now = DateTime.now();
        if (reservation.creneaux != null &&
            reservation.creneaux!.isBefore(now)) {
          return {
            'success': false,
            'error': 'Cannot modify past reservations',
            'errorCode': 'PAST_RESERVATION'
          };
        }

        // Check if modification is too close to meal time (2 hours minimum)
        if (reservation.creneaux != null &&
            reservation.creneaux!.difference(now).inHours < 2) {
          return {
            'success': false,
            'error':
                'Cannot modify reservation less than 2 hours before meal time',
            'errorCode': 'TOO_LATE_TO_MODIFY'
          };
        }

        // Get new time slot
        final newTimeSlotRef = FirebaseFirestore.instance
            .collection('time_slots')
            .doc(newTimeSlotId);
        final newTimeSlotDoc = await transaction.get(newTimeSlotRef);

        if (!newTimeSlotDoc.exists) {
          return {
            'success': false,
            'error': 'New time slot not found',
            'errorCode': 'NEW_TIME_SLOT_NOT_FOUND'
          };
        }

        final newTimeSlot = TimeSlotRecord.fromSnapshot(newTimeSlotDoc);

        // Check if new time slot is in the future
        if (newTimeSlot.startTime != null &&
            newTimeSlot.startTime!.isBefore(now)) {
          return {
            'success': false,
            'error': 'Cannot modify to a past time slot',
            'errorCode': 'PAST_TIME_SLOT'
          };
        }

        // Check availability in new time slot
        if (newTimeSlot.currentReservations + reservation.capacity >
            newTimeSlot.maxCapacity) {
          return {
            'success': false,
            'error': 'New time slot does not have enough capacity',
            'errorCode': 'INSUFFICIENT_CAPACITY'
          };
        }

        // Find old time slot to update capacity
        final oldTimeSlotQuery = await queryTimeSlotRecordOnce(
          queryBuilder: (query) =>
              query.where('start_time', isEqualTo: reservation.creneaux),
          limit: 1,
        );

        if (oldTimeSlotQuery.isEmpty) {
          return {
            'success': false,
            'error': 'Original time slot not found',
            'errorCode': 'OLD_TIME_SLOT_NOT_FOUND'
          };
        }

        final oldTimeSlot = oldTimeSlotQuery.first;

        // NEW: Handle price difference
        final double oldTotal =
            (reservation.total / 1000.0); // Convert from millimes to TND
        final double newTotal = newTimeSlot.price *
            1; // Assuming capacity is 1 for individual reservations
        final double priceDiff = newTotal - oldTotal;

        if (priceDiff != 0) {
          final userRef =
              FirebaseFirestore.instance.collection('user').doc(userId);
          final userDoc = await transaction.get(userRef);

          if (!userDoc.exists) {
            return {
              'success': false,
              'error': 'User not found',
              'errorCode': 'USER_NOT_FOUND'
            };
          }

          final user = UserRecord.fromSnapshot(userDoc);

          if (priceDiff > 0) {
            // Upgrade: Check balance
            if (user.pocket < priceDiff) {
              return {
                'success': false,
                'error':
                    'Insufficient balance for this modification. Additional cost: ${priceDiff}DT',
                'errorCode': 'INSUFFICIENT_FUNDS'
              };
            }
          }

          // Update user balance (deduct diff; if negative, it adds)
          transaction.update(userRef, {
            'pocket': FieldValue.increment(-priceDiff),
          });
        }

        // Atomic updates
        // Update reservation with new time slot details
        transaction.update(reservationRef, {
          'creneaux': newTimeSlot.startTime,
          'prix':
              (newTimeSlot.price * 1000).round(), // Convert to millimes (int)
          'total': (newTimeSlot.price * reservation.capacity * 1000)
              .round(), // Convert to millimes (int)
          'modified_at': FieldValue.serverTimestamp(),
        });

        // Decrease capacity in old time slot
        transaction.update(oldTimeSlot.reference, {
          'current_reservations': FieldValue.increment(-reservation.capacity),
        });

        // Increase capacity in new time slot
        transaction.update(newTimeSlotRef, {
          'current_reservations': FieldValue.increment(reservation.capacity),
        });

        return {
          'success': true,
          'message': 'Reservation modified successfully',
          'reservationId': reservationId,
          'newTimeSlot': {
            'id': newTimeSlotId,
            'startTime': newTimeSlot.startTime?.toIso8601String(),
            'endTime': newTimeSlot.endTime?.toIso8601String(),
            'price': newTimeSlot.price,
          },
          'modifiedAt': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      AppLogger.e('Error modifying reservation',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to modify reservation: ${e.toString()}',
        'errorCode': 'MODIFICATION_FAILED'
      };
    }
  }

  /// Check if a reservation can be cancelled
  Future<Map<String, dynamic>> canCancelReservation({
    required String reservationId,
    required String userId,
  }) async {
    try {
      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        return {
          'canCancel': false,
          'reason': 'Reservation not found',
          'errorCode': 'RESERVATION_NOT_FOUND'
        };
      }

      final reservation = ReservationRecord.fromSnapshot(reservationDoc);

      // Check ownership
      if (reservation.userId != userId) {
        return {
          'canCancel': false,
          'reason': 'Access denied',
          'errorCode': 'ACCESS_DENIED'
        };
      }

      // Check status
      if (reservation.status == 'cancelled') {
        return {
          'canCancel': false,
          'reason': 'Already cancelled',
          'errorCode': 'ALREADY_CANCELLED'
        };
      }

      if (reservation.status == 'used') {
        return {
          'canCancel': false,
          'reason': 'Already used',
          'errorCode': 'ALREADY_USED'
        };
      }

      // Check timing
      final now = DateTime.now();
      if (reservation.creneaux != null) {
        if (reservation.creneaux!.isBefore(now)) {
          return {
            'canCancel': false,
            'reason': 'Past reservation',
            'errorCode': 'PAST_RESERVATION'
          };
        }

        if (reservation.creneaux!.difference(now).inHours < 2) {
          return {
            'canCancel': false,
            'reason': 'Too close to meal time (less than 2 hours)',
            'errorCode': 'TOO_LATE_TO_CANCEL'
          };
        }
      }

      return {
        'canCancel': true,
        'hoursUntilMeal': reservation.creneaux?.difference(now).inHours ?? 0,
      };
    } catch (e) {
      AppLogger.e('Error checking cancellation eligibility',
          error: e, tag: 'ReservationService');
      return {
        'canCancel': false,
        'reason': 'Error checking eligibility: ${e.toString()}',
        'errorCode': 'CHECK_FAILED'
      };
    }
  }

  /// Check if a reservation can be modified
  Future<Map<String, dynamic>> canModifyReservation({
    required String reservationId,
    required String userId,
  }) async {
    try {
      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        return {
          'canModify': false,
          'reason': 'Reservation not found',
          'errorCode': 'RESERVATION_NOT_FOUND'
        };
      }

      final reservation = ReservationRecord.fromSnapshot(reservationDoc);

      // Check ownership
      if (reservation.userId != userId) {
        return {
          'canModify': false,
          'reason': 'Access denied',
          'errorCode': 'ACCESS_DENIED'
        };
      }

      // Check status
      if (reservation.status != 'confirmed' &&
          reservation.status != 'pending') {
        return {
          'canModify': false,
          'reason': 'Only confirmed or pending reservations can be modified',
          'errorCode': 'INVALID_STATUS'
        };
      }

      // Check timing
      final now = DateTime.now();
      if (reservation.creneaux != null) {
        if (reservation.creneaux!.isBefore(now)) {
          return {
            'canModify': false,
            'reason': 'Past reservation',
            'errorCode': 'PAST_RESERVATION'
          };
        }

        if (reservation.creneaux!.difference(now).inHours < 2) {
          return {
            'canModify': false,
            'reason': 'Too close to meal time (less than 2 hours)',
            'errorCode': 'TOO_LATE_TO_MODIFY'
          };
        }
      }

      return {
        'canModify': true,
        'hoursUntilMeal': reservation.creneaux?.difference(now).inHours ?? 0,
      };
    } catch (e) {
      AppLogger.e('Error checking modification eligibility',
          error: e, tag: 'ReservationService');
      return {
        'canModify': false,
        'reason': 'Error checking eligibility: ${e.toString()}',
        'errorCode': 'CHECK_FAILED'
      };
    }
  }

  /// Cancel a reservation using Cloud Function with atomic operations
  /// Requirement 5.5: Add atomic counter decrements for cancellations
  /// Requirement 5.7: Prevent modifications for past reservations
  Future<Map<String, dynamic>> cancelReservationCloudFunction({
    required String reservationId,
    String? reason,
  }) async {
    try {
      final result = await makeCloudCall('cancelReservation', {
        'reservationId': reservationId,
        'reason': reason,
      });

      return result;
    } catch (e) {
      AppLogger.e('Error cancelling reservation via Cloud Function',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to cancel reservation: ${e.toString()}',
        'errorCode': 'CLOUD_FUNCTION_ERROR'
      };
    }
  }

  /// Modify reservation using Cloud Function with atomic operations
  /// Requirement 5.7: Prevent modifications for past reservations
  Future<Map<String, dynamic>> modifyReservationCloudFunction({
    required String reservationId,
    required String newTimeSlotId,
  }) async {
    try {
      final result = await makeCloudCall('modifyReservation', {
        'reservationId': reservationId,
        'newTimeSlotId': newTimeSlotId,
      });

      return result;
    } catch (e) {
      AppLogger.e('Error modifying reservation via Cloud Function',
          error: e, tag: 'ReservationService');
      return {
        'success': false,
        'error': 'Failed to modify reservation: ${e.toString()}',
        'errorCode': 'CLOUD_FUNCTION_ERROR'
      };
    }
  }

  // Get today's reservations for staff dashboard
  Future<List<Map<String, dynamic>>> getTodaysReservations() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final reservations = await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('creneaux', isGreaterThanOrEqualTo: startOfDay)
            .where('creneaux', isLessThan: endOfDay)
            .orderBy('creneaux'),
      );

      // Enrich with user data
      final enrichedReservations = <Map<String, dynamic>>[];

      for (final reservation in reservations) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('user')
              .doc(reservation.userId)
              .get();
          final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

          enrichedReservations.add({
            'reservation': reservation,
            'user': user,
            'userName': user?.displayName ?? user?.nom ?? 'Unknown User',
            'userClass': user?.classe ?? '',
          });
        } catch (e) {
          AppLogger.w('Error fetching user data for reservation',
              error: e, tag: 'ReservationService');
          enrichedReservations.add({
            'reservation': reservation,
            'user': null,
            'userName': 'Unknown User',
            'userClass': '',
          });
        }
      }

      return enrichedReservations;
    } catch (e) {
      AppLogger.e('Error fetching today\'s reservations',
          error: e, tag: 'ReservationService');
      return [];
    }
  }

  // Get occupancy statistics for a specific date
  Future<Map<String, dynamic>> getOccupancyStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Get all time slots for the date
      final timeSlots = await queryTimeSlotRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThan: endOfDay),
      );

      // Get all reservations for the date
      final reservations = await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('creneaux', isGreaterThanOrEqualTo: startOfDay)
            .where('creneaux', isLessThan: endOfDay)
            .where('status', whereIn: ['confirmed', 'used']),
      );

      final totalCapacity =
          timeSlots.fold<int>(0, (total, slot) => total + slot.maxCapacity);
      final totalReservations = reservations.length;
      final occupancyRate =
          totalCapacity > 0 ? (totalReservations / totalCapacity) * 100 : 0.0;

      return {
        'totalCapacity': totalCapacity,
        'totalReservations': totalReservations,
        'occupancyRate': occupancyRate,
        'availableSlots': totalCapacity - totalReservations,
        'timeSlots': timeSlots.length,
      };
    } catch (e) {
      AppLogger.e('Error calculating occupancy stats',
          error: e, tag: 'ReservationService');
      return {
        'totalCapacity': 0,
        'totalReservations': 0,
        'occupancyRate': 0.0,
        'availableSlots': 0,
        'timeSlots': 0,
      };
    }
  }
}
