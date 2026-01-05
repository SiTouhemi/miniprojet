import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../lib/backend/services/time_slot_service.dart';
import '../../lib/backend/backend.dart';

// Mock classes for testing
class MockTimeSlotRecord extends Mock implements TimeSlotRecord {}

void main() {
  group('Time Slot Locking Tests', () {
    late TimeSlotService timeSlotService;

    setUp(() {
      timeSlotService = TimeSlotService.instance;
    });

    test('should lock time slots on Sunday (restaurant closed)', () {
      // Create a mock time slot for Sunday
      final mockTimeSlot = MockTimeSlotRecord();
      final sundayDate = DateTime(2024, 1, 7); // A Sunday
      
      when(mockTimeSlot.date).thenReturn(sundayDate);
      when(mockTimeSlot.endTime).thenReturn(sundayDate.add(Duration(hours: 1)));

      // Test that Sunday slots are locked
      final isLocked = timeSlotService.isTimeSlotLocked(mockTimeSlot);
      expect(isLocked, true, reason: 'Time slots should be locked on Sundays');
    });

    test('should lock time slots when end time has passed', () {
      // Create a mock time slot in the past
      final mockTimeSlot = MockTimeSlotRecord();
      final pastDate = DateTime.now().subtract(Duration(hours: 2));
      
      when(mockTimeSlot.date).thenReturn(pastDate);
      when(mockTimeSlot.endTime).thenReturn(pastDate);

      // Test that past slots are locked
      final isLocked = timeSlotService.isTimeSlotLocked(mockTimeSlot);
      expect(isLocked, true, reason: 'Time slots should be locked when end time has passed');
    });

    test('should not lock future time slots on weekdays', () {
      // Create a mock time slot for future weekday
      final mockTimeSlot = MockTimeSlotRecord();
      final futureDate = DateTime.now().add(Duration(hours: 2));
      final weekdayDate = DateTime(2024, 1, 8); // A Monday
      
      when(mockTimeSlot.date).thenReturn(weekdayDate);
      when(mockTimeSlot.endTime).thenReturn(futureDate);

      // Test that future weekday slots are not locked
      final isLocked = timeSlotService.isTimeSlotLocked(mockTimeSlot);
      expect(isLocked, false, reason: 'Future time slots on weekdays should not be locked');
    });

    test('should identify restaurant as closed on Sundays', () {
      final sundayDate = DateTime(2024, 1, 7); // A Sunday
      final mondayDate = DateTime(2024, 1, 8); // A Monday

      expect(timeSlotService.isRestaurantOpen(sundayDate), false, 
          reason: 'Restaurant should be closed on Sundays');
      expect(timeSlotService.isRestaurantOpen(mondayDate), true, 
          reason: 'Restaurant should be open on weekdays');
    });

    test('should validate time slot with locking logic', () async {
      // This test would require more complex mocking of Firestore
      // For now, we'll test the basic validation logic structure
      
      // Test that validation includes Sunday check
      final result = await timeSlotService.validateTimeSlotForReservation('test-id');
      
      // The result should be invalid for non-existent time slot
      expect(result.isValid, false);
      expect(result.errorMessage, 'Time slot not found');
    });
  });

  group('Time Slot Availability Tests', () {
    late TimeSlotService timeSlotService;

    setUp(() {
      timeSlotService = TimeSlotService.instance;
    });

    test('should filter out Sunday slots from available slots', () async {
      final sundayDate = DateTime(2024, 1, 7); // A Sunday
      
      // Test that Sunday returns empty list
      final availableSlots = await timeSlotService.getAvailableTimeSlotsWithLocking(sundayDate);
      expect(availableSlots, isEmpty, 
          reason: 'No time slots should be available on Sundays');
    });

    test('should allow weekday slots when restaurant is open', () {
      final mondayDate = DateTime(2024, 1, 8); // A Monday
      
      // Test that weekdays are considered open
      expect(timeSlotService.isRestaurantOpen(mondayDate), true,
          reason: 'Restaurant should be open on weekdays');
    });
  });
}