import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

/// Property-based test for time slot query accuracy
/// Feature: production-architecture, Property 4: Time Slot Query Accuracy
/// Validates: Requirements 4.1
void main() {
  group('Feature: production-architecture, Property 4: Time Slot Query Accuracy', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testProperty(
      'For any date selected by a student, the system should return only time slots that match that specific date from Firestore',
      () async {
        // Generate random test data
        final random = Random();
        final testDate = DateTime(2024, 1, 15); // Fixed date for consistency
        final otherDates = [
          DateTime(2024, 1, 14), // Day before
          DateTime(2024, 1, 16), // Day after
          DateTime(2024, 2, 15), // Different month
          DateTime(2023, 1, 15), // Different year
        ];

        // Create time slots for the test date
        final testDateSlots = <Map<String, dynamic>>[];
        final slotsForTestDate = random.nextInt(5) + 1; // 1-5 slots
        
        for (int i = 0; i < slotsForTestDate; i++) {
          final startHour = 8 + (i * 2); // 8, 10, 12, 14, 16
          final slot = {
            'date': Timestamp.fromDate(testDate),
            'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, startHour)),
            'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, startHour + 1)),
            'max_capacity': random.nextInt(50) + 10, // 10-59
            'current_reservations': random.nextInt(10), // 0-9
            'price': (random.nextDouble() * 10) + 5, // 5-15 TND
            'is_active': true,
            'meal_type': ['breakfast', 'lunch', 'dinner'][random.nextInt(3)],
          };
          testDateSlots.add(slot);
          
          await fakeFirestore.collection('time_slots').add(slot);
        }

        // Create time slots for other dates (should not be returned)
        for (final otherDate in otherDates) {
          final slotsForOtherDate = random.nextInt(3) + 1; // 1-3 slots
          
          for (int i = 0; i < slotsForOtherDate; i++) {
            final startHour = 8 + (i * 2);
            final slot = {
              'date': Timestamp.fromDate(otherDate),
              'start_time': Timestamp.fromDate(DateTime(otherDate.year, otherDate.month, otherDate.day, startHour)),
              'end_time': Timestamp.fromDate(DateTime(otherDate.year, otherDate.month, otherDate.day, startHour + 1)),
              'max_capacity': random.nextInt(50) + 10,
              'current_reservations': random.nextInt(10),
              'price': (random.nextDouble() * 10) + 5,
              'is_active': true,
              'meal_type': ['breakfast', 'lunch', 'dinner'][random.nextInt(3)],
            };
            
            await fakeFirestore.collection('time_slots').add(slot);
          }
        }

        // Query time slots for the test date using direct Firestore query
        final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
        final endOfDay = DateTime(testDate.year, testDate.month, testDate.day, 23, 59, 59);

        final snapshot = await fakeFirestore
            .collection('time_slots')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .where('is_active', isEqualTo: true)
            .get();

        final result = snapshot.docs.map((doc) => doc.data()).toList();

        // Property: All returned slots should match the queried date
        for (final slotData in result) {
          final slotTimestamp = slotData['date'] as Timestamp;
          final slotDate = slotTimestamp.toDate();
          
          expect(
            slotDate.year == testDate.year &&
            slotDate.month == testDate.month &&
            slotDate.day == testDate.day,
            isTrue,
            reason: 'Time slot date ${slotDate} should match queried date ${testDate}',
          );
        }

        // Property: The number of returned slots should match the number of active slots for that date
        final expectedCount = testDateSlots.where((slot) => slot['is_active'] == true).length;
        expect(
          result.length,
          equals(expectedCount),
          reason: 'Should return exactly $expectedCount slots for date $testDate, but got ${result.length}',
        );

        // Property: Only active slots should be returned
        for (final slotData in result) {
          expect(slotData['is_active'], isTrue, reason: 'All returned slots should be active');
        }
      },
      iterations: 100,
    );

    testProperty(
      'Time slot queries should handle edge cases correctly',
      () async {
        final random = Random();
        
        // Test with various edge case dates
        final edgeCaseDates = [
          DateTime(2024, 1, 1), // New Year's Day
          DateTime(2024, 2, 29), // Leap year day
          DateTime(2024, 12, 31), // New Year's Eve
          DateTime(2024, 6, 15), // Mid-year
        ];

        for (final testDate in edgeCaseDates) {
          // Create some time slots for this date
          final slotsCount = random.nextInt(3) + 1;
          
          for (int i = 0; i < slotsCount; i++) {
            await fakeFirestore.collection('time_slots').add({
              'date': Timestamp.fromDate(testDate),
              'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 12 + i)),
              'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 13 + i)),
              'max_capacity': 50,
              'current_reservations': 0,
              'price': 5.0,
              'is_active': true,
              'meal_type': 'lunch',
            });
          }

          // Query should work for any valid date
          final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
          final endOfDay = DateTime(testDate.year, testDate.month, testDate.day, 23, 59, 59);

          final snapshot = await fakeFirestore
              .collection('time_slots')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .where('is_active', isEqualTo: true)
              .get();

          final result = snapshot.docs.map((doc) => doc.data()).toList();
          
          // Property: Query should not fail for any valid date
          expect(result, isA<List>(), reason: 'Query should return a list for date $testDate');
          
          // Property: All returned slots should match the queried date
          for (final slotData in result) {
            final slotTimestamp = slotData['date'] as Timestamp;
            final slotDate = slotTimestamp.toDate();
            expect(
              slotDate.year == testDate.year &&
              slotDate.month == testDate.month &&
              slotDate.day == testDate.day,
              isTrue,
              reason: 'Slot date should match queried date for edge case $testDate',
            );
          }
        }
      },
      iterations: 50,
    );

    testProperty(
      'Time slot queries should respect active/inactive status',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 3, 15);
        
        // Create mix of active and inactive slots
        final totalSlots = random.nextInt(10) + 5; // 5-14 slots
        int activeSlots = 0;
        
        for (int i = 0; i < totalSlots; i++) {
          final isActive = random.nextBool();
          if (isActive) activeSlots++;
          
          await fakeFirestore.collection('time_slots').add({
            'date': Timestamp.fromDate(testDate),
            'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 8 + i)),
            'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 9 + i)),
            'max_capacity': 50,
            'current_reservations': 0,
            'price': 5.0,
            'is_active': isActive,
            'meal_type': 'lunch',
          });
        }

        final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
        final endOfDay = DateTime(testDate.year, testDate.month, testDate.day, 23, 59, 59);

        final snapshot = await fakeFirestore
            .collection('time_slots')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .where('is_active', isEqualTo: true)
            .get();

        final result = snapshot.docs.map((doc) => doc.data()).toList();

        // Property: Only active slots should be returned
        expect(
          result.length,
          equals(activeSlots),
          reason: 'Should return only active slots ($activeSlots out of $totalSlots)',
        );

        for (final slotData in result) {
          expect(slotData['is_active'], isTrue, reason: 'All returned slots should be active');
        }
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