import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReservationService {
  static ReservationService? _instance;
  static ReservationService get instance => _instance ??= ReservationService._();
  ReservationService._();

  // Create a new reservation
  Future<Map<String, dynamic>> createReservation({
    required String userId,
    required String timeSlotId,
    required String mealType,
    String? paymentId,
  }) async {
    try {
      // Call cloud function to create reservation
      final result = await makeCloudCall('createReservation', {
        'userId': userId,
        'timeSlotId': timeSlotId,
        'mealType': mealType,
        'paymentId': paymentId,
      });

      return result;
    } catch (e) {
      print('Error creating reservation: $e');
      return {
        'success': false,
        'error': 'Failed to create reservation: ${e.toString()}'
      };
    }
  }

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
      print('Error validating QR code: $e');
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
      print('Error fetching reservation by QR: $e');
      return null;
    }
  }

  // Get reservations for a specific time slot
  Future<List<ReservationRecord>> getTimeSlotReservations(String timeSlotId) async {
    try {
      // First get the time slot to get its start time
      final timeSlotDoc = await TimeSlotRecord.collection.doc(timeSlotId).get();
      if (!timeSlotDoc.exists) return [];
      
      final timeSlot = TimeSlotRecord.fromSnapshot(timeSlotDoc);
      
      return await queryReservationRecordOnce(
        queryBuilder: (query) => query
            .where('creneaux', isEqualTo: timeSlot.startTime)
            .where('status', whereIn: ['confirmed', 'used']),
      );
    } catch (e) {
      print('Error fetching time slot reservations: $e');
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
            .where('status', whereIn: ['confirmed', 'pending'])
            .orderBy('creneaux'),
      );
    } catch (e) {
      print('Error fetching upcoming reservations: $e');
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
      print('Error fetching past reservations: $e');
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
      return await FirebaseFirestore.instance.runTransaction<Map<String, dynamic>>((transaction) async {
        // Get current reservation
        final reservationRef = ReservationRecord.collection.doc(reservationId);
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
            'error': 'Access denied. You can only cancel your own reservations.',
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
        if (reservation.creneaux != null && reservation.creneaux!.isBefore(now)) {
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
            'error': 'Cannot cancel reservation less than 2 hours before meal time',
            'errorCode': 'TOO_LATE_TO_CANCEL'
          };
        }
        
        // Find the time slot to update capacity
        final timeSlotQuery = await queryTimeSlotRecordOnce(
          queryBuilder: (query) => query.where('start_time', isEqualTo: reservation.creneaux),
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
        
        return {
          'success': true,
          'message': 'Reservation cancelled successfully',
          'reservationId': reservationId,
          'cancelledAt': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      print('Error cancelling reservation: $e');
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
      return await FirebaseFirestore.instance.runTransaction<Map<String, dynamic>>((transaction) async {
        // Get current reservation
        final reservationRef = ReservationRecord.collection.doc(reservationId);
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
            'error': 'Access denied. You can only modify your own reservations.',
            'errorCode': 'ACCESS_DENIED'
          };
        }
        
        // Check if reservation can be modified
        if (reservation.status != 'confirmed' && reservation.status != 'pending') {
          return {
            'success': false,
            'error': 'Only confirmed or pending reservations can be modified',
            'errorCode': 'INVALID_STATUS'
          };
        }
        
        // Requirement 5.7: Prevent modifications for past reservations
        final now = DateTime.now();
        if (reservation.creneaux != null && reservation.creneaux!.isBefore(now)) {
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
            'error': 'Cannot modify reservation less than 2 hours before meal time',
            'errorCode': 'TOO_LATE_TO_MODIFY'
          };
        }
        
        // Get new time slot
        final newTimeSlotRef = TimeSlotRecord.collection.doc(newTimeSlotId);
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
        if (newTimeSlot.startTime != null && newTimeSlot.startTime!.isBefore(now)) {
          return {
            'success': false,
            'error': 'Cannot modify to a past time slot',
            'errorCode': 'PAST_TIME_SLOT'
          };
        }
        
        // Check availability in new time slot
        if (newTimeSlot.currentReservations + reservation.capacity > newTimeSlot.maxCapacity) {
          return {
            'success': false,
            'error': 'New time slot does not have enough capacity',
            'errorCode': 'INSUFFICIENT_CAPACITY'
          };
        }
        
        // Find old time slot to update capacity
        final oldTimeSlotQuery = await queryTimeSlotRecordOnce(
          queryBuilder: (query) => query.where('start_time', isEqualTo: reservation.creneaux),
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
        
        // Atomic updates
        // Update reservation with new time slot details
        transaction.update(reservationRef, {
          'creneaux': newTimeSlot.startTime,
          'prix': newTimeSlot.price,
          'total': newTimeSlot.price * reservation.capacity,
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
      print('Error modifying reservation: $e');
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
      final reservationDoc = await ReservationRecord.collection.doc(reservationId).get();
      
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
      print('Error checking cancellation eligibility: $e');
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
      final reservationDoc = await ReservationRecord.collection.doc(reservationId).get();
      
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
      if (reservation.status != 'confirmed' && reservation.status != 'pending') {
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
      print('Error checking modification eligibility: $e');
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
      print('Error cancelling reservation via Cloud Function: $e');
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
      print('Error modifying reservation via Cloud Function: $e');
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
          final userDoc = await UserRecord.collection.doc(reservation.userId).get();
          final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;
          
          enrichedReservations.add({
            'reservation': reservation,
            'user': user,
            'userName': user?.displayName ?? user?.nom ?? 'Unknown User',
            'userClass': user?.classe ?? '',
          });
        } catch (e) {
          print('Error fetching user data for reservation: $e');
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
      print('Error fetching today\'s reservations: $e');
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
      
      final totalCapacity = timeSlots.fold<int>(0, (sum, slot) => sum + slot.maxCapacity);
      final totalReservations = reservations.length;
      final occupancyRate = totalCapacity > 0 ? (totalReservations / totalCapacity) * 100 : 0.0;
      
      return {
        'totalCapacity': totalCapacity,
        'totalReservations': totalReservations,
        'occupancyRate': occupancyRate,
        'availableSlots': totalCapacity - totalReservations,
        'timeSlots': timeSlots.length,
      };
    } catch (e) {
      print('Error calculating occupancy stats: $e');
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