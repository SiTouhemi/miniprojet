import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/backend/services/time_slot_template_service.dart';

void main() {
  group('TimeSlotTemplateService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TimeSlotTemplateService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // Override the Firestore instance in the service
      service = TimeSlotTemplateService.instance;
    });

    test('should create a template successfully', () async {
      final templateId = await service.createTemplate(
        mealType: 'lunch',
        startTime: '11:40',
        endTime: '12:00',
        maxCapacity: 50,
        price: 0.2,
      );

      expect(templateId, isNotNull);
    });

    test('should validate time format correctly', () async {
      // Valid formats
      expect(() => service.createTemplate(
        mealType: 'lunch',
        startTime: '11:40',
        endTime: '12:00',
        maxCapacity: 50,
        price: 0.2,
      ), returnsNormally);

      // Invalid formats should throw
      expect(() => service.createTemplate(
        mealType: 'lunch',
        startTime: '25:40', // Invalid hour
        endTime: '12:00',
        maxCapacity: 50,
        price: 0.2,
      ), throwsException);
    });

    test('should parse time correctly for a date', () {
      final date = DateTime(2026, 1, 6); // Monday
      final parsedTime = service.parseTimeForDate('11:40', date);
      
      expect(parsedTime.year, equals(2026));
      expect(parsedTime.month, equals(1));
      expect(parsedTime.day, equals(6));
      expect(parsedTime.hour, equals(11));
      expect(parsedTime.minute, equals(40));
    });

    test('should generate correct default templates', () async {
      final result = await service.initializeDefaultTemplates();
      
      expect(result['success'], isTrue);
      expect(result['count'], equals(10)); // 7 lunch + 3 dinner
    });
  });
}