/// Application configuration constants
/// This file contains all hardcoded values that should be configurable
class AppConfig {
  // Institution Information
  static const String institutionName = 'ISETCOM Restaurant';
  static const String institutionSubtitle = 'Restaurant Universitaire ISET';
  static const String systemName = 'Système de Réservation';
  
  // Asset paths
  static const Map<String, String> assets = {
    'logo': 'assets/images/logo_iset_com.jpg',
    'placeholder_user': 'assets/images/user_placeholder.png',
    'empty_state': 'assets/images/empty_state.png',
  };
  
  // Network images (fallback URLs)
  static const Map<String, String> networkImages = {
    'logo_fallback': 'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/bada-r5ikqy/assets/cnndd49655hs/logo_iset_com.jpg',
  };
  
  // Currency & Pricing
  static const String currency = 'DT';
  static const String currencySymbol = 'DT';
  static const int priceDecimalPlaces = 3; // Changed to 3 for Tunisian Dinar precision
  
  // Business Rules
  static const int cancellationWindowHours = 2;
  static const int reservationWindowDays = 30;
  static const int lowAvailabilityThreshold = 5;
  static const int historyRetentionDays = 90;
  
  // Environment Configuration
  static const bool isProduction = false; // Set to true for production builds
  static const bool enableCrashReporting = true;
  static const bool enableDebugLogging = !isProduction;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableAnalytics = isProduction;
  
  // Legacy color values (kept for backward compatibility)
  static const int primaryColorValue = 0xFF005BAA;
  static const int accentColorValue = 0xFF00A4E4;
  static const int successColorValue = 0xFF00A855;
  static const int warningColorValue = 0xFFFF6B35;
  static const int errorColorValue = 0xFFE74C3C;
  
  // Helper methods
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(priceDecimalPlaces)} $currency';
  }
  
  static String getAsset(String key) {
    return assets[key] ?? '';
  }
  
  static String getNetworkImage(String key) {
    return networkImages[key] ?? '';
  }
  
  static bool isLowAvailability(int availableSpots) {
    return availableSpots <= lowAvailabilityThreshold;
  }
  
  static bool canCancelReservation(DateTime reservationTime) {
    final now = DateTime.now();
    final hoursUntil = reservationTime.difference(now).inHours;
    return hoursUntil >= cancellationWindowHours;
  }
}