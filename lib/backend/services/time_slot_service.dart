import 'dart:async';
import 'package:flutter/foundation.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

/// Service for managing time slots with real-time capacity updates
/// Implements Requirements 4.1, 4.2, 4.3, 4.5, 4.6, 4.7
class TimeSlotService {
  static TimeSlotService? _instance;
  static TimeSlotService get instance => _instance ??= TimeSlotService._();
  TimeSlotService._();

  // Active listeners for real-time updates
  final Map<String, StreamSubscription<QuerySnapshot>> _activeListeners = {};

  /// Get available time slots for a specific date with real-time updates
  /// Requirement 4.1: Query time slots by date
  /// Requirement 4.5: Update time slot availability in real-time
  Stream<List<TimeSlotRecord>> getAvailableTimeSlotsStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('time_slots')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .where('is_active', isEqualTo: true)
        .orderBy('date')
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .where((slot) => slot.currentReservations < slot.maxCapacity)
          .toList();
    });
  }

  /// Get time slots for a specific date (one-time query)
  /// Requirement 4.1: Query Firestore for slots matching the selected date
  Future<List<TimeSlotRecord>> getAvailableTimeSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .where('is_active', isEqualTo: true)
          .orderBy('date')
          .orderBy('start_time')
          .get();

      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching time slots', error: e, tag: 'TimeSlotService');
      return [];
    }
  }

  /// Check if a time slot has available capacity
  /// Requirement 4.3: Mark time slot as unavailable when it reaches max_capacity
  Future<bool> hasAvailableCapacity(String timeSlotId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .get();

      if (!doc.exists) return false;

      final timeSlot = TimeSlotRecord.fromSnapshot(doc);
      return timeSlot.currentReservations < timeSlot.maxCapacity;
    } catch (e) {
      AppLogger.e('Error checking time slot capacity', error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Get a specific time slot by ID
  Future<TimeSlotRecord?> getTimeSlot(String timeSlotId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .get();

      if (!doc.exists) return null;

      return TimeSlotRecord.fromSnapshot(doc);
    } catch (e) {
      AppLogger.e('Error fetching time slot', error: e, tag: 'TimeSlotService');
      return null;
    }
  }

  /// Get real-time stream for a specific time slot
  /// Requirement 4.5: Update time slot availability in real-time
  Stream<TimeSlotRecord?> getTimeSlotStream(String timeSlotId) {
    return FirebaseFirestore.instance
        .collection('time_slots')
        .doc(timeSlotId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return TimeSlotRecord.fromSnapshot(snapshot);
    });
  }

  /// Check if a time slot is in the past
  /// Requirement 4.7: Prevent reservations for time slots in the past
  bool isTimeSlotInPast(TimeSlotRecord timeSlot) {
    if (timeSlot.endTime == null) return false;
    return timeSlot.endTime!.isBefore(DateTime.now());
  }

  /// Validate time slot for reservation
  /// Combines multiple validation checks
  Future<TimeSlotValidationResult> validateTimeSlotForReservation(
    String timeSlotId,
  ) async {
    try {
      final timeSlot = await getTimeSlot(timeSlotId);

      if (timeSlot == null) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Time slot not found',
        );
      }

      // Requirement 4.4: Check if time slot is marked is_active=false
      if (!timeSlot.isActive) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Time slot is not active',
        );
      }

      // Requirement 4.7: Prevent reservations for time slots in the past
      if (isTimeSlotInPast(timeSlot)) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Cannot reserve time slots in the past',
        );
      }

      // Requirement 4.3: Check if time slot has reached max_capacity
      if (timeSlot.currentReservations >= timeSlot.maxCapacity) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Time slot is fully booked',
        );
      }

      return TimeSlotValidationResult(
        isValid: true,
        timeSlot: timeSlot,
      );
    } catch (e) {
      AppLogger.e('Error validating time slot', error: e, tag: 'TimeSlotService');
      return TimeSlotValidationResult(
        isValid: false,
        errorMessage: 'Error validating time slot: $e',
      );
    }
  }

  /// Get all time slots for a date range (for admin)
  Future<List<TimeSlotRecord>> getTimeSlotsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .orderBy('date')
          .orderBy('start_time')
          .get();

      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching time slots in range', error: e, tag: 'TimeSlotService');
      return [];
    }
  }

  /// Create a new time slot (admin only)
  /// Requirement 11.1: Admin creates time slot
  Future<String?> createTimeSlot({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int maxCapacity,
    required double price,
    required String mealType,
  }) async {
    try {
      // Requirement 11.1: Validate start_time is before end_time
      if (!startTime.isBefore(endTime)) {
        throw Exception('Start time must be before end time');
      }

      // Requirement 11.2: Validate max_capacity is a positive integer
      if (maxCapacity <= 0) {
        throw Exception('Max capacity must be a positive integer');
      }

      final timeSlotData = createTimeSlotRecordData(
        date: date,
        startTime: startTime,
        endTime: endTime,
        maxCapacity: maxCapacity,
        currentReservations: 0, // Requirement 11.3: Set current_reservations to 0
        price: price,
        mealType: mealType,
        isActive: true,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('time_slots')
          .add(timeSlotData);

      return docRef.id;
    } catch (e) {
      AppLogger.e('Error creating time slot', error: e, tag: 'TimeSlotService');
      return null;
    }
  }

  /// Update time slot capacity (admin only)
  /// Requirement 11.4: Validate capacity is not less than current_reservations
  Future<bool> updateTimeSlotCapacity(
    String timeSlotId,
    int newCapacity,
  ) async {
    try {
      final timeSlot = await getTimeSlot(timeSlotId);

      if (timeSlot == null) {
        throw Exception('Time slot not found');
      }

      // Requirement 11.4: Validate new capacity is not less than current reservations
      if (newCapacity < timeSlot.currentReservations) {
        throw Exception(
          'New capacity ($newCapacity) cannot be less than current reservations (${timeSlot.currentReservations})',
        );
      }

      await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .update({'max_capacity': newCapacity});

      return true;
    } catch (e) {
      AppLogger.e('Error updating time slot capacity', error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Deactivate a time slot (admin only)
  /// Requirement 11.5: Set is_active to false and hide from students
  Future<bool> deactivateTimeSlot(String timeSlotId) async {
    try {
      await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .update({'is_active': false});

      return true;
    } catch (e) {
      AppLogger.e('Error deactivating time slot', error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Delete a time slot (admin only)
  /// Requirement 11.6: Prevent deletion if there are existing reservations
  Future<bool> deleteTimeSlot(String timeSlotId) async {
    try {
      final timeSlot = await getTimeSlot(timeSlotId);

      if (timeSlot == null) {
        throw Exception('Time slot not found');
      }

      // Requirement 11.6: Prevent deletion if there are existing reservations
      if (timeSlot.currentReservations > 0) {
        throw Exception(
          'Cannot delete time slot with existing reservations (${timeSlot.currentReservations} reservations)',
        );
      }

      await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .delete();

      return true;
    } catch (e) {
      AppLogger.e('Error deleting time slot', error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Bulk create time slots for multiple dates (admin only)
  /// Requirement 11.7: Allow admins to bulk create time slots
  Future<List<String>> bulkCreateTimeSlots({
    required List<DateTime> dates,
    required DateTime startTime,
    required DateTime endTime,
    required int maxCapacity,
    required double price,
    required String mealType,
  }) async {
    final createdIds = <String>[];

    for (final date in dates) {
      final timeSlotId = await createTimeSlot(
        date: date,
        startTime: DateTime(
          date.year,
          date.month,
          date.day,
          startTime.hour,
          startTime.minute,
        ),
        endTime: DateTime(
          date.year,
          date.month,
          date.day,
          endTime.hour,
          endTime.minute,
        ),
        maxCapacity: maxCapacity,
        price: price,
        mealType: mealType,
      );

      if (timeSlotId != null) {
        createdIds.add(timeSlotId);
      }
    }

    return createdIds;
  }

  /// Cleanup listeners
  void dispose() {
    for (final subscription in _activeListeners.values) {
      subscription.cancel();
    }
    _activeListeners.clear();
  }
}

/// Result of time slot validation
class TimeSlotValidationResult {
  final bool isValid;
  final String? errorMessage;
  final TimeSlotRecord? timeSlot;

  TimeSlotValidationResult({
    required this.isValid,
    this.errorMessage,
    this.timeSlot,
  });
}
