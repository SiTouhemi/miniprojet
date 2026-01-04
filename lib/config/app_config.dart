/// Application configuration constants
/// This file contains all hardcoded values that should be configurable
class AppConfig {
  // Institution Information
  static const String institutionName = 'ISETCOM Restaurant';
  static const String institutionSubtitle = 'Restaurant Universitaire ISET';
  static const String systemName = 'Système de Réservation';
  static const String logoAssetPath = 'assets/images/logo_iset_com.jpg';
  
  // Currency & Pricing
  static const String currency = 'DT';
  static const String currencySymbol = 'DT';
  static const int priceDecimalPlaces = 2;
  
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
  
  // Colors (should eventually move to theme)
  static const int primaryColorValue = 0xFF005BAA;
  static const int accentColorValue = 0xFF00A4E4;
  static const int successColorValue = 0xFF00A855;
  static const int warningColorValue = 0xFFFF6B35;
  static const int errorColorValue = 0xFFE74C3C;
  
  // Status Labels (should eventually move to i18n)
  static const Map<String, String> statusLabels = {
    'confirmed': 'Confirmé',
    'pending': 'En attente',
    'cancelled': 'Annulé',
    'used': 'Utilisé',
    'expired': 'Expiré',
  };
  
  // UI Labels (should eventually move to i18n)
  static const Map<String, String> labels = {
    'current_balance': 'Solde Actuel',
    'choose_time_slot': 'Choisir un Créneau',
    'daily_menu': 'Plat du Jour',
    'quick_actions': 'Actions Rapides',
    'reservation_details': 'Détails de votre réservation',
    'no_active_reservation': 'Aucune réservation active',
    'no_reservations_found': 'Aucune réservation trouvée',
    'no_slots_available': 'Aucun créneau disponible pour le moment',
    'no_menu_available': 'Aucun menu disponible pour aujourd\'hui',
    'reservation_confirmed': 'Réservation confirmée !',
    'ticket_generated': 'Votre ticket repas a été généré avec succès',
    'present_qr_code': 'Présentez ce code à l\'entrée du restaurant',
    'arrive_on_time': 'Veuillez arriver à l\'heure de votre créneau',
  };
  
  // Button Labels (should eventually move to i18n)
  static const Map<String, String> buttons = {
    'reserve': 'Réserver',
    'cancel': 'Annuler',
    'modify': 'Modifier',
    'refresh': 'Actualiser',
    'confirm': 'Confirmer',
    'back_to_home': 'Retour à l\'accueil',
    'view_history': 'Voir l\'historique',
    'view_qr': 'Voir le QR Code',
  };
  
  // Helper methods
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(priceDecimalPlaces)} $currency';
  }
  
  static String getStatusLabel(String status) {
    return statusLabels[status] ?? status;
  }
  
  static String getLabel(String key) {
    return labels[key] ?? key;
  }
  
  static String getButton(String key) {
    return buttons[key] ?? key;
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