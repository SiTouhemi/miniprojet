import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

/// Service for managing daily menus and menu items
class MenuService {
  static MenuService? _instance;
  static MenuService get instance => _instance ??= MenuService._();
  MenuService._();

  /// Get today's menu from daily_menu collection
  /// Uses day of week (1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday)
  Future<List<DailyMenuRecord>> getTodaysMenu() async {
    try {
      final today = DateTime.now();
      final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday
      
      // Sunday (7) has no meals
      if (dayOfWeek == 7) {
        AppLogger.i('Sunday - no meals available', tag: 'MenuService');
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('day_of_week', isEqualTo: dayOfWeek)
          .where('available', isEqualTo: true)
          .orderBy('meal_type')
          .get();

      AppLogger.i('Found ${snapshot.docs.length} menus for day $dayOfWeek', tag: 'MenuService');
      
      return snapshot.docs
          .map((doc) => DailyMenuRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching today\'s menu', error: e, tag: 'MenuService');
      return [];
    }
  }

  /// Get menu for a specific date
  /// Uses day of week (1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday)
  Future<List<DailyMenuRecord>> getMenuForDate(DateTime date) async {
    try {
      final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
      
      // Sunday (7) has no meals
      if (dayOfWeek == 7) {
        AppLogger.i('Sunday - no meals available', tag: 'MenuService');
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('day_of_week', isEqualTo: dayOfWeek)
          .where('available', isEqualTo: true)
          .orderBy('meal_type')
          .get();

      return snapshot.docs
          .map((doc) => DailyMenuRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching menu for date', error: e, tag: 'MenuService');
      return [];
    }
  }

  /// Get real-time stream of today's menu
  /// Uses day of week (1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday)
  Stream<List<DailyMenuRecord>> getTodaysMenuStream() {
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday
    
    // Sunday (7) has no meals
    if (dayOfWeek == 7) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('daily_menu')
        .where('day_of_week', isEqualTo: dayOfWeek)
        .where('available', isEqualTo: true)
        .orderBy('meal_type')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMenuRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get menu for a specific date with real-time updates
  /// Uses day of week (1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday)
  Stream<List<DailyMenuRecord>> getMenuForDateStream(DateTime date) {
    final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    
    // Sunday (7) has no meals
    if (dayOfWeek == 7) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('daily_menu')
        .where('day_of_week', isEqualTo: dayOfWeek)
        .where('available', isEqualTo: true)
        .orderBy('meal_type')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMenuRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get all menu items (plats) for menu creation
  Future<List<PlatRecord>> getAllMenuItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plat')
          .orderBy('categorie')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => PlatRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching menu items', error: e, tag: 'MenuService');
      return [];
    }
  }

  /// Get menu for a specific day of week (1=Monday, 7=Sunday)
  Future<List<DailyMenuRecord>> getMenuForDayOfWeek(int dayOfWeek) async {
    try {
      // Sunday (7) has no meals
      if (dayOfWeek == 7) {
        AppLogger.i('Sunday - no meals available', tag: 'MenuService');
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('day_of_week', isEqualTo: dayOfWeek)
          .where('available', isEqualTo: true)
          .orderBy('meal_type')
          .get();

      return snapshot.docs
          .map((doc) => DailyMenuRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching menu for day of week', error: e, tag: 'MenuService');
      return [];
    }
  }

  /// Get weekly menu (Monday to Saturday)
  Future<Map<int, List<DailyMenuRecord>>> getWeeklyMenu() async {
    try {
      final weeklyMenu = <int, List<DailyMenuRecord>>{};
      
      // Get menus for Monday (1) to Saturday (6)
      for (int dayOfWeek = 1; dayOfWeek <= 6; dayOfWeek++) {
        final dayMenu = await getMenuForDayOfWeek(dayOfWeek);
        weeklyMenu[dayOfWeek] = dayMenu;
      }
      
      return weeklyMenu;
    } catch (e) {
      AppLogger.e('Error fetching weekly menu', error: e, tag: 'MenuService');
      return {};
    }
  }

  /// Helper method to get day name from day of week
  static String getDayName(int dayOfWeek, {String locale = 'fr'}) {
    switch (locale) {
      case 'fr':
        switch (dayOfWeek) {
          case 1: return 'Lundi';
          case 2: return 'Mardi';
          case 3: return 'Mercredi';
          case 4: return 'Jeudi';
          case 5: return 'Vendredi';
          case 6: return 'Samedi';
          case 7: return 'Dimanche';
          default: return 'Inconnu';
        }
      case 'en':
        switch (dayOfWeek) {
          case 1: return 'Monday';
          case 2: return 'Tuesday';
          case 3: return 'Wednesday';
          case 4: return 'Thursday';
          case 5: return 'Friday';
          case 6: return 'Saturday';
          case 7: return 'Sunday';
          default: return 'Unknown';
        }
      case 'ar':
        switch (dayOfWeek) {
          case 1: return 'الاثنين';
          case 2: return 'الثلاثاء';
          case 3: return 'الأربعاء';
          case 4: return 'الخميس';
          case 5: return 'الجمعة';
          case 6: return 'السبت';
          case 7: return 'الأحد';
          default: return 'غير معروف';
        }
      default:
        return getDayName(dayOfWeek, locale: 'en');
    }
  }

  /// Create a new daily menu with day of week
  Future<bool> createDailyMenu({
    required int dayOfWeek,
    required String mealType,
    required String mainDish,
    required List<String> accompaniments,
    required String description,
    required double price,
    String? imageUrl,
    required String createdBy,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('daily_menu').add({
        'day_of_week': dayOfWeek,
        'meal_type': mealType,
        'main_dish': mainDish,
        'accompaniments': accompaniments,
        'description': description,
        'price': price,
        'available': true,
        'image_url': imageUrl ?? '',
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
      });

      AppLogger.i('Daily menu created successfully', tag: 'MenuService');
      return true;
    } catch (e) {
      AppLogger.e('Error creating daily menu', error: e, tag: 'MenuService');
      return false;
    }
  }

  /// Update a daily menu
  Future<bool> updateDailyMenu({
    required String menuId,
    String? mainDish,
    List<String>? accompaniments,
    String? description,
    double? price,
    bool? available,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (mainDish != null) updateData['main_dish'] = mainDish;
      if (accompaniments != null) updateData['accompaniments'] = accompaniments;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (available != null) updateData['available'] = available;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('daily_menu')
          .doc(menuId)
          .update(updateData);

      AppLogger.i('Daily menu updated successfully', tag: 'MenuService');
      return true;
    } catch (e) {
      AppLogger.e('Error updating daily menu', error: e, tag: 'MenuService');
      return false;
    }
  }

  /// Delete a daily menu
  Future<bool> deleteDailyMenu(String menuId) async {
    try {
      await FirebaseFirestore.instance
          .collection('daily_menu')
          .doc(menuId)
          .delete();

      AppLogger.i('Daily menu deleted successfully', tag: 'MenuService');
      return true;
    } catch (e) {
      AppLogger.e('Error deleting daily menu', error: e, tag: 'MenuService');
      return false;
    }
  }

  /// Get menu statistics
  Future<Map<String, dynamic>> getMenuStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('available', isEqualTo: true)
          .get();

      final menus = snapshot.docs.map((doc) => DailyMenuRecord.fromSnapshot(doc)).toList();
      
      final totalMenus = menus.length;
      final availableMenus = menus.where((menu) => menu.available).length;
      final lunchMenus = menus.where((menu) => menu.mealType == 'lunch').length;
      final dinnerMenus = menus.where((menu) => menu.mealType == 'dinner').length;
      final averagePrice = menus.isNotEmpty 
          ? menus.map((menu) => menu.price).reduce((a, b) => a + b) / menus.length
          : 0.0;

      return {
        'totalMenus': totalMenus,
        'availableMenus': availableMenus,
        'lunchMenus': lunchMenus,
        'dinnerMenus': dinnerMenus,
        'averagePrice': averagePrice,
      };
    } catch (e) {
      AppLogger.e('Error fetching menu stats', error: e, tag: 'MenuService');
      return {
        'totalMenus': 0,
        'availableMenus': 0,
        'lunchMenus': 0,
        'dinnerMenus': 0,
        'averagePrice': 0.0,
      };
    }
  }
}