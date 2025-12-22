import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../lib/backend/services/data_validation_service.dart';
import '../lib/backend/schema/user_record.dart';
import '../lib/backend/schema/reservation_record.dart';
import '../lib/backend/schema/plat_record.dart';
import '../lib/backend/schema/time_slot_record.dart';
import 'dart:math';

/// Comprehensive data display validation tests
/// Feature: student-authentication-flow, Property 3: Data Display Consistency
/// Validates: Requirements 2.1, 2.2, 2.3, 2.5, 2.7
void main() {
  group('Data Display Validation Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DataValidationService validationService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      validationService = DataValidationService.instance;
    });

    group('User Data Validation', () {
      testProperty(
        'User data should match between local cache and Firestore',
        () async {
          final random = Random();
          final userId = 'user_${random.nextInt(10000)}';
          
          // Create test user data
          final userData = {
            'uid': userId,
            'display_name': 'Test User ${random.nextInt(1000)}',
            'email': 'user${random.nextInt(1000)}@isetcom.tn',
            'nom': 'Nom Test ${random.nextInt(1000)}',
            'pocket': (random.nextDouble() * 100).roundToDouble(),
            'tickets': random.nextInt(10),
            'cin': random.nextInt(90000000) + 10000000,
            'classe': 'DSI${random.nextInt(3) + 1}',
            'role': 'student',
            'language': 'fr',
            'notifications_enabled': random.nextBool(),
            'created_time': Timestamp.fromDate(DateTime.now()),
            'last_login': Timestamp.fromDate(DateTime.now()),
          };

          // Store in fake Firestore
          await fakeFirestore.collection('user').doc(userId).set(userData);

          // Create local user record
          final doc = await fakeFirestore.collection('user').doc(userId).get();
          final localUser = UserRecord.fromSnapshot(doc);

          // Validate consistency
          final validation = await validationService.validateUserData(localUser, userId);

          expect(validation.isValid, isTrue, 
            reason: 'User data should be consistent: ${validation.errors}');
          expect(validation.errors, isEmpty,
            reason: 'No validation errors should occur for consistent data');
        },
        iterations: 50,
      );

      testProperty(
        'Hardcoded data should be detected and flagged',
        () async {
          final testCases = [
            {'nom': 'Test User', 'email': 'test@example.com'},
            {'nom': 'Default User', 'email': 'user@test.com'},
            {'nom': 'Utilisateur', 'email': 'real@isetcom.tn'},
            {'nom': 'Real Name', 'classe': 'Test Class'},
            {'nom': 'Real Name', 'classe': 'Default'},
          ];

          for (final testCase in testCases) {
            final userData = {
              'uid': 'test_user',
              'display_name': testCase['nom'] ?? 'Real Name',
              'email': testCase['email'] ?? 'real@isetcom.tn',
              'nom': testCase['nom'] ?? 'Real Name',
              'pocket': 25.0,
              'tickets': 3,
              'classe': testCase['classe'] ?? 'DSI1',
              'role': 'student',
              'language': 'fr',
              'notifications_enabled': true,
              'created_time': Timestamp.fromDate(DateTime.now()),
            };

            final mockDocRef = FakeFirebaseFirestore().collection('user').doc('test_user');
            final user = UserRecord.getDocumentFromData(userData, mockDocRef);

            final validation = validationService.validateNoHardcodedData(user);

            // Should detect hardcoded data in test cases with suspicious values
            if (testCase.containsKey('nom') && 
                (testCase['nom'] == 'Test User' || 
                 testCase['nom'] == 'Default User' || 
                 testCase['nom'] == 'Utilisateur')) {
              expect(validation.isValid, isFalse,
                reason: 'Should detect hardcoded name: ${testCase['nom']}');
            }

            if (testCase.containsKey('email') && 
                (testCase['email'] == 'test@example.com' || 
                 testCase['email'] == 'user@test.com')) {
              expect(validation.isValid, isFalse,
                reason: 'Should detect hardcoded email: ${testCase['email']}');
            }

            if (testCase.containsKey('classe') && 
                (testCase['classe'] == 'Test Class' || 
                 testCase['classe'] == 'Default')) {
              expect(validation.isValid, isFalse,
                reason: 'Should detect hardcoded class: ${testCase['classe']}');
            }
          }
        },
        iterations: 1, // Run once with predefined test cases
      );

      test('Missing optional data should be handled gracefully', () {
        final userData = {
          'uid': 'test_user',
          'display_name': 'Test User',
          'email': 'test@isetcom.tn',
          'nom': 'Test User',
          'pocket': 25.0,
          'tickets': 3,
          'role': 'student',
          'language': 'fr',
          'notifications_enabled': true,
          'created_time': Timestamp.fromDate(DateTime.now()),
          // Missing optional fields: classe, cin, phone_number
        };

        final mockDocRef = FakeFirebaseFirestore().collection('user').doc('test_user');
        final user = UserRecord.getDocumentFromData(userData, mockDocRef);

        // Should handle missing optional data gracefully
        expect(user.classe, isEmpty, reason: 'Missing classe should be empty string');
        expect(user.cin, equals(0), reason: 'Missing CIN should be 0');
        expect(user.phoneNumber, isEmpty, reason: 'Missing phone should be empty string');

        // Validation should still pass for missing optional data
        final validation = validationService.validateNoHardcodedData(user);
        expect(validation.isValid, isTrue, 
          reason: 'Missing optional data should not fail validation');
      });
    });

    group('Data Type Consistency', () {
      testProperty(
        'Numeric data should maintain precision and type consistency',
        () async {
          final random = Random();
          
          // Test various numeric scenarios
          final testCases = [
            {'pocket': 0.0, 'tickets': 0}, // Zero values
            {'pocket': 0.01, 'tickets': 1}, // Minimum values
            {'pocket': 999.99, 'tickets': 999}, // Maximum reasonable values
            {'pocket': 25.50, 'tickets': 5}, // Typical values
            {'pocket': double.parse((random.nextDouble() * 100).toStringAsFixed(2)), 
             'tickets': random.nextInt(50)}, // Random values
          ];

          for (final testCase in testCases) {
            final userData = {
              'uid': 'test_user',
              'display_name': 'Test User',
              'email': 'test@isetcom.tn',
              'nom': 'Test User',
              'pocket': testCase['pocket'],
              'tickets': testCase['tickets'],
              'role': 'student',
              'language': 'fr',
              'notifications_enabled': true,
              'created_time': Timestamp.fromDate(DateTime.now()),
            };

            final mockDocRef = FakeFirebaseFirestore().collection('user').doc('test_user');
            final user = UserRecord.getDocumentFromData(userData, mockDocRef);

            // Verify numeric precision is maintained
            expect(user.pocket, equals(testCase['pocket']),
              reason: 'Pocket balance precision should be maintained');
            expect(user.tickets, equals(testCase['tickets']),
              reason: 'Ticket count should be exact');

            // Verify types are correct
            expect(user.pocket, isA<double>(),
              reason: 'Pocket should be double type');
            expect(user.tickets, isA<int>(),
              reason: 'Tickets should be int type');
          }
        },
        iterations: 20,
      );

      testProperty(
        'String data should preserve encoding and special characters',
        () async {
          final testStrings = [
            'Ahmed Ben Ali',
            'Fatma Bint Mohamed',
            'Jean-Pierre Dupont',
            'María José García',
            'محمد بن علي', // Arabic
            'فاطمة بنت محمد', // Arabic
            'User with émojis 🎓📚',
            'Special chars: @#\$%^&*()',
            'Accented: àáâãäåæçèéêë',
          ];

          for (final testString in testStrings) {
            final userData = {
              'uid': 'test_user',
              'display_name': testString,
              'email': 'test@isetcom.tn',
              'nom': testString,
              'pocket': 25.0,
              'tickets': 3,
              'classe': 'DSI1-${testString.substring(0, min(5, testString.length))}',
              'role': 'student',
              'language': 'fr',
              'notifications_enabled': true,
              'created_time': Timestamp.fromDate(DateTime.now()),
            };

            final mockDocRef = FakeFirebaseFirestore().collection('user').doc('test_user');
            final user = UserRecord.getDocumentFromData(userData, mockDocRef);

            // Verify string encoding is preserved
            expect(user.displayName, equals(testString),
              reason: 'Display name encoding should be preserved: "$testString"');
            expect(user.nom, equals(testString),
              reason: 'Nom encoding should be preserved: "$testString"');
            
            // Verify string length is preserved
            expect(user.displayName.length, equals(testString.length),
              reason: 'String length should be preserved');
          }
        },
        iterations: 1, // Run once with predefined test cases
      );

      testProperty(
        'Boolean and enum values should be consistent',
        () async {
          final random = Random();
          final roles = ['student', 'staff', 'admin'];
          final languages = ['fr', 'ar', 'en'];
          
          for (int i = 0; i < 10; i++) {
            final notificationsEnabled = random.nextBool();
            final role = roles[random.nextInt(roles.length)];
            final language = languages[random.nextInt(languages.length)];

            final userData = {
              'uid': 'test_user_$i',
              'display_name': 'Test User $i',
              'email': 'test$i@isetcom.tn',
              'nom': 'Test User $i',
              'pocket': 25.0,
              'tickets': 3,
              'role': role,
              'language': language,
              'notifications_enabled': notificationsEnabled,
              'created_time': Timestamp.fromDate(DateTime.now()),
            };

            final mockDocRef = FakeFirebaseFirestore().collection('user').doc('test_user_$i');
            final user = UserRecord.getDocumentFromData(userData, mockDocRef);

            // Verify boolean values are preserved
            expect(user.notificationsEnabled, equals(notificationsEnabled),
              reason: 'Boolean notification setting should be preserved');
            expect(user.notificationsEnabled, isA<bool>(),
              reason: 'Notifications should be boolean type');

            // Verify enum-like values are preserved
            expect(user.role, equals(role),
              reason: 'Role should be preserved: "$role"');
            expect(user.language, equals(language),
              reason: 'Language should be preserved: "$language"');

            // Verify enum values are valid
            expect(roles.contains(user.role), isTrue,
              reason: 'Role should be valid enum value');
            expect(languages.contains(user.language), isTrue,
              reason: 'Language should be valid enum value');
          }
        },
        iterations: 1, // Run once with controlled test cases
      );
    });

    group('Real-time Update Validation', () {
      test('Data updates should be immediately reflected', () async {
        final userId = 'test_user';
        
        // Initial data
        final initialData = {
          'uid': userId,
          'display_name': 'Initial Name',
          'email': 'initial@isetcom.tn',
          'nom': 'Initial Name',
          'pocket': 25.0,
          'tickets': 3,
          'role': 'student',
          'language': 'fr',
          'notifications_enabled': true,
          'created_time': Timestamp.fromDate(DateTime.now()),
        };

        await fakeFirestore.collection('user').doc(userId).set(initialData);

        // Get initial user
        var doc = await fakeFirestore.collection('user').doc(userId).get();
        var user = UserRecord.fromSnapshot(doc);

        expect(user.nom, equals('Initial Name'));
        expect(user.pocket, equals(25.0));
        expect(user.tickets, equals(3));

        // Update data
        await fakeFirestore.collection('user').doc(userId).update({
          'nom': 'Updated Name',
          'pocket': 50.0,
          'tickets': 7,
        });

        // Get updated user
        doc = await fakeFirestore.collection('user').doc(userId).get();
        user = UserRecord.fromSnapshot(doc);

        // Verify updates are immediately available
        expect(user.nom, equals('Updated Name'),
          reason: 'Updated name should be immediately available');
        expect(user.pocket, equals(50.0),
          reason: 'Updated pocket should be immediately available');
        expect(user.tickets, equals(7),
          reason: 'Updated tickets should be immediately available');

        // Verify non-updated fields remain unchanged
        expect(user.email, equals('initial@isetcom.tn'),
          reason: 'Non-updated fields should remain unchanged');
        expect(user.role, equals('student'),
          reason: 'Non-updated role should remain unchanged');
      });

      test('Stale data should be detected', () {
        final lastSyncTime = DateTime.now().subtract(Duration(minutes: 10));
        
        // Data older than 5 minutes should be considered stale
        final isStale = validationService.isDataStale(lastSyncTime, maxAge: Duration(minutes: 5));
        
        expect(isStale, isTrue, reason: 'Data older than max age should be stale');

        // Recent data should not be stale
        final recentSyncTime = DateTime.now().subtract(Duration(minutes: 2));
        final isRecentStale = validationService.isDataStale(recentSyncTime, maxAge: Duration(minutes: 5));
        
        expect(isRecentStale, isFalse, reason: 'Recent data should not be stale');

        // Null sync time should be considered stale
        final isNullStale = validationService.isDataStale(null);
        
        expect(isNullStale, isTrue, reason: 'Null sync time should be considered stale');
      });
    });

    group('Comprehensive Data Validation', () {
      testProperty(
        'All user-related data should be consistent across collections',
        () async {
          final random = Random();
          final userId = 'user_${random.nextInt(10000)}';
          
          // Create comprehensive test data
          final userData = {
            'uid': userId,
            'display_name': 'Test User ${random.nextInt(1000)}',
            'email': 'user${random.nextInt(1000)}@isetcom.tn',
            'nom': 'Nom Test ${random.nextInt(1000)}',
            'pocket': (random.nextDouble() * 100).roundToDouble(),
            'tickets': random.nextInt(10),
            'role': 'student',
            'language': 'fr',
            'notifications_enabled': random.nextBool(),
            'created_time': Timestamp.fromDate(DateTime.now()),
          };

          await fakeFirestore.collection('user').doc(userId).set(userData);

          // Create test reservations
          final reservations = <ReservationRecord>[];
          for (int i = 0; i < random.nextInt(3) + 1; i++) {
            final reservationData = {
              'userId': userId,
              'status': 'confirmed',
              'creneaux': Timestamp.fromDate(DateTime.now().add(Duration(hours: i + 1))),
              'createdAt': Timestamp.fromDate(DateTime.now()),
            };
            
            await fakeFirestore.collection('reservation').add(reservationData);
          }

          // Create test menu
          final menu = <PlatRecord>[];
          for (int i = 0; i < random.nextInt(3) + 1; i++) {
            final platData = {
              'nom': 'Plat ${i + 1}',
              'prix': (random.nextDouble() * 20 + 5).roundToDouble(),
              'description': 'Description du plat ${i + 1}',
              'isActive': true,
              'availableDate': Timestamp.fromDate(DateTime.now()),
            };
            
            await fakeFirestore.collection('plat').add(platData);
          }

          // Get user and validate
          final doc = await fakeFirestore.collection('user').doc(userId).get();
          final user = UserRecord.fromSnapshot(doc);

          final validation = await validationService.validateAllUserData(
            user,
            reservations,
            menu,
            [], // Empty time slots for this test
            DateTime.now(),
          );

          // User validation should pass
          expect(validation.userValidation.isValid, isTrue,
            reason: 'User validation should pass: ${validation.userValidation.errors}');

          // Hardcoded data validation should pass for real data
          expect(validation.hardcodedDataValidation.isValid, isTrue,
            reason: 'Hardcoded data validation should pass: ${validation.hardcodedDataValidation.errors}');
        },
        iterations: 25,
      );
    });
  });
}

/// Helper function for property-based testing
void testProperty(String description, Future<void> Function() testFunction, {int iterations = 100}) {
  group(description, () {
    for (int i = 0; i < iterations; i++) {
      test('Iteration ${i + 1}', () async {
        await testFunction();
      });
    }
  });
}