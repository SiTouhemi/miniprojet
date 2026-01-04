import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

/// Service for seeding the database with sample data
/// This service can be called from within the Flutter app to populate
/// the database with menus, time slots, and user data
class DataSeedingService {
  static DataSeedingService? _instance;
  static DataSeedingService get instance => _instance ??= DataSeedingService._();
  DataSeedingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all necessary data for the app to function
  Future<bool> seedAllData() async {
    try {
      AppLogger.i('Starting database seeding...', tag: 'DataSeeding');
      
      // Check if data already exists
      final existingMenus = await _firestore
          .collection('daily_menu')
          .where('created_by', isEqualTo: 'system')
          .limit(1)
          .get();
      
      if (existingMenus.docs.isNotEmpty) {
        AppLogger.i('Sample data already exists, skipping seeding', tag: 'DataSeeding');
        return true;
      }

      // Seed menus
      final menuSuccess = await _seedWeeklyMenus();
      if (!menuSuccess) {
        throw Exception('Failed to seed menus');
      }

      // Seed time slots
      final slotsSuccess = await _seedTimeSlots();
      if (!slotsSuccess) {
        throw Exception('Failed to seed time slots');
      }

      AppLogger.i('Database seeding completed successfully', tag: 'DataSeeding');
      return true;
    } catch (e) {
      AppLogger.e('Error seeding database', error: e, tag: 'DataSeeding');
      return false;
    }
  }

  /// Seed weekly menu data (Monday-Saturday)
  Future<bool> _seedWeeklyMenus() async {
    try {
      AppLogger.i('Seeding weekly menus...', tag: 'DataSeeding');
      
      final weeklyMenus = [
        // Monday (1)
        {
          'day_of_week': 1,
          'meal_type': 'lunch',
          'main_dish': 'Couscous aux légumes',
          'accompaniments': ['Salade verte', 'Pain', 'Olives'],
          'description': 'Couscous traditionnel tunisien avec légumes de saison',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 1,
          'meal_type': 'dinner',
          'main_dish': 'Spaghetti Bolognaise',
          'accompaniments': ['Fromage râpé', 'Pain à l\'ail', 'Salade'],
          'description': 'Spaghetti avec sauce bolognaise maison',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        
        // Tuesday (2)
        {
          'day_of_week': 2,
          'meal_type': 'lunch',
          'main_dish': 'Poulet grillé',
          'accompaniments': ['Riz basmati', 'Légumes sautés', 'Sauce'],
          'description': 'Poulet grillé aux herbes avec accompagnements',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 2,
          'meal_type': 'dinner',
          'main_dish': 'Pizza Margherita',
          'accompaniments': ['Salade mixte', 'Boisson'],
          'description': 'Pizza fraîche avec mozzarella et basilic',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        
        // Wednesday (3)
        {
          'day_of_week': 3,
          'meal_type': 'lunch',
          'main_dish': 'Poisson grillé',
          'accompaniments': ['Pommes de terre', 'Ratatouille', 'Citron'],
          'description': 'Poisson frais grillé avec légumes méditerranéens',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 3,
          'meal_type': 'dinner',
          'main_dish': 'Tajine de légumes',
          'accompaniments': ['Pain traditionnel', 'Olives', 'Salade'],
          'description': 'Tajine végétarien aux légumes de saison',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        
        // Thursday (4)
        {
          'day_of_week': 4,
          'meal_type': 'lunch',
          'main_dish': 'Escalope panée',
          'accompaniments': ['Frites maison', 'Salade verte', 'Sauce'],
          'description': 'Escalope de poulet panée avec frites croustillantes',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 4,
          'meal_type': 'dinner',
          'main_dish': 'Lasagnes',
          'accompaniments': ['Salade César', 'Pain à l\'ail', 'Parmesan'],
          'description': 'Lasagnes à la viande avec béchamel onctueuse',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        
        // Friday (5)
        {
          'day_of_week': 5,
          'meal_type': 'lunch',
          'main_dish': 'Kefta aux œufs',
          'accompaniments': ['Pain frais', 'Salade de tomates', 'Harissa'],
          'description': 'Kefta traditionnelle avec œufs et sauce tomate épicée',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 5,
          'meal_type': 'dinner',
          'main_dish': 'Burger maison',
          'accompaniments': ['Frites', 'Cornichons', 'Sauce spéciale'],
          'description': 'Burger artisanal avec steak haché frais',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        
        // Saturday (6)
        {
          'day_of_week': 6,
          'meal_type': 'lunch',
          'main_dish': 'Paella aux fruits de mer',
          'accompaniments': ['Pain grillé', 'Citron', 'Aioli'],
          'description': 'Paella valencienne aux fruits de mer frais',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'day_of_week': 6,
          'meal_type': 'dinner',
          'main_dish': 'Gratin de pâtes',
          'accompaniments': ['Salade verte', 'Pain', 'Fromage'],
          'description': 'Gratin de pâtes au fromage et béchamel dorée',
          'price': 0.2,
          'available': true,
          'image_url': '',
          'created_by': 'system',
          'created_at': FieldValue.serverTimestamp(),
        },
      ];

      // Add menus in batch
      final batch = _firestore.batch();
      for (final menu in weeklyMenus) {
        final docRef = _firestore.collection('daily_menu').doc();
        batch.set(docRef, menu);
      }
      
      await batch.commit();
      AppLogger.i('Added ${weeklyMenus.length} weekly menu items', tag: 'DataSeeding');
      return true;
    } catch (e) {
      AppLogger.e('Error seeding menus', error: e, tag: 'DataSeeding');
      return false;
    }
  }

  /// Seed time slots for the next 7 days
  Future<bool> _seedTimeSlots() async {
    try {
      AppLogger.i('Seeding time slots...', tag: 'DataSeeding');
      
      final timeSlots = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      // Generate slots for next 7 days
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final currentDate = DateTime(now.year, now.month, now.day + dayOffset);
        
        // Skip Sundays (weekday 7)
        if (currentDate.weekday == 7) continue;
        
        // Lunch slots (12:00-14:00)
        final lunchSlots = [
          {'start': 12, 'startMin': 0, 'end': 12, 'endMin': 30, 'capacity': 25},
          {'start': 12, 'startMin': 30, 'end': 13, 'endMin': 0, 'capacity': 25},
          {'start': 13, 'startMin': 0, 'end': 13, 'endMin': 30, 'capacity': 25},
          {'start': 13, 'startMin': 30, 'end': 14, 'endMin': 0, 'capacity': 25},
        ];
        
        // Dinner slots (19:00-21:00)
        final dinnerSlots = [
          {'start': 19, 'startMin': 0, 'end': 19, 'endMin': 30, 'capacity': 30},
          {'start': 19, 'startMin': 30, 'end': 20, 'endMin': 0, 'capacity': 30},
          {'start': 20, 'startMin': 0, 'end': 20, 'endMin': 30, 'capacity': 30},
          {'start': 20, 'startMin': 30, 'end': 21, 'endMin': 0, 'capacity': 30},
        ];
        
        // Create lunch time slots
        for (final slot in lunchSlots) {
          final startTime = DateTime(currentDate.year, currentDate.month, currentDate.day, slot['start'] as int, slot['startMin'] as int);
          final endTime = DateTime(currentDate.year, currentDate.month, currentDate.day, slot['end'] as int, slot['endMin'] as int);
          
          timeSlots.add({
            'date': Timestamp.fromDate(currentDate),
            'start_time': Timestamp.fromDate(startTime),
            'end_time': Timestamp.fromDate(endTime),
            'meal_type': 'lunch',
            'max_capacity': slot['capacity'],
            'current_reservations': 0,
            'price': 0.2,
            'is_active': true,
          });
        }
        
        // Create dinner time slots
        for (final slot in dinnerSlots) {
          final startTime = DateTime(currentDate.year, currentDate.month, currentDate.day, slot['start'] as int, slot['startMin'] as int);
          final endTime = DateTime(currentDate.year, currentDate.month, currentDate.day, slot['end'] as int, slot['endMin'] as int);
          
          timeSlots.add({
            'date': Timestamp.fromDate(currentDate),
            'start_time': Timestamp.fromDate(startTime),
            'end_time': Timestamp.fromDate(endTime),
            'meal_type': 'dinner',
            'max_capacity': slot['capacity'],
            'current_reservations': 0,
            'price': 0.2,
            'is_active': true,
          });
        }
      }
      
      // Add time slots in batches (Firestore limit is 500 operations per batch)
      const batchSize = 500;
      for (int i = 0; i < timeSlots.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchSlots = timeSlots.skip(i).take(batchSize);
        
        for (final slot in batchSlots) {
          final docRef = _firestore.collection('time_slots').doc();
          batch.set(docRef, slot);
        }
        
        await batch.commit();
      }
      
      AppLogger.i('Added ${timeSlots.length} time slots', tag: 'DataSeeding');
      return true;
    } catch (e) {
      AppLogger.e('Error seeding time slots', error: e, tag: 'DataSeeding');
      return false;
    }
  }

  /// Check if sample data exists
  Future<bool> hasSampleData() async {
    try {
      final menuQuery = await _firestore
          .collection('daily_menu')
          .where('created_by', isEqualTo: 'system')
          .limit(1)
          .get();
      
      final slotsQuery = await _firestore
          .collection('time_slots')
          .limit(1)
          .get();
      
      return menuQuery.docs.isNotEmpty && slotsQuery.docs.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error checking sample data', error: e, tag: 'DataSeeding');
      return false;
    }
  }

  /// Clear all sample data (for testing purposes)
  Future<bool> clearSampleData() async {
    try {
      AppLogger.i('Clearing sample data...', tag: 'DataSeeding');
      
      // Clear sample menus
      final menuQuery = await _firestore
          .collection('daily_menu')
          .where('created_by', isEqualTo: 'system')
          .get();
      
      final menuBatch = _firestore.batch();
      for (final doc in menuQuery.docs) {
        menuBatch.delete(doc.reference);
      }
      await menuBatch.commit();
      
      // Clear time slots (be careful - this clears ALL time slots)
      final slotsQuery = await _firestore
          .collection('time_slots')
          .get();
      
      const batchSize = 500;
      for (int i = 0; i < slotsQuery.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchDocs = slotsQuery.docs.skip(i).take(batchSize);
        
        for (final doc in batchDocs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      }
      
      AppLogger.i('Sample data cleared', tag: 'DataSeeding');
      return true;
    } catch (e) {
      AppLogger.e('Error clearing sample data', error: e, tag: 'DataSeeding');
      return false;
    }
  }
}