class AppConfig {
  // Environment Configuration
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'production');
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';
  
  // App Information
  static const String appName = 'ISET Com Restaurant';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  // Organization Details
  static const String organizationName = 'ISET Com';
  static const String organizationDomain = 'isetcom.tn';
  static const String supportEmail = 'support@isetcom.tn';
  static const String contactPhone = '+216 71 XXX XXX';
  
  // App Store Information
  static const String androidPackageId = 'tn.edu.isetcom.restaurant';
  static const String iosAppId = 'tn.edu.isetcom.restaurant';
  
  // Deep Linking
  static const String deepLinkScheme = 'isetrestaurant';
  static const String deepLinkHost = 'isetcom.tn';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableRemoteConfig = true;
  
  // Business Rules - Tunisian University Restaurant
  static const int maxReservationsPerUser = 2; // Lunch + Dinner max per day
  static const int reservationDeadlineHours = 1; // 1 hour before meal
  static const double fixedMealPrice = 0.2; // TND - government subsidized
  static const int maxCapacityPerSlot = 200; // Students per meal time
  
  // Tunisian Meal Times
  static const String lunchStartTime = '12:00';
  static const String lunchEndTime = '14:00';
  static const String dinnerStartTime = '19:00';
  static const String dinnerEndTime = '21:00';
  
  // Currency and Subsidy
  static const String currency = 'TND';
  static const double governmentSubsidyRate = 0.95; // 95% subsidized
  static const double actualMealCost = 4.0; // Real cost before subsidy
  
  // API Configuration
  static const String d17ApiBaseUrl = 'https://api.d17.tn';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const int maxCacheSize = 100; // MB
  
  // Notification Configuration
  static const String fcmSenderId = ''; // To be filled when Firebase is configured
  static const bool enablePushNotifications = true;
  
  // Security Configuration
  static const bool enableBiometricAuth = false; // Future feature
  static const bool enablePinAuth = false; // Future feature
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // UI Configuration
  static const List<String> supportedLanguages = ['en', 'fr', 'ar'];
  static const String defaultLanguage = 'fr'; // French for Tunisia
  static const bool enableDarkMode = true;
  
  // Logging Configuration
  static const bool enableDebugLogging = !isProduction;
  static const bool enableNetworkLogging = !isProduction;
  
  // Get configuration based on environment
  static Map<String, dynamic> getConfig() {
    return {
      'environment': environment,
      'isProduction': isProduction,
      'appName': appName,
      'version': appVersion,
      'buildNumber': buildNumber,
      'organization': {
        'name': organizationName,
        'domain': organizationDomain,
        'supportEmail': supportEmail,
        'contactPhone': contactPhone,
      },
      'features': {
        'analytics': enableAnalytics,
        'crashReporting': enableCrashReporting,
        'performanceMonitoring': enablePerformanceMonitoring,
        'remoteConfig': enableRemoteConfig,
        'pushNotifications': enablePushNotifications,
      },
      'business': {
        'maxReservationsPerUser': maxReservationsPerUser,
        'reservationDeadlineHours': reservationDeadlineHours,
        'defaultMealPrice': fixedMealPrice,
        'maxCapacityPerSlot': maxCapacityPerSlot,
      },
      'api': {
        'd17BaseUrl': d17ApiBaseUrl,
        'timeout': apiTimeout.inMilliseconds,
        'maxRetryAttempts': maxRetryAttempts,
      },
    };
  }
}