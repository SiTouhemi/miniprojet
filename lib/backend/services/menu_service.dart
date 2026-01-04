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
  Future<List<DailyMenuRecord>> getTodaysMenu() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .where('available', isEqualTo: true)
          .orderBy('date')
          .orderBy('meal_type')
          .get();

      return snapshot.docs
          .map((doc) => DailyMenuRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching today\'s menu', error: e, tag: 'MenuService');
      return [];
    }
  }

  /// Get menu for a specific date
  Future<List<DailyMenuRecord>> getMenuForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .where('available', isEqualTo: true)
          .orderBy('date')
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
  Stream<List<DailyMenuRecord>> getTodaysMenuStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('daily_menu')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('available', isEqualTo: true)
        .orderBy('date')
        .orderBy('meal_type')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyMenuRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get menu for a specific date with real-time updates
  Stream<List<DailyMenuRecord>> getMenuForDateStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('daily_menu')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('available', isEqualTo: true)
        .orderBy('date')
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

  /// Create a new daily menu
  Future<bool> createDailyMenu({
    required DateTime date,
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
        'date': date,
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
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_menu')
          .where('date', isGreaterThanOrEqualTo: startOfWeek)
          .where('date', isLessThanOrEqualTo: endOfWeek)
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
        'weekStart': startOfWeek,
        'weekEnd': endOfWeek,
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