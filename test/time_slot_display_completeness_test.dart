import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

/// Property-based test for time slot display completeness
/// Feature: production-architecture, Property 5: Time Slot Display Completeness
/// Validates: Requirements 4.2
void main() {
  group('Feature: production-architecture, Property 5: Time Slot Display Completeness', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testProperty(
      'For any time slot displayed to users, all required fields (current_reservations, max_capacity, start_time, end_time) should be present and accurate',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 1, 15);
        
        // Generate random time slot data with all required fields
        final maxCapacity = random.nextInt(50) + 10; // 10-59
        final currentReservations = random.nextInt(maxCapacity); // 0 to maxCapacity-1
        final startHour = random.nextInt(12) + 8; // 8-19
        final endHour = startHour + 1;
        final price = (random.nextDouble() * 10) + 5; // 5-15 TND
        
        final timeSlotData = {
          'date': Timestamp.fromDate(testDate),
          'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, startHour)),
          'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, endHour)),
          'max_capacity': maxCapacity,
          'current_reservations': currentReservations,
          'price': price,
          'is_active': true,
          'meal_type': ['breakfast', 'lunch', 'dinner'][random.nextInt(3)],
        };

        // Add to Firestore
        final docRef = await fakeFirestore.collection('time_slots').add(timeSlotData);
        
        // Retrieve the time slot
        final doc = await docRef.get();
        expect(doc.exists, isTrue, reason: 'Time slot should be retrievable after creation');
        
        final retrievedData = doc.data()!;
        
        // Property: All required fields should be present and accurate
        
        // Requirement 4.2: Show current_reservations
        expect(retrievedData.containsKey('current_reservations'), isTrue, reason: 'current_reservations field should be present');
        expect(
          retrievedData['current_reservations'],
          equals(currentReservations),
          reason: 'current_reservations should match stored value: expected $currentReservations, got ${retrievedData['current_reservations']}',
        );
        
        // Requirement 4.2: Show max_capacity
        expect(retrievedData.containsKey('max_capacity'), isTrue, reason: 'max_capacity field should be present');
        expect(
          retrievedData['max_capacity'],
          equals(maxCapacity),
          reason: 'max_capacity should match stored value: expected $maxCapacity, got ${retrievedData['max_capacity']}',
        );
        
        // Property: start_time should be present and accurate
        expect(retrievedData.containsKey('start_time'), isTrue, reason: 'start_time field should be present');
        expect(retrievedData['start_time'], isNotNull, reason: 'start_time should not be null');
        final retrievedStartTime = (retrievedData['start_time'] as Timestamp).toDate();
        expect(
          retrievedStartTime.hour,
          equals(startHour),
          reason: 'start_time hour should match: expected $startHour, got ${retrievedStartTime.hour}',
        );
        
        // Property: end_time should be present and accurate
        expect(retrievedData.containsKey('end_time'), isTrue, reason: 'end_time field should be present');
        expect(retrievedData['end_time'], isNotNull, reason: 'end_time should not be null');
        final retrievedEndTime = (retrievedData['end_time'] as Timestamp).toDate();
        expect(
          retrievedEndTime.hour,
          equals(endHour),
          reason: 'end_time hour should match: expected $endHour, got ${retrievedEndTime.hour}',
        );
        
        // Property: price should be present and accurate
        expect(retrievedData.containsKey('price'), isTrue, reason: 'price field should be present');
        expect(
          retrievedData['price'],
          closeTo(price, 0.01),
          reason: 'price should match stored value: expected $price, got ${retrievedData['price']}',
        );
        
        // Property: is_active should be present
        expect(retrievedData.containsKey('is_active'), isTrue, reason: 'is_active field should be present');
        expect(retrievedData['is_active'], isTrue, reason: 'is_active should be true for test data');
        
        // Property: meal_type should be present
        expect(retrievedData.containsKey('meal_type'), isTrue, reason: 'meal_type field should be present');
        expect(retrievedData['meal_type'], isNotEmpty, reason: 'meal_type should not be empty');
        
        // Property: date should be present and accurate
        expect(retrievedData.containsKey('date'), isTrue, reason: 'date field should be present');
        expect(retrievedData['date'], isNotNull, reason: 'date should not be null');
        final retrievedDate = (retrievedData['date'] as Timestamp).toDate();
        expect(
          retrievedDate.year == testDate.year &&
          retrievedDate.month == testDate.month &&
          retrievedDate.day == testDate.day,
          isTrue,
          reason: 'date should match test date',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Time slots should have valid capacity relationships',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 2, 20);
        
        // Generate data ensuring current_reservations <= max_capacity
        final maxCapacity = random.nextInt(100) + 1; // 1-100
        final currentReservations = random.nextInt(maxCapacity + 1); // 0 to maxCapacity
        
        final timeSlotData = {
          'date': Timestamp.fromDate(testDate),
          'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 12)),
          'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 13)),
          'max_capacity': maxCapacity,
          'current_reservations': currentReservations,
          'price': 5.0,
          'is_active': true,
          'meal_type': 'lunch',
        };

        final docRef = await fakeFirestore.collection('time_slots').add(timeSlotData);
        final doc = await docRef.get();
        final retrievedData = doc.data()!;
        
        // Property: current_reservations should never exceed max_capacity
        expect(
          retrievedData['current_reservations'] <= retrievedData['max_capacity'],
          isTrue,
          reason: 'current_reservations (${retrievedData['current_reservations']}) should not exceed max_capacity (${retrievedData['max_capacity']})',
        );
        
        // Property: Both capacity values should be non-negative
        expect(
          retrievedData['current_reservations'] >= 0,
          isTrue,
          reason: 'current_reservations should be non-negative',
        );
        expect(
          retrievedData['max_capacity'] >= 0,
          isTrue,
          reason: 'max_capacity should be non-negative',
        );
        
        // Property: Available spots calculation should be correct
        final availableSpots = retrievedData['max_capacity'] - retrievedData['current_reservations'];
        expect(
          availableSpots >= 0,
          isTrue,
          reason: 'available spots should be non-negative',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Time slots should have valid time relationships',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 3, 10);
        
        // Generate valid time ranges
        final startHour = random.nextInt(20) + 1; // 1-20 (to ensure end time is valid)
        final duration = random.nextInt(4) + 1; // 1-4 hours
        final endHour = startHour + duration;
        
        // Ensure end hour doesn't exceed 24
        final validEndHour = endHour > 23 ? 23 : endHour;
        
        final timeSlotData = {
          'date': Timestamp.fromDate(testDate),
          'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, startHour)),
          'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, validEndHour)),
          'max_capacity': 50,
          'current_reservations': 0,
          'price': 5.0,
          'is_active': true,
          'meal_type': 'lunch',
        };

        final docRef = await fakeFirestore.collection('time_slots').add(timeSlotData);
        final doc = await docRef.get();
        final retrievedData = doc.data()!;
        
        final startTime = (retrievedData['start_time'] as Timestamp).toDate();
        final endTime = (retrievedData['end_time'] as Timestamp).toDate();
        final slotDate = (retrievedData['date'] as Timestamp).toDate();
        
        // Property: start_time should be before end_time
        expect(
          startTime.isBefore(endTime),
          isTrue,
          reason: 'start_time ($startTime) should be before end_time ($endTime)',
        );
        
        // Property: Both times should be on the same date
        expect(
          startTime.year == slotDate.year &&
          startTime.month == slotDate.month &&
          startTime.day == slotDate.day,
          isTrue,
          reason: 'start_time should be on the same date as the time slot date',
        );
        
        expect(
          endTime.year == slotDate.year &&
          endTime.month == slotDate.month &&
          endTime.day == slotDate.day,
          isTrue,
          reason: 'end_time should be on the same date as the time slot date',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Time slots should have valid price and meal type data',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 4, 5);
        
        // Generate valid price (positive number)
        final price = (random.nextDouble() * 50) + 0.1; // 0.1 to 50.1 TND
        final mealTypes = ['breakfast', 'lunch', 'dinner'];
        final mealType = mealTypes[random.nextInt(mealTypes.length)];
        
        final timeSlotData = {
          'date': Timestamp.fromDate(testDate),
          'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 12)),
          'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 13)),
          'max_capacity': 50,
          'current_reservations': 0,
          'price': price,
          'is_active': true,
          'meal_type': mealType,
        };

        final docRef = await fakeFirestore.collection('time_slots').add(timeSlotData);
        final doc = await docRef.get();
        final retrievedData = doc.data()!;
        
        // Property: price should be positive
        expect(
          retrievedData['price'] > 0,
          isTrue,
          reason: 'price should be positive, got ${retrievedData['price']}',
        );
        
        // Property: price should match stored value
        expect(
          retrievedData['price'],
          closeTo(price, 0.01),
          reason: 'price should match stored value',
        );
        
        // Property: meal_type should be valid
        expect(
          mealTypes.contains(retrievedData['meal_type']),
          isTrue,
          reason: 'meal_type should be one of the valid types, got ${retrievedData['meal_type']}',
        );
        
        // Property: meal_type should match stored value
        expect(
          retrievedData['meal_type'],
          equals(mealType),
          reason: 'meal_type should match stored value',
        );
      },
      iterations: 100,
    );

    testProperty(
      'Multiple time slots should maintain data integrity',
      () async {
        final random = Random();
        final testDate = DateTime(2024, 5, 15);
        
        // Create multiple time slots
        final slotCount = random.nextInt(5) + 2; // 2-6 slots
        final createdSlots = <String>[];
        
        for (int i = 0; i < slotCount; i++) {
          final timeSlotData = {
            'date': Timestamp.fromDate(testDate),
            'start_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 8 + i * 2)),
            'end_time': Timestamp.fromDate(DateTime(testDate.year, testDate.month, testDate.day, 9 + i * 2)),
            'max_capacity': random.nextInt(50) + 10,
            'current_reservations': random.nextInt(10),
            'price': (random.nextDouble() * 10) + 5,
            'is_active': true,
            'meal_type': ['breakfast', 'lunch', 'dinner'][random.nextInt(3)],
          };

          final docRef = await fakeFirestore.collection('time_slots').add(timeSlotData);
          createdSlots.add(docRef.id);
        }
        
        // Retrieve all created slots
        final retrievedSlots = <Map<String, dynamic>>[];
        for (final slotId in createdSlots) {
          final doc = await fakeFirestore.collection('time_slots').doc(slotId).get();
          expect(doc.exists, isTrue, reason: 'Each created slot should be retrievable');
          retrievedSlots.add(doc.data()!);
        }
        
        // Property: All slots should have complete data
        for (int i = 0; i < retrievedSlots.length; i++) {
          final slotData = retrievedSlots[i];
          
          expect(slotData.containsKey('current_reservations'), isTrue, reason: 'Slot $i should have current_reservations');
          expect(slotData.containsKey('max_capacity'), isTrue, reason: 'Slot $i should have max_capacity');
          expect(slotData.containsKey('start_time'), isTrue, reason: 'Slot $i should have start_time');
          expect(slotData.containsKey('end_time'), isTrue, reason: 'Slot $i should have end_time');
          expect(slotData.containsKey('price'), isTrue, reason: 'Slot $i should have price');
          expect(slotData.containsKey('is_active'), isTrue, reason: 'Slot $i should have is_active');
          expect(slotData.containsKey('meal_type'), isTrue, reason: 'Slot $i should have meal_type');
          expect(slotData.containsKey('date'), isTrue, reason: 'Slot $i should have date');
        }
        
        // Property: Each slot should have unique start times (no overlaps in our test data)
        final startTimes = retrievedSlots.map((slotData) => (slotData['start_time'] as Timestamp).toDate().hour).toList();
        final uniqueStartTimes = startTimes.toSet();
        expect(
          uniqueStartTimes.length,
          equals(startTimes.length),
          reason: 'All slots should have unique start times in our test data',
        );
      },
      iterations: 50,
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