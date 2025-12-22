import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/flutter_flow/app_state.dart';
import '../lib/backend/schema/user_record.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('Real-time User Data Synchronization Tests', () {
    late FFAppState appState;

    setUp(() {
      appState = FFAppState();
    });

    tearDown(() {
      appState.dispose();
    });

    test('should initialize with default values', () {
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isOnline, isTrue);
      expect(appState.lastError, isNull);
    });

    test('should set current user and update login state', () {
      // Create a mock user document reference
      final mockDocRef = MockDocumentReference();
      
      // Create test user data
      final userData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'nom': 'Test User',
        'pocket': 25.50,
        'tickets': 3,
        'role': 'student',
        'language': 'fr',
        'notifications_enabled': true,
      };

      // Create UserRecord from test data
      final user = UserRecord.getDocumentFromData(userData, mockDocRef);

      // Set the user
      appState.setCurrentUser(user);

      // Verify state changes
      expect(appState.currentUser, equals(user));
      expect(appState.isLoggedIn, isTrue);
      expect(appState.currentUser?.nom, equals('Test User'));
      expect(appState.currentUser?.pocket, equals(25.50));
      expect(appState.currentUser?.tickets, equals(3));
    });

    test('should clear user data on logout', () {
      // First set a user
      final mockDocRef = MockDocumentReference();
      final userData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'nom': 'Test User',
        'pocket': 25.50,
        'tickets': 3,
        'role': 'student',
      };
      final user = UserRecord.getDocumentFromData(userData, mockDocRef);
      appState.setCurrentUser(user);

      // Verify user is set
      expect(appState.isLoggedIn, isTrue);

      // Logout
      appState.logout();

      // Verify state is cleared
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userReservations, isEmpty);
    });

    test('should handle error states correctly', () {
      const errorMessage = 'Test error message';
      
      appState.setLastError(errorMessage);
      
      expect(appState.lastError, equals(errorMessage));
    });

    test('should manage offline state', () {
      // Initially online
      expect(appState.isOnline, isTrue);
      
      // Simulate going offline (this would normally be called internally)
      // We can't directly test the private method, but we can verify the public interface
      expect(appState.isOnline, isTrue);
    });

    test('should calculate active reservations count correctly', () {
      // Set up a user first
      final mockDocRef = MockDocumentReference();
      final userData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'nom': 'Test User',
        'pocket': 25.50,
        'tickets': 3,
        'role': 'student',
      };
      final user = UserRecord.getDocumentFromData(userData, mockDocRef);
      appState.setCurrentUser(user);

      // Initially should be 0
      expect(appState.getActiveReservationsCount(), equals(0));
    });

    test('should check if user can make more reservations', () {
      // Set up a user first
      final mockDocRef = MockDocumentReference();
      final userData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'nom': 'Test User',
        'pocket': 25.50,
        'tickets': 3,
        'role': 'student',
      };
      final user = UserRecord.getDocumentFromData(userData, mockDocRef);
      appState.setCurrentUser(user);

      // Should be able to make reservations (default max is 3, current is 0)
      expect(appState.canMakeMoreReservations(), isTrue);
    });

    test('should get upcoming and past reservations correctly', () {
      // Set up a user first
      final mockDocRef = MockDocumentReference();
      final userData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'nom': 'Test User',
        'pocket': 25.50,
        'tickets': 3,
        'role': 'student',
      };
      final user = UserRecord.getDocumentFromData(userData, mockDocRef);
      appState.setCurrentUser(user);

      // Initially should be empty
      expect(appState.getUpcomingReservations(), isEmpty);
      expect(appState.getPastReservations(), isEmpty);
    });

    test('should provide app configuration values', () {
      expect(appState.getAppName(), equals('ISET Com Restaurant'));
      expect(appState.getWelcomeMessage(), equals('Welcome to our restaurant reservation system'));
      expect(appState.getContactEmail(), equals('contact@isetcom.tn'));
      expect(appState.getDefaultMealPrice(), equals(5.0));
      expect(appState.getMaxReservationsPerUser(), equals(3));
    });
  });
}