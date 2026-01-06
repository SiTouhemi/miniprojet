import 'dart:async';
import '/backend/backend.dart';
import '/backend/services/app_service.dart';
import '/utils/app_logger.dart';
import '/config/app_config.dart';
import 'time_slot_template_service.dart';

/// Service for managing time slots with real-time capacity updates
/// NOW SUPPORTS DAILY RECURRING TIME SLOTS based on templates
/// Implements Requirements 4.1, 4.2, 4.3, 4.5, 4.6, 4.7
class TimeSlotService {
  static TimeSlotService? _instance;
  static TimeSlotService get instance => _instance ??= TimeSlotService._();
  TimeSlotService._();

  // Active listeners for real-time updates
  final Map<String, StreamSubscription<QuerySnapshot>> _activeListeners = {};

  // Template service for recurring slots
  final _templateService = TimeSlotTemplateService.instance;

  /// Get available time slots for a specific date with real-time updates
  /// HYBRID APPROACH: Uses existing slots but updates their dates dynamically
  Stream<List<TimeSlotRecord>> getAvailableTimeSlotsStream(DateTime date) {
    // For now, use the existing database approach but with updated locking logic
    return FirebaseFirestore.instance
        .collection('time_slots')
        .where('is_active', isEqualTo: true)
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .where((slot) {
        // Apply capacity and locking filters
        final hasCapacity = slot.currentReservations < slot.maxCapacity;
        final notLocked = !isTimeSlotLocked(slot);
        return hasCapacity && notLocked;
      }).toList();
    });
  }

  /// Get time slots for a specific date (one-time query)
  /// HYBRID APPROACH: Uses existing slots but with updated locking logic
  Future<List<TimeSlotRecord>> getAvailableTimeSlots(DateTime date) async {
    try {
      // Get all active slots (ignore date for now - treat as templates)
      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('is_active', isEqualTo: true)
          .orderBy('start_time')
          .get();

      AppLogger.i(
          'Found ${snapshot.docs.length} time slots (treating as recurring)',
          tag: 'TimeSlotService');

      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .where((slot) {
        // Apply capacity and locking filters
        final hasCapacity = slot.currentReservations < slot.maxCapacity;
        final notLocked = !isTimeSlotLocked(slot);
        return hasCapacity && notLocked;
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching time slots',
          error: e, tag: 'TimeSlotService');
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
      AppLogger.e('Error checking time slot capacity',
          error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Generate 20-minute time slots for restaurant operating hours
  /// Lunch: 11:40 - 14:00 (7 slots of 20 minutes each)
  /// Dinner: 17:40 - 18:40 (3 slots of 20 minutes each)
  /// DEPRECATED: Use generateDailyTimeSlotsFromTemplates instead
  @Deprecated('Use generateDailyTimeSlotsFromTemplates for recurring slots')
  Future<List<Map<String, dynamic>>> generateDailyTimeSlots(
      DateTime date) async {
    final List<Map<String, dynamic>> slots = [];

    // Generate lunch slots: 11:40 - 14:00
    final lunchSlots = await _generateMealTimeSlots(
      date: date,
      mealType: 'lunch',
      startHour: 11,
      startMinute: 40,
      endHour: 14,
      endMinute: 0,
    );
    slots.addAll(lunchSlots);

    // Generate dinner slots: 17:40 - 18:40
    final dinnerSlots = await _generateMealTimeSlots(
      date: date,
      mealType: 'dinner',
      startHour: 17,
      startMinute: 40,
      endHour: 18,
      endMinute: 40,
    );
    slots.addAll(dinnerSlots);

    return slots;
  }

  /// Generate time slots for a specific meal period
  Future<List<Map<String, dynamic>>> _generateMealTimeSlots({
    required DateTime date,
    required String mealType,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    final List<Map<String, dynamic>> slots = [];

    // Get the correct meal price from app settings
    final appSettings = await AppService.instance.getAppSettings();
    final mealPrice = appSettings.defaultMealPrice;

    final startTime =
        DateTime(date.year, date.month, date.day, startHour, startMinute);
    final endTime =
        DateTime(date.year, date.month, date.day, endHour, endMinute);

    DateTime currentSlotStart = startTime;

    while (currentSlotStart.isBefore(endTime)) {
      final slotEnd = currentSlotStart
          .add(Duration(minutes: AppConfig.timeSlotDurationMinutes));

      // Don't create slot if it would exceed the meal period end time
      if (slotEnd.isAfter(endTime)) {
        break;
      }

      slots.add({
        'date': DateTime(date.year, date.month, date.day),
        'start_time': currentSlotStart,
        'end_time': slotEnd,
        'max_capacity': AppConfig.defaultSlotCapacity,
        'current_reservations': 0,
        'price': mealPrice, // Use app settings meal price
        'is_active': true,
        'meal_type': mealType,
      });

      currentSlotStart = slotEnd;
    }

    return slots;
  }

  /// Generate daily time slots from templates (NEW RECURRING LOGIC)
  /// This creates actual time slot instances for a specific date based on templates
  Future<List<Map<String, dynamic>>> generateDailyTimeSlotsFromTemplates(
      DateTime date) async {
    try {
      // Get active templates
      final templates = await _templateService.getActiveTemplates();

      if (templates.isEmpty) {
        AppLogger.w('No active templates found. Initialize templates first.',
            tag: 'TimeSlotService');
        return [];
      }

      final List<Map<String, dynamic>> slots = [];

      for (final template in templates) {
        final startTime = _templateService.parseTimeForDate(
          template['start_time'] as String,
          date,
        );
        final endTime = _templateService.parseTimeForDate(
          template['end_time'] as String,
          date,
        );

        slots.add({
          'date': DateTime(date.year, date.month, date.day),
          'start_time': startTime,
          'end_time': endTime,
          'max_capacity': template['max_capacity'] as int,
          'current_reservations': 0,
          'price': (template['price'] as num).toDouble(),
          'is_active': true,
          'meal_type': template['meal_type'] as String,
          'template_id': template['id'] as String, // Link to template
        });
      }

      return slots;
    } catch (e) {
      AppLogger.e('Error generating slots from templates',
          error: e, tag: 'TimeSlotService');
      return [];
    }
  }

  /// Create time slots for a specific date using templates (NEW)
  Future<bool> createTimeSlotsForDateFromTemplates(DateTime date) async {
    try {
      // Check if restaurant is open on this date
      if (!isRestaurantOpen(date)) {
        AppLogger.w(
            'Restaurant is closed on ${date.toString().split(' ')[0]} (Sunday)',
            tag: 'TimeSlotService');
        return false;
      }

      final slots = await generateDailyTimeSlotsFromTemplates(date);

      if (slots.isEmpty) {
        AppLogger.w('No slots generated from templates',
            tag: 'TimeSlotService');
        return false;
      }

      // Check if slots already exist for this date
      final existingSlots = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isEqualTo: DateTime(date.year, date.month, date.day))
          .get();

      if (existingSlots.docs.isNotEmpty) {
        AppLogger.w(
            'Time slots already exist for ${date.toString().split(' ')[0]}',
            tag: 'TimeSlotService');
        return false;
      }

      // Create slots in batch
      final batch = FirebaseFirestore.instance.batch();

      for (final slotData in slots) {
        final docRef =
            FirebaseFirestore.instance.collection('time_slots').doc();
        batch.set(docRef, slotData);
      }

      await batch.commit();

      AppLogger.i(
          'Created ${slots.length} time slots from templates for ${date.toString().split(' ')[0]}',
          tag: 'TimeSlotService');
      return true;
    } catch (e) {
      AppLogger.e('Error creating time slots from templates',
          error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Bulk create time slots for multiple days using templates (NEW)
  Future<Map<String, dynamic>> bulkCreateTimeSlotsFromTemplates({
    required DateTime startDate,
    required int numberOfDays,
  }) async {
    int successCount = 0;
    int skipCount = 0;
    final List<String> errors = [];

    for (int i = 0; i < numberOfDays; i++) {
      final date = startDate.add(Duration(days: i));

      // Skip Sundays
      if (!isRestaurantOpen(date)) {
        skipCount++;
        continue;
      }

      try {
        final created = await createTimeSlotsForDateFromTemplates(date);
        if (created) {
          successCount++;
        } else {
          skipCount++;
        }
      } catch (e) {
        errors.add('${date.toString().split(' ')[0]}: ${e.toString()}');
      }
    }

    return {
      'success': true,
      'created': successCount,
      'skipped': skipCount,
      'errors': errors,
      'message':
          'Created time slots for $successCount days, skipped $skipCount days',
    };
  }

  /// Reset daily time slots (for automatic daily reset)
  /// This should be called daily to ensure slots are available for the next day
  Future<Map<String, dynamic>> resetDailyTimeSlots(DateTime date) async {
    try {
      // Delete existing slots for the date
      final existingSlots = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isEqualTo: DateTime(date.year, date.month, date.day))
          .get();

      if (existingSlots.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in existingSlots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        AppLogger.i('Deleted ${existingSlots.docs.length} existing slots',
            tag: 'TimeSlotService');
      }

      // Create new slots from templates
      final created = await createTimeSlotsForDateFromTemplates(date);

      return {
        'success': created,
        'message': created
            ? 'Time slots reset successfully'
            : 'Failed to reset time slots',
        'date': date.toString().split(' ')[0],
      };
    } catch (e) {
      AppLogger.e('Error resetting daily time slots',
          error: e, tag: 'TimeSlotService');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Create time slots in Firestore for a specific date
  Future<bool> createTimeSlotsForDate(DateTime date) async {
    try {
      final slots = await generateDailyTimeSlots(date);

      // Check if slots already exist for this date
      final existingSlots = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isEqualTo: DateTime(date.year, date.month, date.day))
          .get();

      if (existingSlots.docs.isNotEmpty) {
        AppLogger.w(
            'Time slots already exist for ${date.toString().split(' ')[0]}',
            tag: 'TimeSlotService');
        return false;
      }

      // Create slots in batch
      final batch = FirebaseFirestore.instance.batch();

      for (final slotData in slots) {
        final docRef =
            FirebaseFirestore.instance.collection('time_slots').doc();
        batch.set(docRef, slotData);
      }

      await batch.commit();

      AppLogger.i(
          'Created ${slots.length} time slots for ${date.toString().split(' ')[0]}',
          tag: 'TimeSlotService');
      return true;
    } catch (e) {
      AppLogger.e('Error creating time slots',
          error: e, tag: 'TimeSlotService');
      return false;
    }
  }

  /// Bulk create time slots for multiple days
  Future<Map<String, dynamic>> bulkCreateTimeSlots({
    required DateTime startDate,
    required int numberOfDays,
  }) async {
    int successCount = 0;
    int skipCount = 0;
    final List<String> errors = [];

    for (int i = 0; i < numberOfDays; i++) {
      final date = startDate.add(Duration(days: i));

      try {
        final created = await createTimeSlotsForDate(date);
        if (created) {
          successCount++;
        } else {
          skipCount++;
        }
      } catch (e) {
        errors.add('${date.toString().split(' ')[0]}: ${e.toString()}');
      }
    }

    return {
      'success': true,
      'created': successCount,
      'skipped': skipCount,
      'errors': errors,
      'message':
          'Created time slots for $successCount days, skipped $skipCount days',
    };
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
  /// NEW LOGIC: Uses meal period logic instead of individual slot end times
  /// Requirement 4.7: Prevent reservations for time slots in the past
  bool isTimeSlotInPast(TimeSlotRecord timeSlot) {
    // Use the same logic as isTimeSlotLocked for consistency
    return isTimeSlotLocked(timeSlot);
  }

  /// Check if a time slot is locked (past time but can be unlocked next day)
  /// RECURRING LOGIC: Ignores stored date, treats slots as daily recurring
  /// - Lunch slots (11:40-14:00) are available until 17:40 (dinner starts)
  /// - Dinner slots (17:40-18:40) are available until 23:59 (end of day)
  /// - All slots reset the next day (except Sundays - restaurant closed)
  bool isTimeSlotLocked(TimeSlotRecord timeSlot) {
    final now = DateTime.now();

    // Check if it's Sunday (restaurant closed)
    if (now.weekday == DateTime.sunday) {
      return true;
    }

    // For recurring slots, check meal period availability for TODAY
    if (timeSlot.mealType == 'lunch') {
      // Lunch slots available until dinner starts (17:40)
      final dinnerStartTime = DateTime(now.year, now.month, now.day, 17, 40);
      return now.isAfter(dinnerStartTime);
    } else if (timeSlot.mealType == 'dinner') {
      // Dinner slots available until end of day (23:59)
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
      return now.isAfter(endOfDay);
    }

    // Default: not locked
    return false;
  }

  /// Check if restaurant is open on a given date
  /// Restaurant is closed on Sundays
  bool isRestaurantOpen(DateTime date) {
    return date.weekday != DateTime.sunday;
  }

  /// Get available time slots with proper locking logic
  /// Filters out locked slots and Sunday slots
  Future<List<TimeSlotRecord>> getAvailableTimeSlotsWithLocking(
      DateTime date) async {
    try {
      // Check if restaurant is open on this date
      if (!isRestaurantOpen(date)) {
        AppLogger.i(
            'Restaurant is closed on ${date.toString().split(' ')[0]} (Sunday)',
            tag: 'TimeSlotService');
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('is_active', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .orderBy('date')
          .orderBy('start_time')
          .get();

      AppLogger.i(
          'Found ${snapshot.docs.length} time slots for ${date.toString().split(' ')[0]}',
          tag: 'TimeSlotService');

      return snapshot.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .where((slot) {
        // Has available capacity
        final hasCapacity = slot.currentReservations < slot.maxCapacity;

        // Not locked (not in the past)
        final notLocked = !isTimeSlotLocked(slot);

        return hasCapacity && notLocked;
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching available time slots with locking',
          error: e, tag: 'TimeSlotService');
      return [];
    }
  }

  /// Validate time slot for reservation
  /// Combines multiple validation checks including locking logic
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

      // Check if restaurant is closed (Sunday)
      if (timeSlot.date?.weekday == DateTime.sunday) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Restaurant is closed on Sundays',
        );
      }

      // Check if time slot is locked (past time)
      if (isTimeSlotLocked(timeSlot)) {
        return TimeSlotValidationResult(
          isValid: false,
          errorMessage: 'Time slot is no longer available (time has passed)',
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
      AppLogger.e('Error validating time slot',
          error: e, tag: 'TimeSlotService');
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
      AppLogger.e('Error fetching time slots in range',
          error: e, tag: 'TimeSlotService');
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
        currentReservations:
            0, // Requirement 11.3: Set current_reservations to 0
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
      AppLogger.e('Error updating time slot capacity',
          error: e, tag: 'TimeSlotService');
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
      AppLogger.e('Error deactivating time slot',
          error: e, tag: 'TimeSlotService');
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
