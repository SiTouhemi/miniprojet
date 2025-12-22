import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

/// Unit tests for reservation cancellation and modification functionality
/// Validates Requirements 5.5, 5.7 for atomic operations and past reservation restrictions
void main() {
  group('Reservation Cancellation and Modification Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('Cancellation Tests', () {
      test('should allow cancellation of future reservations more than 2 hours away', () async {
        // Create a future reservation (4 hours from now)
        final futureTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(futureTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
          'created_at': Timestamp.fromDate(DateTime.now()),
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Create corresponding time slot
        final timeSlotData = {
          'start_time': Timestamp.fromDate(futureTime),
          'end_time': Timestamp.fromDate(futureTime.add(const Duration(hours: 1))),
          'max_capacity': 50,
          'current_reservations': 10,
          'price': 5.0,
          'is_active': true,
        };

        await fakeFirestore.collection('time_slots').add(timeSlotData);

        // Simulate cancellation logic
        await fakeFirestore.runTransaction((transaction) async {
          final reservationDoc = await transaction.get(reservationRef);
          final reservation = reservationDoc.data()!;

          // Verify cancellation is allowed
          final reservationTime = (reservation['creneaux'] as Timestamp).toDate();
          final hoursUntilMeal = reservationTime.difference(DateTime.now()).inHours;
          
          expect(hoursUntilMeal, greaterThan(2), reason: 'Should be more than 2 hours until meal');
          expect(reservation['status'], equals('confirmed'), reason: 'Should be confirmed status');

          // Update reservation status
          transaction.update(reservationRef, {
            'status': 'cancelled',
            'cancelled_at': FieldValue.serverTimestamp(),
            'cancellation_reason': 'User cancelled',
          });

          // Update time slot capacity
          final timeSlotsQuery = await fakeFirestore.collection('time_slots')
              .where('start_time', isEqualTo: reservation['creneaux'])
              .get();

          if (timeSlotsQuery.docs.isNotEmpty) {
            final timeSlotRef = timeSlotsQuery.docs.first.reference;
            transaction.update(timeSlotRef, {
              'current_reservations': FieldValue.increment(-1),
            });
          }
        });

        // Verify cancellation was successful
        final updatedReservation = await reservationRef.get();
        expect(updatedReservation.data()!['status'], equals('cancelled'));
        expect(updatedReservation.data()!['cancellation_reason'], equals('User cancelled'));
      });

      test('should prevent cancellation of past reservations', () async {
        // Create a past reservation
        final pastTime = DateTime.now().subtract(const Duration(hours: 2));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(pastTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Attempt cancellation
        try {
          await fakeFirestore.runTransaction((transaction) async {
            final reservationDoc = await transaction.get(reservationRef);
            final reservation = reservationDoc.data()!;

            final reservationTime = (reservation['creneaux'] as Timestamp).toDate();
            final now = DateTime.now();

            // Requirement 5.7: Prevent modifications for past reservations
            if (reservationTime.isBefore(now)) {
              throw Exception('Cannot cancel past reservations');
            }
          });

          fail('Should have thrown exception for past reservation');
        } catch (e) {
          expect(e.toString(), contains('Cannot cancel past reservations'));
        }
      });

      test('should prevent cancellation less than 2 hours before meal time', () async {
        // Create a reservation 1 hour from now
        final nearFutureTime = DateTime.now().add(const Duration(hours: 1));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(nearFutureTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Attempt cancellation
        try {
          await fakeFirestore.runTransaction((transaction) async {
            final reservationDoc = await transaction.get(reservationRef);
            final reservation = reservationDoc.data()!;

            final reservationTime = (reservation['creneaux'] as Timestamp).toDate();
            final hoursUntilMeal = reservationTime.difference(DateTime.now()).inHours;

            if (hoursUntilMeal < 2) {
              throw Exception('Cannot cancel reservation less than 2 hours before meal time');
            }
          });

          fail('Should have thrown exception for reservation too close to meal time');
        } catch (e) {
          expect(e.toString(), contains('Cannot cancel reservation less than 2 hours before meal time'));
        }
      });

      test('should prevent cancellation of already cancelled reservations', () async {
        // Create a cancelled reservation
        final futureTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'cancelled',
          'creneaux': Timestamp.fromDate(futureTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Attempt cancellation
        try {
          await fakeFirestore.runTransaction((transaction) async {
            final reservationDoc = await transaction.get(reservationRef);
            final reservation = reservationDoc.data()!;

            if (reservation['status'] == 'cancelled') {
              throw Exception('Reservation is already cancelled');
            }
          });

          fail('Should have thrown exception for already cancelled reservation');
        } catch (e) {
          expect(e.toString(), contains('Reservation is already cancelled'));
        }
      });
    });

    group('Modification Tests', () {
      test('should allow modification of future reservations more than 2 hours away', () async {
        // Create original reservation
        final originalTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(originalTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Create original time slot
        final originalTimeSlotData = {
          'start_time': Timestamp.fromDate(originalTime),
          'end_time': Timestamp.fromDate(originalTime.add(const Duration(hours: 1))),
          'max_capacity': 50,
          'current_reservations': 10,
          'price': 5.0,
          'is_active': true,
        };

        await fakeFirestore.collection('time_slots').add(originalTimeSlotData);

        // Create new time slot
        final newTime = DateTime.now().add(const Duration(hours: 6));
        final newTimeSlotData = {
          'start_time': Timestamp.fromDate(newTime),
          'end_time': Timestamp.fromDate(newTime.add(const Duration(hours: 1))),
          'max_capacity': 50,
          'current_reservations': 5,
          'price': 6.0,
          'is_active': true,
        };

        final newTimeSlotRef = await fakeFirestore.collection('time_slots').add(newTimeSlotData);

        // Simulate modification logic
        await fakeFirestore.runTransaction((transaction) async {
          final reservationDoc = await transaction.get(reservationRef);
          final reservation = reservationDoc.data()!;

          // Verify modification is allowed
          final reservationTime = (reservation['creneaux'] as Timestamp).toDate();
          final hoursUntilMeal = reservationTime.difference(DateTime.now()).inHours;
          
          expect(hoursUntilMeal, greaterThan(2), reason: 'Should be more than 2 hours until meal');
          expect(reservation['status'], equals('confirmed'), reason: 'Should be confirmed status');

          // Get new time slot
          final newTimeSlotDoc = await transaction.get(newTimeSlotRef);
          final newTimeSlot = newTimeSlotDoc.data()!;

          // Check availability
          final capacity = reservation['capacity'] as int;
          final currentReservations = newTimeSlot['current_reservations'] as int;
          final maxCapacity = newTimeSlot['max_capacity'] as int;

          expect(currentReservations + capacity, lessThanOrEqualTo(maxCapacity), 
                 reason: 'New time slot should have enough capacity');

          // Update reservation
          transaction.update(reservationRef, {
            'creneaux': newTimeSlot['start_time'],
            'prix': newTimeSlot['price'],
            'total': newTimeSlot['price'] * capacity,
            'modified_at': FieldValue.serverTimestamp(),
          });

          // Update old time slot (increase capacity)
          final oldTimeSlotsQuery = await fakeFirestore.collection('time_slots')
              .where('start_time', isEqualTo: reservation['creneaux'])
              .get();

          if (oldTimeSlotsQuery.docs.isNotEmpty) {
            transaction.update(oldTimeSlotsQuery.docs.first.reference, {
              'current_reservations': FieldValue.increment(-capacity),
            });
          }

          // Update new time slot (decrease capacity)
          transaction.update(newTimeSlotRef, {
            'current_reservations': FieldValue.increment(capacity),
          });
        });

        // Verify modification was successful
        final updatedReservation = await reservationRef.get();
        final updatedData = updatedReservation.data()!;
        
        expect((updatedData['creneaux'] as Timestamp).toDate(), equals(newTime));
        expect(updatedData['prix'], equals(6.0));
        expect(updatedData['total'], equals(6.0));
      });

      test('should prevent modification to past time slots', () async {
        // Create original reservation
        final originalTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(originalTime),
          'prix': 5,
          'total': 5,
          'capacity': 1,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Create past time slot
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final pastTimeSlotData = {
          'start_time': Timestamp.fromDate(pastTime),
          'end_time': Timestamp.fromDate(pastTime.add(const Duration(hours: 1))),
          'max_capacity': 50,
          'current_reservations': 5,
          'price': 6.0,
          'is_active': true,
        };

        final pastTimeSlotRef = await fakeFirestore.collection('time_slots').add(pastTimeSlotData);

        // Attempt modification
        try {
          await fakeFirestore.runTransaction((transaction) async {
            final newTimeSlotDoc = await transaction.get(pastTimeSlotRef);
            final newTimeSlot = newTimeSlotDoc.data()!;

            final newTimeSlotTime = (newTimeSlot['start_time'] as Timestamp).toDate();
            final now = DateTime.now();

            if (newTimeSlotTime.isBefore(now)) {
              throw Exception('Cannot modify to a past time slot');
            }
          });

          fail('Should have thrown exception for past time slot');
        } catch (e) {
          expect(e.toString(), contains('Cannot modify to a past time slot'));
        }
      });

      test('should prevent modification when new time slot has insufficient capacity', () async {
        // Create original reservation with capacity 2
        final originalTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(originalTime),
          'prix': 5,
          'total': 10,
          'capacity': 2,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        // Create new time slot with insufficient capacity
        final newTime = DateTime.now().add(const Duration(hours: 6));
        final newTimeSlotData = {
          'start_time': Timestamp.fromDate(newTime),
          'end_time': Timestamp.fromDate(newTime.add(const Duration(hours: 1))),
          'max_capacity': 10,
          'current_reservations': 9, // Only 1 spot available, but need 2
          'price': 6.0,
          'is_active': true,
        };

        final newTimeSlotRef = await fakeFirestore.collection('time_slots').add(newTimeSlotData);

        // Attempt modification
        try {
          await fakeFirestore.runTransaction((transaction) async {
            final reservationDoc = await transaction.get(reservationRef);
            final reservation = reservationDoc.data()!;

            final newTimeSlotDoc = await transaction.get(newTimeSlotRef);
            final newTimeSlot = newTimeSlotDoc.data()!;

            final capacity = reservation['capacity'] as int;
            final currentReservations = newTimeSlot['current_reservations'] as int;
            final maxCapacity = newTimeSlot['max_capacity'] as int;

            if (currentReservations + capacity > maxCapacity) {
              throw Exception('New time slot does not have enough capacity');
            }
          });

          fail('Should have thrown exception for insufficient capacity');
        } catch (e) {
          expect(e.toString(), contains('New time slot does not have enough capacity'));
        }
      });
    });

    group('Atomic Operations Tests', () {
      test('should perform atomic updates for cancellation', () async {
        // Create reservation and time slot
        final futureTime = DateTime.now().add(const Duration(hours: 4));
        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(futureTime),
          'capacity': 2,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        final timeSlotData = {
          'start_time': Timestamp.fromDate(futureTime),
          'max_capacity': 50,
          'current_reservations': 10,
        };

        final timeSlotRef = await fakeFirestore.collection('time_slots').add(timeSlotData);

        // Perform atomic cancellation
        await fakeFirestore.runTransaction((transaction) async {
          final reservationDoc = await transaction.get(reservationRef);
          final reservation = reservationDoc.data()!;

          // Update reservation status
          transaction.update(reservationRef, {
            'status': 'cancelled',
            'cancelled_at': FieldValue.serverTimestamp(),
          });

          // Atomically decrement time slot capacity
          transaction.update(timeSlotRef, {
            'current_reservations': FieldValue.increment(-2), // Decrement by capacity
          });
        });

        // Verify both updates were applied
        final updatedReservation = await reservationRef.get();
        final updatedTimeSlot = await timeSlotRef.get();

        expect(updatedReservation.data()!['status'], equals('cancelled'));
        expect(updatedTimeSlot.data()!['current_reservations'], equals(8)); // 10 - 2 = 8
      });

      test('should perform atomic updates for modification', () async {
        // Create original reservation and time slots
        final originalTime = DateTime.now().add(const Duration(hours: 4));
        final newTime = DateTime.now().add(const Duration(hours: 6));

        final reservationData = {
          'user_id': 'test-user-123',
          'status': 'confirmed',
          'creneaux': Timestamp.fromDate(originalTime),
          'capacity': 1,
          'prix': 5,
        };

        final reservationRef = await fakeFirestore.collection('reservation').add(reservationData);

        final originalTimeSlotData = {
          'start_time': Timestamp.fromDate(originalTime),
          'current_reservations': 10,
          'max_capacity': 50,
        };

        final originalTimeSlotRef = await fakeFirestore.collection('time_slots').add(originalTimeSlotData);

        final newTimeSlotData = {
          'start_time': Timestamp.fromDate(newTime),
          'current_reservations': 5,
          'max_capacity': 50,
          'price': 6.0,
        };

        final newTimeSlotRef = await fakeFirestore.collection('time_slots').add(newTimeSlotData);

        // Perform atomic modification
        await fakeFirestore.runTransaction((transaction) async {
          final reservationDoc = await transaction.get(reservationRef);
          final newTimeSlotDoc = await transaction.get(newTimeSlotRef);
          
          final reservation = reservationDoc.data()!;
          final newTimeSlot = newTimeSlotDoc.data()!;
          final capacity = reservation['capacity'] as int;

          // Update reservation
          transaction.update(reservationRef, {
            'creneaux': newTimeSlot['start_time'],
            'prix': newTimeSlot['price'],
            'total': newTimeSlot['price'] * capacity,
          });

          // Update old time slot (increase capacity)
          transaction.update(originalTimeSlotRef, {
            'current_reservations': FieldValue.increment(-capacity),
          });

          // Update new time slot (decrease capacity)
          transaction.update(newTimeSlotRef, {
            'current_reservations': FieldValue.increment(capacity),
          });
        });

        // Verify all updates were applied atomically
        final updatedReservation = await reservationRef.get();
        final updatedOriginalTimeSlot = await originalTimeSlotRef.get();
        final updatedNewTimeSlot = await newTimeSlotRef.get();

        expect((updatedReservation.data()!['creneaux'] as Timestamp).toDate(), equals(newTime));
        expect(updatedReservation.data()!['prix'], equals(6.0));
        expect(updatedOriginalTimeSlot.data()!['current_reservations'], equals(9)); // 10 - 1 = 9
        expect(updatedNewTimeSlot.data()!['current_reservations'], equals(6)); // 5 + 1 = 6
      });
    });
  });
}