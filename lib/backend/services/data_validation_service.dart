import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/user_record.dart';
import '/backend/schema/reservation_record.dart';
import '/backend/schema/plat_record.dart';
import '/backend/schema/time_slot_record.dart';
import '/utils/error_handler.dart';

/// Service for validating data consistency between Firestore and UI display
/// Implements requirements 2.4, 5.1, 5.2, 5.3, 5.6 for real-time data synchronization
class DataValidationService {
  static final DataValidationService _instance = DataValidationService._internal();
  factory DataValidationService() => _instance;
  DataValidationService._internal();

  static DataValidationService get instance => _instance;

  /// Validate user data consistency between Firestore and local cache
  /// Requirement 2.1, 2.2, 2.3: Ensure displayed data matches Firestore
  Future<ValidationResult> validateUserData(UserRecord localUser, String uid) async {
    try {
      // Fetch fresh data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return ValidationResult(
          isValid: false,
          errors: ['User document not found in Firestore'],
          missingFields: [],
        );
      }

      final firestoreUser = UserRecord.fromSnapshot(doc);
      final errors = <String>[];
      final missingFields = <String>[];

      // Validate critical fields match
      if (localUser.nom != firestoreUser.nom) {
        errors.add('Name mismatch: local="${localUser.nom}", firestore="${firestoreUser.nom}"');
      }

      if (localUser.email != firestoreUser.email) {
        errors.add('Email mismatch: local="${localUser.email}", firestore="${firestoreUser.email}"');
      }

      if (localUser.pocket != firestoreUser.pocket) {
        errors.add('Balance mismatch: local=${localUser.pocket}, firestore=${firestoreUser.pocket}');
      }

      if (localUser.tickets != firestoreUser.tickets) {
        errors.add('Tickets mismatch: local=${localUser.tickets}, firestore=${firestoreUser.tickets}');
      }

      if (localUser.role != firestoreUser.role) {
        errors.add('Role mismatch: local="${localUser.role}", firestore="${firestoreUser.role}"');
      }

      // Check for missing optional fields
      if (firestoreUser.classe.isNotEmpty && localUser.classe != firestoreUser.classe) {
        errors.add('Class mismatch: local="${localUser.classe}", firestore="${firestoreUser.classe}"');
      }

      if (localUser.language != firestoreUser.language) {
        errors.add('Language mismatch: local="${localUser.language}", firestore="${firestoreUser.language}"');
      }

      if (localUser.notificationsEnabled != firestoreUser.notificationsEnabled) {
        errors.add('Notifications setting mismatch: local=${localUser.notificationsEnabled}, firestore=${firestoreUser.notificationsEnabled}');
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        missingFields: missingFields,
        firestoreData: firestoreUser,
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Validation failed: ${e.toString()}'],
        missingFields: [],
      );
    }
  }

  /// Validate reservation data consistency
  /// Requirement 5.2: Ensure reservation data is synchronized
  Future<ValidationResult> validateReservationData(List<ReservationRecord> localReservations, String userId) async {
    try {
      // Fetch fresh reservations from Firestore
      final query = await FirebaseFirestore.instance
          .collection('reservation')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final firestoreReservations = query.docs
          .map((doc) => ReservationRecord.fromSnapshot(doc))
          .toList();

      final errors = <String>[];

      // Check count consistency
      if (localReservations.length != firestoreReservations.length) {
        errors.add('Reservation count mismatch: local=${localReservations.length}, firestore=${firestoreReservations.length}');
      }

      // Check individual reservations
      for (int i = 0; i < localReservations.length && i < firestoreReservations.length; i++) {
        final local = localReservations[i];
        final firestore = firestoreReservations[i];

        if (local.status != firestore.status) {
          errors.add('Reservation ${i} status mismatch: local="${local.status}", firestore="${firestore.status}"');
        }

        if (local.creneaux?.millisecondsSinceEpoch != firestore.creneaux?.millisecondsSinceEpoch) {
          errors.add('Reservation ${i} time slot mismatch');
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        missingFields: [],
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Reservation validation failed: ${e.toString()}'],
        missingFields: [],
      );
    }
  }

  /// Validate menu data consistency
  /// Requirement 5.3: Ensure menu data is synchronized
  Future<ValidationResult> validateMenuData(List<PlatRecord> localMenu, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final query = await FirebaseFirestore.instance
          .collection('plat')
          .where('availableDate', isGreaterThanOrEqualTo: startOfDay)
          .where('availableDate', isLessThanOrEqualTo: endOfDay)
          .where('isActive', isEqualTo: true)
          .get();

      final firestoreMenu = query.docs
          .map((doc) => PlatRecord.fromSnapshot(doc))
          .toList();

      final errors = <String>[];

      // Check count consistency
      if (localMenu.length != firestoreMenu.length) {
        errors.add('Menu count mismatch: local=${localMenu.length}, firestore=${firestoreMenu.length}');
      }

      // Check individual menu items
      for (int i = 0; i < localMenu.length && i < firestoreMenu.length; i++) {
        final local = localMenu[i];
        final firestore = firestoreMenu[i];

        if (local.nom != firestore.nom) {
          errors.add('Menu item ${i} name mismatch: local="${local.nom}", firestore="${firestore.nom}"');
        }

        if (local.prix != firestore.prix) {
          errors.add('Menu item ${i} price mismatch: local=${local.prix}, firestore=${firestore.prix}');
        }

        // Note: PlatRecord doesn't have isActive property, skipping this validation
        // if (local.isActive != firestore.isActive) {
        //   errors.add('Menu item ${i} active status mismatch: local=${local.isActive}, firestore=${firestore.isActive}');
        // }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        missingFields: [],
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Menu validation failed: ${e.toString()}'],
        missingFields: [],
      );
    }
  }

  /// Validate time slot data consistency
  /// Requirement 5.1: Ensure time slot data is synchronized
  Future<ValidationResult> validateTimeSlotData(List<TimeSlotRecord> localSlots, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final query = await FirebaseFirestore.instance
          .collection('time_slot')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .where('isActive', isEqualTo: true)
          .get();

      final firestoreSlots = query.docs
          .map((doc) => TimeSlotRecord.fromSnapshot(doc))
          .toList();

      final errors = <String>[];

      // Check count consistency
      if (localSlots.length != firestoreSlots.length) {
        errors.add('Time slot count mismatch: local=${localSlots.length}, firestore=${firestoreSlots.length}');
      }

      // Check individual time slots
      for (int i = 0; i < localSlots.length && i < firestoreSlots.length; i++) {
        final local = localSlots[i];
        final firestore = firestoreSlots[i];

        if (local.maxCapacity != firestore.maxCapacity) {
          errors.add('Time slot ${i} capacity mismatch: local=${local.maxCapacity}, firestore=${firestore.maxCapacity}');
        }

        if (local.currentReservations != firestore.currentReservations) {
          errors.add('Time slot ${i} current reservations mismatch: local=${local.currentReservations}, firestore=${firestore.currentReservations}');
        }

        if (local.isActive != firestore.isActive) {
          errors.add('Time slot ${i} active status mismatch: local=${local.isActive}, firestore=${firestore.isActive}');
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        missingFields: [],
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Time slot validation failed: ${e.toString()}'],
        missingFields: [],
      );
    }
  }

  /// Check if data is stale and needs refresh
  /// Requirement 5.6: Performance monitoring for sync operations
  bool isDataStale(DateTime? lastSyncTime, {Duration maxAge = const Duration(minutes: 5)}) {
    if (lastSyncTime == null) return true;
    return DateTime.now().difference(lastSyncTime) > maxAge;
  }

  /// Validate that no hardcoded data is being displayed
  /// Requirement 2.5: Ensure no hardcoded data is displayed
  ValidationResult validateNoHardcodedData(UserRecord? user) {
    final errors = <String>[];

    if (user == null) {
      errors.add('User data is null - may be showing hardcoded fallback');
      return ValidationResult(
        isValid: false,
        errors: errors,
        missingFields: [],
      );
    }

    // Check for common hardcoded values
    if (user.nom == 'Test User' || user.nom == 'Default User' || user.nom == 'Utilisateur') {
      errors.add('Potentially hardcoded name detected: "${user.nom}"');
    }

    if (user.email == 'test@example.com' || user.email == 'user@test.com') {
      errors.add('Potentially hardcoded email detected: "${user.email}"');
    }

    if (user.pocket == 0.0 && user.tickets == 0) {
      // This could be legitimate, but worth flagging for new users
      // Don't add as error, just log for monitoring
    }

    if (user.classe == 'Test Class' || user.classe == 'Default') {
      errors.add('Potentially hardcoded class detected: "${user.classe}"');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      missingFields: [],
    );
  }

  /// Comprehensive data validation for all user-related data
  /// Combines all validation checks for complete consistency verification
  Future<ComprehensiveValidationResult> validateAllUserData(
    UserRecord? localUser,
    List<ReservationRecord> localReservations,
    List<PlatRecord> localMenu,
    List<TimeSlotRecord> localTimeSlots,
    DateTime selectedDate,
  ) async {
    if (localUser == null) {
      return ComprehensiveValidationResult(
        isValid: false,
        userValidation: ValidationResult(
          isValid: false,
          errors: ['No user data available'],
          missingFields: [],
        ),
        reservationValidation: ValidationResult(isValid: true, errors: [], missingFields: []),
        menuValidation: ValidationResult(isValid: true, errors: [], missingFields: []),
        timeSlotValidation: ValidationResult(isValid: true, errors: [], missingFields: []),
        hardcodedDataValidation: ValidationResult(isValid: true, errors: [], missingFields: []),
      );
    }

    // Run all validations in parallel for better performance
    final results = await Future.wait([
      validateUserData(localUser, localUser.uid),
      validateReservationData(localReservations, localUser.uid),
      validateMenuData(localMenu, selectedDate),
      validateTimeSlotData(localTimeSlots, selectedDate),
    ]);

    final hardcodedValidation = validateNoHardcodedData(localUser);

    return ComprehensiveValidationResult(
      isValid: results.every((r) => r.isValid) && hardcodedValidation.isValid,
      userValidation: results[0],
      reservationValidation: results[1],
      menuValidation: results[2],
      timeSlotValidation: results[3],
      hardcodedDataValidation: hardcodedValidation,
    );
  }
}

/// Result of data validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> missingFields;
  final UserRecord? firestoreData;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.missingFields,
    this.firestoreData,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: ${errors.length}, missingFields: ${missingFields.length})';
  }
}

/// Comprehensive validation result for all user data
class ComprehensiveValidationResult {
  final bool isValid;
  final ValidationResult userValidation;
  final ValidationResult reservationValidation;
  final ValidationResult menuValidation;
  final ValidationResult timeSlotValidation;
  final ValidationResult hardcodedDataValidation;

  ComprehensiveValidationResult({
    required this.isValid,
    required this.userValidation,
    required this.reservationValidation,
    required this.menuValidation,
    required this.timeSlotValidation,
    required this.hardcodedDataValidation,
  });

  List<String> get allErrors {
    return [
      ...userValidation.errors,
      ...reservationValidation.errors,
      ...menuValidation.errors,
      ...timeSlotValidation.errors,
      ...hardcodedDataValidation.errors,
    ];
  }

  @override
  String toString() {
    return 'ComprehensiveValidationResult(isValid: $isValid, totalErrors: ${allErrors.length})';
  }
}