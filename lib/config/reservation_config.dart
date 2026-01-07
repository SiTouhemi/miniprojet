/// Configuration for reservation system behavior
/// This file allows easy switching between different validation approaches
class ReservationConfig {
  /// Choose the validation method for checking existing reservations
  ///
  /// COUNTER_BASED (Recommended): Uses daily counters to track reservations
  /// - Pros: No complex Firestore queries, no index requirements, faster
  /// - Cons: Requires maintaining counter documents and proper Firestore rules
  ///
  /// QUERY_BASED: Uses Firestore queries with client-side filtering
  /// - Pros: Direct query of reservation data, no additional documents
  /// - Cons: May require Firestore indexes for complex queries
  ///
  /// FIXED: Changed to COUNTER_BASED to avoid Firestore index errors
  static const ValidationMethod validationMethod =
      ValidationMethod.COUNTER_BASED;

  /// Maximum reservations per meal type per day
  static const int maxLunchReservationsPerDay = 1;
  static const int maxDinnerReservationsPerDay = 1;

  /// Minimum hours before meal time to allow cancellation/modification
  static const int minHoursBeforeCancellation = 2;

  /// Days to keep old counter documents (for cleanup)
  static const int counterRetentionDays = 30;

  /// Enable detailed logging for reservation operations
  static const bool enableDetailedLogging = true;

  /// Fallback behavior when validation fails
  /// If true, allows reservation when validation check fails
  /// If false, blocks reservation when validation check fails
  static const bool allowReservationOnValidationFailure = true;
}

enum ValidationMethod {
  COUNTER_BASED,
  QUERY_BASED,
}

/// Helper methods for configuration
extension ReservationConfigHelper on ReservationConfig {
  static bool get useCounterBasedValidation =>
      ReservationConfig.validationMethod == ValidationMethod.COUNTER_BASED;

  static bool get useQueryBasedValidation =>
      ReservationConfig.validationMethod == ValidationMethod.QUERY_BASED;
}
