import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/services/time_slot_service.dart';
import '/backend/services/time_slot_template_service.dart';
import '/utils/app_logger.dart';

/// Utility class for generating time slots
class TimeSlotGenerator {
  static final TimeSlotService _timeSlotService = TimeSlotService.instance;
  static final TimeSlotTemplateService _templateService =
      TimeSlotTemplateService.instance;

  /// Generate time slots for today if they don't exist
  static Future<Map<String, dynamic>> generateTodaysSlots() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Check if restaurant is open (not Sunday)
      if (today.weekday == DateTime.sunday) {
        return {
          'success': false,
          'message': 'Restaurant is closed on Sundays',
          'created': 0,
        };
      }

      // Check if slots already exist for today
      final existingSlots = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('date', isEqualTo: todayStart)
          .where('is_active', isEqualTo: true)
          .get();

      if (existingSlots.docs.isNotEmpty) {
        return {
          'success': true,
          'message': 'Time slots already exist for today',
          'created': 0,
          'existing': existingSlots.docs.length,
        };
      }

      // Check if templates exist
      final templates = await _templateService.getActiveTemplates();
      if (templates.isEmpty) {
        return {
          'success': false,
          'message':
              'No active templates found. Please create templates first.',
          'created': 0,
        };
      }

      // Generate slots from templates
      final created = await _timeSlotService
          .createTimeSlotsForDateFromTemplates(todayStart);

      if (created) {
        // Count created slots
        final newSlots = await FirebaseFirestore.instance
            .collection('time_slots')
            .where('date', isEqualTo: todayStart)
            .where('is_active', isEqualTo: true)
            .get();

        return {
          'success': true,
          'message': 'Successfully generated time slots for today',
          'created': newSlots.docs.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate time slots from templates',
          'created': 0,
        };
      }
    } catch (e) {
      AppLogger.e('Error generating today\'s slots',
          error: e, tag: 'TimeSlotGenerator');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'created': 0,
      };
    }
  }

  /// Generate slots for multiple days
  static Future<Map<String, dynamic>> generateSlotsForDays({
    DateTime? startDate,
    int days = 7,
  }) async {
    try {
      final start = startDate ?? DateTime.now();

      return await _timeSlotService.bulkCreateTimeSlotsFromTemplates(
        startDate: start,
        numberOfDays: days,
      );
    } catch (e) {
      AppLogger.e('Error generating slots for multiple days',
          error: e, tag: 'TimeSlotGenerator');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'created': 0,
      };
    }
  }

  /// Check if templates are properly configured
  static Future<Map<String, dynamic>> checkTemplateConfiguration() async {
    try {
      final templates = await _templateService.getActiveTemplates();

      if (templates.isEmpty) {
        return {
          'configured': false,
          'message': 'No active templates found',
          'templates': 0,
        };
      }

      // Check for lunch and dinner templates
      final lunchTemplates =
          templates.where((t) => t['meal_type'] == 'lunch').length;
      final dinnerTemplates =
          templates.where((t) => t['meal_type'] == 'dinner').length;

      return {
        'configured': true,
        'message': 'Templates are properly configured',
        'templates': templates.length,
        'lunch': lunchTemplates,
        'dinner': dinnerTemplates,
      };
    } catch (e) {
      AppLogger.e('Error checking template configuration',
          error: e, tag: 'TimeSlotGenerator');
      return {
        'configured': false,
        'message': 'Error: ${e.toString()}',
        'templates': 0,
      };
    }
  }
}
