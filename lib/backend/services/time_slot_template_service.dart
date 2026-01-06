import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';
import '/config/app_config.dart';

/// Service for managing recurring time slot templates
/// Templates define the daily recurring time slots (e.g., lunch 11:40-12:00 every day)
class TimeSlotTemplateService {
  static TimeSlotTemplateService? _instance;
  static TimeSlotTemplateService get instance =>
      _instance ??= TimeSlotTemplateService._();
  TimeSlotTemplateService._();

  final CollectionReference _templatesCollection =
      FirebaseFirestore.instance.collection('time_slot_templates');

  /// Create a new time slot template
  /// Templates are recurring patterns (e.g., "Lunch 11:40-12:00" happens every day)
  Future<String?> createTemplate({
    required String mealType, // 'lunch' or 'dinner'
    required String startTime, // Format: "HH:mm" (e.g., "11:40")
    required String endTime, // Format: "HH:mm" (e.g., "12:00")
    required int maxCapacity,
    required double price,
    bool isActive = true,
  }) async {
    try {
      // Validate time format
      if (!_isValidTimeFormat(startTime) || !_isValidTimeFormat(endTime)) {
        throw Exception(
            'Invalid time format. Use HH:mm format (e.g., "11:40")');
      }

      final templateData = {
        'meal_type': mealType,
        'start_time': startTime,
        'end_time': endTime,
        'max_capacity': maxCapacity,
        'price': price,
        'is_active': isActive,
        'created_at': FieldValue.serverTimestamp(),
      };

      final docRef = await _templatesCollection.add(templateData);

      AppLogger.i(
        'Created time slot template: $mealType $startTime-$endTime',
        tag: 'TimeSlotTemplateService',
      );

      return docRef.id;
    } catch (e) {
      AppLogger.e('Error creating time slot template',
          error: e, tag: 'TimeSlotTemplateService');
      return null;
    }
  }

  /// Get all active templates
  Future<List<Map<String, dynamic>>> getActiveTemplates() async {
    try {
      final snapshot = await _templatesCollection
          .where('is_active', isEqualTo: true)
          .orderBy('meal_type')
          .orderBy('start_time')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching active templates',
          error: e, tag: 'TimeSlotTemplateService');
      return [];
    }
  }

  /// Get all templates (including inactive)
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      final snapshot = await _templatesCollection
          .orderBy('meal_type')
          .orderBy('start_time')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching all templates',
          error: e, tag: 'TimeSlotTemplateService');
      return [];
    }
  }

  /// Get templates stream for real-time updates
  Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _templatesCollection
        .orderBy('meal_type')
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
  }

  /// Update a template
  Future<bool> updateTemplate(
    String templateId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _templatesCollection.doc(templateId).update(updates);
      AppLogger.i('Updated template: $templateId',
          tag: 'TimeSlotTemplateService');
      return true;
    } catch (e) {
      AppLogger.e('Error updating template',
          error: e, tag: 'TimeSlotTemplateService');
      return false;
    }
  }

  /// Deactivate a template
  Future<bool> deactivateTemplate(String templateId) async {
    return await updateTemplate(templateId, {'is_active': false});
  }

  /// Activate a template
  Future<bool> activateTemplate(String templateId) async {
    return await updateTemplate(templateId, {'is_active': true});
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _templatesCollection.doc(templateId).delete();
      AppLogger.i('Deleted template: $templateId',
          tag: 'TimeSlotTemplateService');
      return true;
    } catch (e) {
      AppLogger.e('Error deleting template',
          error: e, tag: 'TimeSlotTemplateService');
      return false;
    }
  }

  /// Initialize default templates for Tunisian university restaurant
  /// Lunch: 11:40 - 14:00 (7 slots of 20 minutes)
  /// Dinner: 17:40 - 18:40 (3 slots of 20 minutes)
  Future<Map<String, dynamic>> initializeDefaultTemplates() async {
    try {
      // Check if templates already exist
      final existing = await getAllTemplates();
      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Templates already exist',
          'count': existing.length,
        };
      }

      int createdCount = 0;

      // Create lunch slots: 11:40 - 14:00 (20-minute intervals)
      final lunchSlots = _generateTimeSlots(
        startHour: 11,
        startMinute: 40,
        endHour: 14,
        endMinute: 0,
        intervalMinutes: 20,
      );

      for (final slot in lunchSlots) {
        await createTemplate(
          mealType: 'lunch',
          startTime: slot['start']!,
          endTime: slot['end']!,
          maxCapacity: AppConfig.defaultSlotCapacity,
          price: 0.2, // Standard meal price in TND
        );
        createdCount++;
      }

      // Create dinner slots: 17:40 - 18:40 (20-minute intervals)
      final dinnerSlots = _generateTimeSlots(
        startHour: 17,
        startMinute: 40,
        endHour: 18,
        endMinute: 40,
        intervalMinutes: 20,
      );

      for (final slot in dinnerSlots) {
        await createTemplate(
          mealType: 'dinner',
          startTime: slot['start']!,
          endTime: slot['end']!,
          maxCapacity: AppConfig.defaultSlotCapacity,
          price: 0.2, // Standard meal price in TND
        );
        createdCount++;
      }

      AppLogger.i('Initialized $createdCount default templates',
          tag: 'TimeSlotTemplateService');

      return {
        'success': true,
        'message': 'Default templates created successfully',
        'count': createdCount,
      };
    } catch (e) {
      AppLogger.e('Error initializing default templates',
          error: e, tag: 'TimeSlotTemplateService');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'count': 0,
      };
    }
  }

  /// Generate time slots for a given time range
  List<Map<String, String>> _generateTimeSlots({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int intervalMinutes,
  }) {
    final List<Map<String, String>> slots = [];

    int currentHour = startHour;
    int currentMinute = startMinute;

    while (true) {
      final nextMinute = currentMinute + intervalMinutes;
      final nextHour = currentHour + (nextMinute ~/ 60);
      final adjustedNextMinute = nextMinute % 60;

      // Check if we've exceeded the end time
      if (nextHour > endHour ||
          (nextHour == endHour && adjustedNextMinute > endMinute)) {
        break;
      }

      slots.add({
        'start': _formatTime(currentHour, currentMinute),
        'end': _formatTime(nextHour, adjustedNextMinute),
      });

      currentHour = nextHour;
      currentMinute = adjustedNextMinute;
    }

    return slots;
  }

  /// Format time as HH:mm
  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Validate time format (HH:mm)
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// Parse time string to DateTime for a specific date
  DateTime parseTimeForDate(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
