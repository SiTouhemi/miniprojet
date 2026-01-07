import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

/// Alternative approach: Daily reservation counter service
/// This service maintains daily counters per user to avoid complex Firestore queries
/// Each user has a document per day tracking their meal reservations
class DailyReservationCounterService {
  static DailyReservationCounterService? _instance;
  static DailyReservationCounterService get instance =>
      _instance ??= DailyReservationCounterService._();
  DailyReservationCounterService._();

  /// Get or create daily counter document for a user
  Future<DocumentReference<Map<String, dynamic>>> _getDailyCounterRef(
      String userId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return FirebaseFirestore.instance
        .collection('daily_reservation_counters')
        .doc('${userId}_$dateStr');
  }

  /// Check if user can make a reservation for the specified meal type
  Future<Map<String, dynamic>> canMakeReservation(
      String userId, String mealType) async {
    try {
      final today = DateTime.now();
      final counterRef = await _getDailyCounterRef(userId, today);
      final counterDoc = await counterRef.get();

      if (!counterDoc.exists) {
        // No reservations today - user can make reservation
        return {'success': true, 'canReserve': true};
      }

      final data = counterDoc.data() as Map<String, dynamic>;
      final lunchCount = (data['lunch_count'] as int?) ?? 0;
      final dinnerCount = (data['dinner_count'] as int?) ?? 0;

      if (mealType == 'lunch' && lunchCount >= 1) {
        return {
          'success': false,
          'canReserve': false,
          'error':
              'Vous avez déjà une réservation pour le déjeuner aujourd\'hui. Une seule réservation par repas par jour est autorisée.',
          'errorCode': 'DUPLICATE_LUNCH_RESERVATION'
        };
      }

      if (mealType == 'dinner' && dinnerCount >= 1) {
        return {
          'success': false,
          'canReserve': false,
          'error':
              'Vous avez déjà une réservation pour le dîner aujourd\'hui. Une seule réservation par repas par jour est autorisée.',
          'errorCode': 'DUPLICATE_DINNER_RESERVATION'
        };
      }

      return {'success': true, 'canReserve': true};
    } catch (e) {
      AppLogger.e('Error checking daily reservation counter',
          error: e, tag: 'DailyReservationCounterService');

      // On error, allow reservation but log the issue
      return {
        'success': true,
        'canReserve': true,
        'warning':
            'Could not verify daily reservation limit due to database issues.'
      };
    }
  }

  /// Increment counter when a reservation is made
  Future<void> incrementCounter(String userId, String mealType) async {
    try {
      final today = DateTime.now();
      final counterRef = await _getDailyCounterRef(userId, today);

      final fieldToIncrement =
          mealType == 'lunch' ? 'lunch_count' : 'dinner_count';

      await counterRef.set({
        'user_id': userId,
        'date': today,
        'date_str':
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        fieldToIncrement: FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.i('Incremented $mealType counter for user $userId',
          tag: 'DailyReservationCounterService');
    } catch (e) {
      AppLogger.e('Error incrementing daily counter',
          error: e, tag: 'DailyReservationCounterService');
      // Don't throw - this is not critical for reservation creation
    }
  }

  /// Decrement counter when a reservation is cancelled
  Future<void> decrementCounter(
      String userId, String mealType, DateTime reservationDate) async {
    try {
      final counterRef = await _getDailyCounterRef(userId, reservationDate);
      final fieldToDecrement =
          mealType == 'lunch' ? 'lunch_count' : 'dinner_count';

      await counterRef.update({
        fieldToDecrement: FieldValue.increment(-1),
        'last_updated': FieldValue.serverTimestamp(),
      });

      AppLogger.i('Decremented $mealType counter for user $userId',
          tag: 'DailyReservationCounterService');
    } catch (e) {
      AppLogger.e('Error decrementing daily counter',
          error: e, tag: 'DailyReservationCounterService');
      // Don't throw - this is not critical for cancellation
    }
  }

  /// Get daily stats for a user
  Future<Map<String, dynamic>> getDailyStats(
      String userId, DateTime date) async {
    try {
      final counterRef = await _getDailyCounterRef(userId, date);
      final counterDoc = await counterRef.get();

      if (!counterDoc.exists) {
        return {
          'lunch_count': 0,
          'dinner_count': 0,
          'total_count': 0,
        };
      }

      final data = counterDoc.data() as Map<String, dynamic>;
      final lunchCount = (data['lunch_count'] as int?) ?? 0;
      final dinnerCount = (data['dinner_count'] as int?) ?? 0;

      return {
        'lunch_count': lunchCount,
        'dinner_count': dinnerCount,
        'total_count': lunchCount + dinnerCount,
      };
    } catch (e) {
      AppLogger.e('Error getting daily stats',
          error: e, tag: 'DailyReservationCounterService');
      return {
        'lunch_count': 0,
        'dinner_count': 0,
        'total_count': 0,
      };
    }
  }

  /// Clean up old counter documents (run periodically)
  Future<void> cleanupOldCounters({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr =
          '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      final oldCounters = await FirebaseFirestore.instance
          .collection('daily_reservation_counters')
          .where('date_str', isLessThan: cutoffDateStr)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in oldCounters.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.i('Cleaned up ${oldCounters.docs.length} old counter documents',
          tag: 'DailyReservationCounterService');
    } catch (e) {
      AppLogger.e('Error cleaning up old counters',
          error: e, tag: 'DailyReservationCounterService');
    }
  }
}
