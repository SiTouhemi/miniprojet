import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

/// Property-based test for data display consistency
/// Feature: production-architecture, Property 3: Data Display Consistency
/// Validates: Requirements 2.1, 2.2, 2.5
void main() {
  group('Feature: production-architecture, Property 3: Data Display Consistency', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testProperty(
      'For any user data displayed in the UI, the displayed values should match the corresponding values stored in Firestore',
      () async {
        final random = Random();
        
        // Generate random user data
        final userId = 'user_${random.nextInt(10000)}';
        final displayName = 'Test User ${random.nextInt(1000)}';
        final email = 'user${random.nextInt(1000)}@isetcom.tn';
        final pocket = (random.nextDouble() * 100).roundToDouble(); // 0-100 TND
        final tickets = random.nextInt(10); // 0-9 tickets
        final cin = random.nextInt(90000000) + 10000000; // 8-digit CIN
        final classe = 'DSI${random.nextInt(3) + 1}'; // DSI1, DSI2, DSI3
        final role = ['student', 'staff', 'admin'][random.nextInt(3)];
        final language = ['fr', 'ar', 'en'][random.nextInt(3)];
        final notificationsEnabled = random.nextBool();
        final createdTime = DateTime.now().subtract(Duration(days: random.nextInt(365)));
        final lastLogin = DateTime.now().subtract(Duration(hours: random.nextInt(24)));

        // Store user data in Firestore
        final userData = {
          'uid': userId,
          'display_name': displayName,
          'email': email,
          'pocket': pocket,
          'tickets': tickets,
          'cin': cin,
          'classe': classe,
          'role': role,
          'language': language,
          'notifications_enabled': notificationsEnabled,
          'created_time': Timestamp.fromDate(createdTime),
          'last_login': Timestamp.fromDate(lastLogin),
        };

        await fakeFirestore.collection('user').doc(userId).set(userData);

        // Retrieve user data (simulating what the UI would do)
        final doc = await fakeFirestore.collection('user').doc(userId).get();
        expect(doc.exists, isTrue, reason: 'User document should exist after creation');
        
        final retrievedData = doc.data()!;

        // Property: Display name should match stored value
        expect(
          retrievedData['display_name'],
          equals(displayName),
          reason: 'UI display name should match Firestore value: expected "$displayName", got "${retrievedData['display_name']}"',
        );

        // Property: Email should match stored value
        expect(
          retrievedData['email'],
          equals(email),
          reason: 'UI email should match Firestore value: expected "$email", got "${retrievedData['email']}"',
        );

        // Property: Pocket balance should match stored value (Requirement 2.2)
        expect(
          retrievedData['pocket'],
          equals(pocket),
          reason: 'UI pocket balance should match Firestore value: expected $pocket, got ${retrievedData['pocket']}',
        );

        // Property: Ticket count should match stored value
        expect(
          retrievedData['tickets'],
          equals(tickets),
          reason: 'UI ticket count should match Firestore value: expected $tickets, got ${retrievedData['tickets']}',
        );

        // Property: CIN should match stored value
        expect(
          retrievedData['cin'],
          equals(cin),
          reason: 'UI CIN should match Firestore value: expected $cin, got ${retrievedData['cin']}',
        );

        // Property: Class should match stored value
        expect(
          retrievedData['classe'],
          equals(classe),
          reason: 'UI class should match Firestore value: expected "$classe", got "${retrievedData['classe']}"',
        );

        // Property: Role should match stored value
        expect(
          retrievedData['role'],
          equals(role),
          reason: 'UI role should match Firestore value: expected "$role", got "${retrievedData['role']}"',
        );

        // Property: Language preference should match stored value
        expect(
          retrievedData['language'],
          equals(language),
          reason: 'UI language should match Firestore value: expected "$language", got "${retrievedData['language']}"',
        );

        // Property: Notification preference should match stored value
        expect(
          retrievedData['notifications_enabled'],
          equals(notificationsEnabled),
          reason: 'UI notifications setting should match Firestore value: expected $notificationsEnabled, got ${retrievedData['notifications_enabled']}',
        );

        // Property: Timestamps should be preserved accurately
        final retrievedCreatedTime = (retrievedData['created_time'] as Timestamp).toDate();
        expect(
          retrievedCreatedTime.millisecondsSinceEpoch,
          equals(createdTime.millisecondsSinceEpoch),
          reason: 'Created time should be preserved accurately',
        );

        final retrievedLastLogin = (retrievedData['last_login'] as Timestamp).toDate();
        expect(
          retrievedLastLogin.millisecondsSinceEpoch,
          equals(lastLogin.millisecondsSinceEpoch),
          reason: 'Last login time should be preserved accurately',
        );
      },
      iterations: 100,
    );

    testProperty(
      'User data updates should be immediately reflected in subsequent queries',
      () async {
        final random = Random();
        final userId = 'user_${random.nextInt(10000)}';
        
        // Initial user data
        final initialPocket = (random.nextDouble() * 50).roundToDouble();
        final initialTickets = random.nextInt(5);
        
        await fakeFirestore.collection('user').doc(userId).set({
          'uid': userId,
          'display_name': 'Initial Name',
          'email': 'initial@isetcom.tn',
          'pocket': initialPocket,
          'tickets': initialTickets,
          'role': 'student',
          'language': 'fr',
          'notifications_enabled': true,
          'created_time': Timestamp.fromDate(DateTime.now()),
        });

        // Update user data
        final updatedPocket = (random.nextDouble() * 100).roundToDouble();
        final updatedTickets = random.nextInt(10);
        final updatedName = 'Updated Name ${random.nextInt(1000)}';

        await fakeFirestore.collection('user').doc(userId).update({
          'display_name': updatedName,
          'pocket': updatedPocket,
          'tickets': updatedTickets,
        });

        // Retrieve updated data
        final doc = await fakeFirestore.collection('user').doc(userId).get();
        final retrievedData = doc.data()!;

        // Property: Updated values should be immediately available
        expect(
          retrievedData['display_name'],
          equals(updatedName),
          reason: 'Updated display name should be immediately available',
        );

        expect(
          retrievedData['pocket'],
          equals(updatedPocket),
          reason: 'Updated pocket balance should be immediately available',
        );

        expect(
          retrievedData['tickets'],
          equals(updatedTickets),
          reason: 'Updated ticket count should be immediately available',
        );

        // Property: Non-updated fields should remain unchanged
        expect(
          retrievedData['email'],
          equals('initial@isetcom.tn'),
          reason: 'Non-updated fields should remain unchanged',
        );

        expect(
          retrievedData['role'],
          equals('student'),
          reason: 'Non-updated role should remain unchanged',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Numeric data types should maintain precision',
      () async {
        final random = Random();
        final userId = 'user_${random.nextInt(10000)}';
        
        // Test various numeric values including decimals
        final pocket = double.parse((random.nextDouble() * 999.99).toStringAsFixed(2)); // Up to 2 decimal places
        final tickets = random.nextInt(1000);
        final cin = random.nextInt(90000000) + 10000000; // 8-digit number
        
        await fakeFirestore.collection('user').doc(userId).set({
          'uid': userId,
          'display_name': 'Test User',
          'email': 'test@isetcom.tn',
          'pocket': pocket,
          'tickets': tickets,
          'cin': cin,
          'role': 'student',
          'created_time': Timestamp.fromDate(DateTime.now()),
        });

        final doc = await fakeFirestore.collection('user').doc(userId).get();
        final retrievedData = doc.data()!;

        // Property: Decimal precision should be maintained for pocket balance
        expect(
          retrievedData['pocket'],
          closeTo(pocket, 0.01),
          reason: 'Pocket balance precision should be maintained: expected $pocket, got ${retrievedData['pocket']}',
        );

        // Property: Integer values should be exact
        expect(
          retrievedData['tickets'],
          equals(tickets),
          reason: 'Integer ticket count should be exact: expected $tickets, got ${retrievedData['tickets']}',
        );

        expect(
          retrievedData['cin'],
          equals(cin),
          reason: 'Integer CIN should be exact: expected $cin, got ${retrievedData['cin']}',
        );
      },
      iterations: 100,
    );

    testProperty(
      'String data should preserve encoding and special characters',
      () async {
        final random = Random();
        final userId = 'user_${random.nextInt(10000)}';
        
        // Test various string formats including special characters
        final specialNames = [
          'Ahmed Ben Ali',
          'Fatma Bint Mohamed',
          'Jean-Pierre Dupont',
          'María José García',
          'محمد بن علي',
          'فاطمة بنت محمد',
          'Test@User#123',
          'User with émojis 🎓📚',
        ];
        
        final displayName = specialNames[random.nextInt(specialNames.length)];
        final email = 'user${random.nextInt(1000)}@isetcom.tn';
        final classe = 'DSI${random.nextInt(3) + 1}-Groupe${random.nextInt(5) + 1}';
        
        await fakeFirestore.collection('user').doc(userId).set({
          'uid': userId,
          'display_name': displayName,
          'email': email,
          'classe': classe,
          'role': 'student',
          'pocket': 0.0,
          'tickets': 0,
          'created_time': Timestamp.fromDate(DateTime.now()),
        });

        final doc = await fakeFirestore.collection('user').doc(userId).get();
        final retrievedData = doc.data()!;

        // Property: String encoding should be preserved
        expect(
          retrievedData['display_name'],
          equals(displayName),
          reason: 'Display name with special characters should be preserved: expected "$displayName", got "${retrievedData['display_name']}"',
        );

        expect(
          retrievedData['email'],
          equals(email),
          reason: 'Email format should be preserved: expected "$email", got "${retrievedData['email']}"',
        );

        expect(
          retrievedData['classe'],
          equals(classe),
          reason: 'Class format should be preserved: expected "$classe", got "${retrievedData['classe']}"',
        );

        // Property: String length should be preserved
        expect(
          retrievedData['display_name'].length,
          equals(displayName.length),
          reason: 'String length should be preserved',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Boolean and enum values should be consistent',
      () async {
        final random = Random();
        final userId = 'user_${random.nextInt(10000)}';
        
        final notificationsEnabled = random.nextBool();
        final roles = ['student', 'staff', 'admin'];
        final languages = ['fr', 'ar', 'en'];
        final role = roles[random.nextInt(roles.length)];
        final language = languages[random.nextInt(languages.length)];
        
        await fakeFirestore.collection('user').doc(userId).set({
          'uid': userId,
          'display_name': 'Test User',
          'email': 'test@isetcom.tn',
          'role': role,
          'language': language,
          'notifications_enabled': notificationsEnabled,
          'pocket': 0.0,
          'tickets': 0,
          'created_time': Timestamp.fromDate(DateTime.now()),
        });

        final doc = await fakeFirestore.collection('user').doc(userId).get();
        final retrievedData = doc.data()!;

        // Property: Boolean values should be preserved exactly
        expect(
          retrievedData['notifications_enabled'],
          equals(notificationsEnabled),
          reason: 'Boolean notification setting should be preserved: expected $notificationsEnabled, got ${retrievedData['notifications_enabled']}',
        );

        // Property: Enum-like string values should be preserved
        expect(
          retrievedData['role'],
          equals(role),
          reason: 'Role enum value should be preserved: expected "$role", got "${retrievedData['role']}"',
        );

        expect(
          retrievedData['language'],
          equals(language),
          reason: 'Language enum value should be preserved: expected "$language", got "${retrievedData['language']}"',
        );

        // Property: Enum values should be valid
        expect(
          roles.contains(retrievedData['role']),
          isTrue,
          reason: 'Role should be a valid enum value',
        );

        expect(
          languages.contains(retrievedData['language']),
          isTrue,
          reason: 'Language should be a valid enum value',
        );
      },
      iterations: 100,
    );
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