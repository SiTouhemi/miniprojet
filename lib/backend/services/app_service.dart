import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppService {
  static AppService? _instance;
  static AppService get instance => _instance ??= AppService._();
  AppService._();

  // Cache for app settings
  AppSettingsRecord? _cachedSettings;
  DateTime? _lastSettingsFetch;

  // Get app settings with caching
  Future<AppSettingsRecord> getAppSettings() async {
    // Return cached settings if they're less than 5 minutes old
    if (_cachedSettings != null && 
        _lastSettingsFetch != null && 
        DateTime.now().difference(_lastSettingsFetch!).inMinutes < 5) {
      return _cachedSettings!;
    }

    try {
      final settingsQuery = await queryAppSettingsRecordOnce(limit: 1);
      
      if (settingsQuery.isNotEmpty) {
        _cachedSettings = settingsQuery.first;
      } else {
        // Create default settings if none exist
        _cachedSettings = await _createDefaultSettings();
      }
      
      _lastSettingsFetch = DateTime.now();
      return _cachedSettings!;
    } catch (e) {
      print('Error fetching app settings: $e');
      // Return default settings on error
      return _getDefaultSettings();
    }
  }

  // Create default app settings
  Future<AppSettingsRecord> _createDefaultSettings() async {
    try {
      final defaultData = createAppSettingsRecordData(
        appName: 'ISET Com Restaurant',
        welcomeMessage: 'Welcome to our restaurant reservation system',
        contactEmail: 'contact@isetcom.tn',
        contactPhone: '+216 XX XXX XXX',
        restaurantAddress: 'ISET Com Campus',
        defaultMealPrice: 5.0,
        maxReservationsPerUser: 3,
        reservationDeadlineHours: 2,
        notificationEnabled: true,
      );

      final docRef = await AppSettingsRecord.collection.add(defaultData);
      final doc = await docRef.get();
      return AppSettingsRecord.fromSnapshot(doc);
    } catch (e) {
      print('Error creating default settings: $e');
      return _getDefaultSettings();
    }
  }

  // Get default settings without database
  AppSettingsRecord _getDefaultSettings() {
    return AppSettingsRecord.getDocumentFromData({
      'app_name': 'ISET Com Restaurant',
      'welcome_message': 'Welcome to our restaurant reservation system',
      'contact_email': 'contact@isetcom.tn',
      'contact_phone': '+216 XX XXX XXX',
      'restaurant_address': 'ISET Com Campus',
      'default_meal_price': 5.0,
      'max_reservations_per_user': 3,
      'reservation_deadline_hours': 2,
      'notification_enabled': true,
    }, FirebaseFirestore.instance.collection('app_settings').doc('default'));
  }

  // Update app settings
  Future<bool> updateAppSettings(Map<String, dynamic> updates) async {
    try {
      if (_cachedSettings?.reference != null) {
        await _cachedSettings!.reference.update(updates);
        _cachedSettings = null; // Clear cache to force refresh
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating app settings: $e');
      return false;
    }
  }

  // Get available time slots for a specific date
  Future<List<TimeSlotRecord>> getAvailableTimeSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final timeSlots = await queryTimeSlotRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThan: endOfDay)
            .where('is_active', isEqualTo: true)
            .orderBy('date')
            .orderBy('start_time'),
      );

      // Filter out full slots
      return timeSlots.where((slot) => 
        slot.currentReservations < slot.maxCapacity).toList();
    } catch (e) {
      print('Error fetching time slots: $e');
      return [];
    }
  }

  // Get user's active reservations
  Future<List<ReservationRecord>> getUserReservations(String userId, {bool activeOnly = false}) async {
    try {
      Query query = ReservationRecord.collection.where('user_id', isEqualTo: userId);
      
      if (activeOnly) {
        query = query.where('status', whereIn: ['confirmed', 'pending']);
      }
      
      final snapshot = await query.orderBy('created_at', descending: true).get();
      return snapshot.docs.map((doc) => ReservationRecord.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error fetching user reservations: $e');
      return [];
    }
  }

  // Check if user can make more reservations
  Future<bool> canUserMakeReservation(String userId) async {
    try {
      final settings = await getAppSettings();
      final activeReservations = await getUserReservations(userId, activeOnly: true);
      
      return activeReservations.length < settings.maxReservationsPerUser;
    } catch (e) {
      print('Error checking reservation limit: $e');
      return false;
    }
  }

  // Cancel reservation
  Future<bool> cancelReservation(String reservationId, String userId) async {
    try {
      final reservationDoc = await ReservationRecord.collection.doc(reservationId).get();
      
      if (!reservationDoc.exists) {
        return false;
      }
      
      final reservation = ReservationRecord.fromSnapshot(reservationDoc);
      
      // Check if user owns this reservation
      if (reservation.userId != userId) {
        return false;
      }
      
      // Check if cancellation is allowed (not too close to meal time)
      final settings = await getAppSettings();
      final now = DateTime.now();
      final mealTime = reservation.creneaux;
      
      if (mealTime != null && 
          mealTime.difference(now).inHours < settings.reservationDeadlineHours) {
        return false; // Too late to cancel
      }
      
      // Update reservation status
      await reservationDoc.reference.update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
      });
      
      // Update time slot capacity
      final timeSlotQuery = await queryTimeSlotRecordOnce(
        queryBuilder: (query) => query.where('start_time', isEqualTo: mealTime),
        limit: 1,
      );
      
      if (timeSlotQuery.isNotEmpty) {
        await timeSlotQuery.first.reference.update({
          'current_reservations': FieldValue.increment(-1),
        });
      }
      
      return true;
    } catch (e) {
      print('Error cancelling reservation: $e');
      return false;
    }
  }

  // Get today's menu
  Future<List<PlatRecord>> getTodaysMenu() async {
    try {
      return await queryPlatRecordOnce(
        queryBuilder: (query) => query.orderBy('categorie').orderBy('nom'),
      );
    } catch (e) {
      print('Error fetching menu: $e');
      return [];
    }
  }

  // Get analytics data for admin dashboard
  Future<Map<String, dynamic>> getAnalytics({int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final analytics = await queryAnalyticsRecordOnce(
        queryBuilder: (query) => query
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThan: endDate)
            .orderBy('date', descending: true),
      );
      
      if (analytics.isEmpty) {
        return {
          'totalReservations': 0,
          'totalRevenue': 0.0,
          'averageOccupancy': 0.0,
          'peakHour': '12:00',
          'cancellationRate': 0.0,
        };
      }
      
      final totalReservations = analytics.fold<int>(0, (sum, record) => sum + record.totalReservations);
      final totalRevenue = analytics.fold<double>(0, (sum, record) => sum + record.totalRevenue);
      final avgOccupancy = analytics.fold<double>(0, (sum, record) => sum + record.averageOccupancy) / analytics.length;
      
      // Find most common peak hour
      final peakHours = <String, int>{};
      for (final record in analytics) {
        peakHours[record.peakHour] = (peakHours[record.peakHour] ?? 0) + 1;
      }
      
      final mostCommonPeakHour = peakHours.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      return {
        'totalReservations': totalReservations,
        'totalRevenue': totalRevenue,
        'averageOccupancy': avgOccupancy,
        'peakHour': mostCommonPeakHour,
        'cancellationRate': analytics.isNotEmpty ? analytics.last.cancellationRate : 0.0,
        'dailyData': analytics,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }
}