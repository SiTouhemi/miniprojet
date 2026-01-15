import '/backend/backend.dart';
import '/backend/services/menu_service.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'weekly_menu_widget.dart';

/// Model for WeeklyMenuWidget
/// Manages weekly menu data and loading states
class WeeklyMenuModel extends FlutterFlowModel<WeeklyMenuWidget> {
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  Map<int, List<DailyMenuRecord>> _weeklyMenu = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, List<DailyMenuRecord>> get weeklyMenu => _weeklyMenu;

  /// Load weekly menu data
  Future<void> loadWeeklyMenu() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      AppLogger.i('Loading weekly menu...', tag: 'WeeklyMenuModel');
      
      final weeklyMenuData = await MenuService.instance.getWeeklyMenu();
      
      _weeklyMenu = weeklyMenuData;
      
      AppLogger.i('Weekly menu loaded successfully: ${_weeklyMenu.length} days', 
          tag: 'WeeklyMenuModel');
      
    } catch (e) {
      AppLogger.e('Error loading weekly menu', error: e, tag: 'WeeklyMenuModel');
      _setError('Failed to load weekly menu. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh weekly menu data
  Future<void> refreshWeeklyMenu() async {
    AppLogger.i('Refreshing weekly menu...', tag: 'WeeklyMenuModel');
    
    // Clear existing data
    _weeklyMenu.clear();
    
    // Reload data
    await loadWeeklyMenu();
  }

  /// Get menu for a specific day
  List<DailyMenuRecord> getMenuForDay(int dayOfWeek) {
    return _weeklyMenu[dayOfWeek] ?? [];
  }

  /// Get lunch menus for a specific day
  List<DailyMenuRecord> getLunchMenusForDay(int dayOfWeek) {
    final dayMenus = getMenuForDay(dayOfWeek);
    return dayMenus.where((menu) => menu.mealType == 'lunch').toList();
  }

  /// Get dinner menus for a specific day
  List<DailyMenuRecord> getDinnerMenusForDay(int dayOfWeek) {
    final dayMenus = getMenuForDay(dayOfWeek);
    return dayMenus.where((menu) => menu.mealType == 'dinner').toList();
  }

  /// Check if a day has any menus
  bool hasDayMenu(int dayOfWeek) {
    return getMenuForDay(dayOfWeek).isNotEmpty;
  }

  /// Get total number of available menus for the week
  int getTotalMenuCount() {
    int total = 0;
    for (final dayMenus in _weeklyMenu.values) {
      total += dayMenus.length;
    }
    return total;
  }

  /// Get number of days with available menus
  int getAvailableDaysCount() {
    return _weeklyMenu.values.where((dayMenus) => dayMenus.isNotEmpty).length;
  }

  /// Get weekly menu statistics
  Map<String, dynamic> getWeeklyStats() {
    int totalMenus = 0;
    int lunchMenus = 0;
    int dinnerMenus = 0;
    int daysWithMenus = 0;
    double totalPrice = 0.0;
    int menuCount = 0;

    for (final dayMenus in _weeklyMenu.values) {
      if (dayMenus.isNotEmpty) {
        daysWithMenus++;
      }
      
      for (final menu in dayMenus) {
        totalMenus++;
        menuCount++;
        totalPrice += menu.price;
        
        if (menu.mealType == 'lunch') {
          lunchMenus++;
        } else if (menu.mealType == 'dinner') {
          dinnerMenus++;
        }
      }
    }

    final averagePrice = menuCount > 0 ? totalPrice / menuCount : 0.0;

    return {
      'totalMenus': totalMenus,
      'lunchMenus': lunchMenus,
      'dinnerMenus': dinnerMenus,
      'daysWithMenus': daysWithMenus,
      'averagePrice': averagePrice,
    };
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _errorMessage = error;
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void initState(BuildContext context) {
    // Initialize any context-dependent state here
  }

  @override
  void dispose() {
    // Clean up resources
    _weeklyMenu.clear();
  }
}