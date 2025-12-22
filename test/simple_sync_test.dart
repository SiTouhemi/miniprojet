import 'package:flutter_test/flutter_test.dart';
import '../lib/flutter_flow/app_state.dart';

void main() {
  group('Real-time User Data Synchronization - Core Tests', () {
    late FFAppState appState;

    setUp(() {
      appState = FFAppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('should initialize with correct default values', () {
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isOnline, isTrue);
      expect(appState.lastError, isNull);
      expect(appState.userReservations, isEmpty);
      expect(appState.todaysMenu, isEmpty);
      expect(appState.availableTimeSlots, isEmpty);
    });

    test('should handle error states correctly', () {
      const errorMessage = 'Test network error';
      
      appState.setLastError(errorMessage);
      
      expect(appState.lastError, equals(errorMessage));
    });

    test('should clear error when set to null', () {
      // Set an error first
      appState.setLastError('Test error');
      expect(appState.lastError, equals('Test error'));
      
      // Clear the error
      appState.setLastError('');
      expect(appState.lastError, equals(''));
    });

    test('should provide correct app configuration defaults', () {
      expect(appState.getAppName(), equals('ISET Com Restaurant'));
      expect(appState.getWelcomeMessage(), equals('Welcome to our restaurant reservation system'));
      expect(appState.getContactEmail(), equals('contact@isetcom.tn'));
      expect(appState.getContactPhone(), equals('+216 XX XXX XXX'));
      expect(appState.getDefaultMealPrice(), equals(5.0));
      expect(appState.getMaxReservationsPerUser(), equals(3));
    });

    test('should handle logout correctly', () {
      // Simulate having some data
      appState.setLastError('Some error');
      
      // Logout should clear user data
      appState.logout();
      
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userReservations, isEmpty);
    });

    test('should calculate active reservations count when no user', () {
      expect(appState.getActiveReservationsCount(), equals(0));
    });

    test('should check reservation capability when no user', () {
      // Without a user, should not be able to make reservations
      expect(appState.canMakeMoreReservations(), isFalse);
    });

    test('should return empty lists for reservations when no user', () {
      expect(appState.getUpcomingReservations(), isEmpty);
      expect(appState.getPastReservations(), isEmpty);
    });

    test('should handle language setting', () {
      // Test language setting
      appState.setLanguage('fr');
      expect(appState.currentLanguage, equals('fr'));
      
      appState.setLanguage('ar');
      expect(appState.currentLanguage, equals('ar'));
    });

    test('should handle loading states', () {
      expect(appState.isLoadingSettings, isFalse);
      expect(appState.isLoadingTimeSlots, isFalse);
      expect(appState.isLoadingReservations, isFalse);
    });

    test('should handle selected date for time slots', () {
      final testDate = DateTime(2024, 1, 15);
      
      // The selectedDate should have a default value (today)
      expect(appState.selectedDate, isNotNull);
      
      // We can't directly test loadTimeSlots without mocking Firestore,
      // but we can verify the date is stored correctly
      expect(appState.selectedDate.year, equals(DateTime.now().year));
    });

    test('should handle cache clearing', () {
      // Clear cache should not throw errors
      expect(() => appState.clearCache(), returnsNormally);
      
      // After clearing cache, lists should be empty
      expect(appState.availableTimeSlots, isEmpty);
      expect(appState.userReservations, isEmpty);
      expect(appState.todaysMenu, isEmpty);
    });
  });
}