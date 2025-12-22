import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Simplified demonstration of real-time synchronization concepts
class MockUserData {
  final String uid;
  final String nom;
  final double pocket;
  final int tickets;
  final String role;

  MockUserData({
    required this.uid,
    required this.nom,
    required this.pocket,
    required this.tickets,
    required this.role,
  });

  MockUserData copyWith({
    String? uid,
    String? nom,
    double? pocket,
    int? tickets,
    String? role,
  }) {
    return MockUserData(
      uid: uid ?? this.uid,
      nom: nom ?? this.nom,
      pocket: pocket ?? this.pocket,
      tickets: tickets ?? this.tickets,
      role: role ?? this.role,
    );
  }
}

class MockAppState extends ChangeNotifier {
  MockUserData? _currentUser;
  MockUserData? get currentUser => _currentUser;
  
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  String? _lastError;
  String? get lastError => _lastError;
  
  List<String> _userReservations = [];
  List<String> get userReservations => _userReservations;

  // Simulate setting current user with real-time sync
  void setCurrentUser(MockUserData? user) {
    _currentUser = user;
    _isLoggedIn = user != null;
    _clearError();
    notifyListeners();
    
    if (user != null) {
      print('Real-time sync initialized for user: ${user.nom}');
      // In real implementation, this would setup Firestore listeners
      _simulateRealTimeUpdates();
    } else {
      _userReservations.clear();
    }
  }

  // Simulate real-time user data updates
  void _simulateRealTimeUpdates() {
    // This simulates receiving real-time updates from Firestore
    Future.delayed(Duration(milliseconds: 100), () {
      if (_currentUser != null) {
        // Simulate balance update
        _currentUser = _currentUser!.copyWith(pocket: _currentUser!.pocket + 5.0);
        print('Real-time update: Balance updated to ${_currentUser!.pocket} DT');
        notifyListeners();
      }
    });
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    _userReservations.clear();
    _clearError();
    notifyListeners();
  }

  void setLastError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void setOfflineMode() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
  }

  void setOnlineMode() {
    if (!_isOnline) {
      _isOnline = true;
      _clearError();
      notifyListeners();
    }
  }

  // Simulate adding a reservation with real-time sync
  void addReservation(String reservationId) {
    _userReservations.insert(0, reservationId);
    print('Real-time sync: Reservation $reservationId added');
    notifyListeners();
  }

  // Simulate removing a reservation with real-time sync
  void removeReservation(String reservationId) {
    _userReservations.removeWhere((id) => id == reservationId);
    print('Real-time sync: Reservation $reservationId removed');
    notifyListeners();
  }

  int getActiveReservationsCount() {
    return _userReservations.length;
  }

  bool canMakeMoreReservations() {
    const maxReservations = 3;
    return getActiveReservationsCount() < maxReservations;
  }
}

void main() {
  group('Real-time User Data Synchronization Demo', () {
    late MockAppState appState;

    setUp(() {
      appState = MockAppState();
    });

    test('should initialize with correct default values', () {
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isOnline, isTrue);
      expect(appState.lastError, isNull);
      expect(appState.userReservations, isEmpty);
    });

    test('should set current user and trigger real-time sync', () async {
      final testUser = MockUserData(
        uid: 'test-uid',
        nom: 'Ahmed Ben Ali',
        pocket: 25.50,
        tickets: 3,
        role: 'student',
      );

      // Set user - this would trigger real-time listeners in real implementation
      appState.setCurrentUser(testUser);

      // Verify immediate state changes
      expect(appState.currentUser, equals(testUser));
      expect(appState.isLoggedIn, isTrue);
      expect(appState.currentUser?.nom, equals('Ahmed Ben Ali'));
      expect(appState.currentUser?.pocket, equals(25.50));

      // Wait for simulated real-time update
      await Future.delayed(Duration(milliseconds: 150));

      // Verify real-time update occurred
      expect(appState.currentUser?.pocket, equals(30.50)); // +5.0 from simulation
    });

    test('should handle real-time reservation updates', () {
      final testUser = MockUserData(
        uid: 'test-uid',
        nom: 'Ahmed Ben Ali',
        pocket: 25.50,
        tickets: 3,
        role: 'student',
      );

      appState.setCurrentUser(testUser);

      // Initially no reservations
      expect(appState.getActiveReservationsCount(), equals(0));
      expect(appState.canMakeMoreReservations(), isTrue);

      // Add reservations (simulating real-time updates from Firestore)
      appState.addReservation('reservation-1');
      expect(appState.getActiveReservationsCount(), equals(1));
      expect(appState.userReservations, contains('reservation-1'));

      appState.addReservation('reservation-2');
      expect(appState.getActiveReservationsCount(), equals(2));

      appState.addReservation('reservation-3');
      expect(appState.getActiveReservationsCount(), equals(3));
      expect(appState.canMakeMoreReservations(), isFalse); // Max reached

      // Remove a reservation (simulating cancellation)
      appState.removeReservation('reservation-2');
      expect(appState.getActiveReservationsCount(), equals(2));
      expect(appState.canMakeMoreReservations(), isTrue);
      expect(appState.userReservations, isNot(contains('reservation-2')));
    });

    test('should handle network state changes', () {
      expect(appState.isOnline, isTrue);

      // Simulate going offline
      appState.setOfflineMode();
      expect(appState.isOnline, isFalse);

      // Simulate coming back online
      appState.setOnlineMode();
      expect(appState.isOnline, isTrue);
    });

    test('should handle error states with real-time sync', () {
      const errorMessage = 'Network connection lost';
      
      appState.setLastError(errorMessage);
      expect(appState.lastError, equals(errorMessage));

      // Error should be cleared when user is set (simulating successful reconnection)
      final testUser = MockUserData(
        uid: 'test-uid',
        nom: 'Ahmed Ben Ali',
        pocket: 25.50,
        tickets: 3,
        role: 'student',
      );

      appState.setCurrentUser(testUser);
      expect(appState.lastError, isNull); // Error cleared
    });

    test('should clear all data on logout', () async {
      final testUser = MockUserData(
        uid: 'test-uid',
        nom: 'Ahmed Ben Ali',
        pocket: 25.50,
        tickets: 3,
        role: 'student',
      );

      // Set user and add some data
      appState.setCurrentUser(testUser);
      appState.addReservation('reservation-1');
      appState.setLastError('Some error');

      // Wait for any async operations
      await Future.delayed(Duration(milliseconds: 50));

      // Verify data is present
      expect(appState.isLoggedIn, isTrue);
      expect(appState.userReservations, isNotEmpty);

      // Logout
      appState.logout();

      // Verify all data is cleared
      expect(appState.currentUser, isNull);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userReservations, isEmpty);
      expect(appState.lastError, isNull);
    });

    test('should demonstrate real-time data consistency', () async {
      final testUser = MockUserData(
        uid: 'test-uid',
        nom: 'Ahmed Ben Ali',
        pocket: 25.50,
        tickets: 3,
        role: 'student',
      );

      // Track notifications
      int notificationCount = 0;
      appState.addListener(() {
        notificationCount++;
      });

      // Set user - should trigger notification
      appState.setCurrentUser(testUser);
      expect(notificationCount, greaterThan(0));

      final initialNotifications = notificationCount;

      // Wait for simulated real-time update
      await Future.delayed(Duration(milliseconds: 150));

      // Should have received additional notification from real-time update
      expect(notificationCount, greaterThan(initialNotifications));

      // Verify the data was updated in real-time
      expect(appState.currentUser?.pocket, equals(30.50));
    });
  });
}