import 'package:flutter/material.dart';

/// Application localization system
/// Provides centralized text management for multiple languages
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('fr', ''),
    Locale('ar', ''),
  ];

  // Localized strings map
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'ISETCOM Restaurant',
      'app_subtitle': 'University Restaurant ISET',
      'system_name': 'Reservation System',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'ok': 'OK',
      'retry': 'Retry',
      'back': 'Back',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      
      // Authentication
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'signing_in': 'Signing in...',
      'email_placeholder': 'your.email@isetcom.tn',
      'password_placeholder': 'Your password',
      'forgot_password_title': 'Forgot Password',
      'forgot_password_message': 'Enter your email address to receive a reset link.',
      'send': 'Send',
      'reset_email_sent': 'Reset email sent! Check your inbox.',
      'copyright': '© 2025 ISETCOM - All rights reserved',
      
      // Home
      'greeting': 'Hello, {name}',
      'greeting_default': 'Hello, User',
      'class_label': 'Class: {class}',
      'current_balance': 'Current Balance',
      'tickets_available': '{count} ticket(s) available',
      'quick_actions': 'Quick Actions',
      'reserve_meal': 'Reserve Meal',
      'reserve_meal_subtitle': 'Book your meal',
      'qr_code': 'QR Code',
      'restaurant_access': 'Restaurant access',
      'history': 'History',
      'your_reservations': 'Your reservations',
      'profile': 'Profile',
      'my_information': 'My information',
      'todays_menu': 'Today\'s Menu',
      'no_menu_available': 'No menu available today',
      'data_refreshed': 'Data refreshed successfully',
      'no_confirmed_reservations': 'No confirmed reservations found',
      'loading_user_data': 'Loading user data...',
      'unable_to_load_user_data': 'Unable to load user data',
      
      // Profile
      'profile_settings': 'Profile Settings',
      'login_to_view_profile': 'Please log in to view your profile',
      'go_to_login': 'Go to Login',
      'account_information': 'Account Information',
      'full_name': 'Full Name',
      'enter_full_name': 'Enter your full name',
      'enter_email': 'Enter your email',
      'phone_number': 'Phone Number',
      'enter_phone': 'Enter your phone number',
      'class': 'Class',
      'enter_class': 'Enter your class (e.g., L3 INFO)',
      'preferences': 'Preferences',
      'language': 'Language',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'push_notifications': 'Push Notifications',
      'notification_subtitle': 'Receive reminders about your reservations',
      'update_profile': 'Update Profile',
      'updating': 'Updating...',
      'profile_updated': 'Profile updated successfully',
      'profile_update_error': 'Error updating profile',
      'please_enter_name': 'Please enter your name',
      'please_enter_email': 'Please enter your email',
      'invalid_email': 'Please enter a valid email',
      
      // Reservations
      'my_reservations': 'My Reservations',
      'no_upcoming_reservations': 'No upcoming reservations',
      'make_reservation_prompt': 'Make a reservation to see it here',
      'cancel_reservation': 'Cancel Reservation',
      'cancel_reservation_confirm': 'Are you sure you want to cancel this reservation?',
      'keep_reservation': 'Keep Reservation',
      'select_new_time_slot': 'Select New Time Slot',
      'modify': 'Modify',
      'time_label': 'Time',
      'price_label': 'Price',
      'capacity_label': 'Capacity',
      'hours_until_meal': 'Hours until meal',
      'available_label': 'Available',
      'person_s': 'person(s)',
      'cannot_cancel': 'Cannot Cancel',
      'cannot_modify': 'Cannot Modify',
      'no_available_slots': 'No Available Slots',
      'no_alternative_slots': 'No alternative time slots are available for modification.',
      'reservation_cancelled': 'Reservation cancelled successfully',
      'reservation_modified': 'Reservation modified successfully',
      'failed_to_cancel': 'Failed to cancel reservation',
      'failed_to_modify': 'Failed to modify reservation',
      'error_cancelling': 'Error cancelling reservation',
      'error_modifying': 'Error modifying reservation',
      'failed_to_load_reservations': 'Failed to load reservations',
      'error_loading_slots': 'Error loading time slots',
      'user_requested_cancellation': 'User requested cancellation',
      'reservation_cancelled_status': 'This reservation has been cancelled',
      'reservation_used_status': 'This reservation has been used',
      'past_reservations_message': 'Past reservations cannot be modified or cancelled',
      'two_hour_restriction': 'Cannot modify or cancel less than 2 hours before meal time',
      'modification_not_available': 'Modification and cancellation not available',
      'cancellation_note': 'Note: Cancellations must be made at least 2 hours before the meal time.',
      
      // Status labels
      'status_confirmed': 'Confirmed',
      'status_pending': 'Pending',
      'status_cancelled': 'Cancelled',
      'status_used': 'Used',
      'status_expired': 'Expired',
    },
    
    'fr': {
      // Common
      'app_name': 'ISETCOM Restaurant',
      'app_subtitle': 'Restaurant Universitaire ISET',
      'system_name': 'Système de Réservation',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'ok': 'OK',
      'retry': 'Réessayer',
      'back': 'Retour',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      
      // Authentication
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'email': 'Adresse e-mail',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'sign_in': 'Se connecter',
      'signing_in': 'Connexion en cours...',
      'email_placeholder': 'votre.email@isetcom.tn',
      'password_placeholder': 'Votre mot de passe',
      'forgot_password_title': 'Mot de passe oublié',
      'forgot_password_message': 'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
      'send': 'Envoyer',
      'reset_email_sent': 'E-mail de réinitialisation envoyé ! Vérifiez votre boîte de réception.',
      'copyright': '© 2025 ISETCOM - Tous droits réservés',
      
      // Home
      'greeting': 'Bonjour, {name}',
      'greeting_default': 'Bonjour, Utilisateur',
      'class_label': 'Classe: {class}',
      'current_balance': 'Solde Actuel',
      'tickets_available': '{count} ticket(s) disponible(s)',
      'quick_actions': 'Actions Rapides',
      'reserve_meal': 'Réserver Repas',
      'reserve_meal_subtitle': 'Réservez votre repas',
      'qr_code': 'Code QR',
      'restaurant_access': 'Accès restaurant',
      'history': 'Historique',
      'your_reservations': 'Vos réservations',
      'profile': 'Profil',
      'my_information': 'Mes informations',
      'todays_menu': 'Menu du Jour',
      'no_menu_available': 'Aucun menu disponible aujourd\'hui',
      'data_refreshed': 'Données actualisées avec succès',
      'no_confirmed_reservations': 'Aucune réservation confirmée trouvée',
      'loading_user_data': 'Chargement des données utilisateur...',
      'unable_to_load_user_data': 'Impossible de charger les données utilisateur',
      
      // Profile
      'profile_settings': 'Paramètres du Profil',
      'login_to_view_profile': 'Veuillez vous connecter pour voir votre profil',
      'go_to_login': 'Aller à la Connexion',
      'account_information': 'Informations du Compte',
      'full_name': 'Nom Complet',
      'enter_full_name': 'Entrez votre nom complet',
      'enter_email': 'Entrez votre e-mail',
      'phone_number': 'Numéro de Téléphone',
      'enter_phone': 'Entrez votre numéro de téléphone',
      'class': 'Classe',
      'enter_class': 'Entrez votre classe (ex: L3 INFO)',
      'preferences': 'Préférences',
      'language': 'Langue',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'push_notifications': 'Notifications Push',
      'notification_subtitle': 'Recevoir des rappels sur vos réservations',
      'update_profile': 'Mettre à Jour le Profil',
      'updating': 'Mise à jour...',
      'profile_updated': 'Profil mis à jour avec succès',
      'profile_update_error': 'Erreur lors de la mise à jour du profil',
      'please_enter_name': 'Veuillez entrer votre nom',
      'please_enter_email': 'Veuillez entrer votre e-mail',
      'invalid_email': 'Veuillez entrer un e-mail valide',
      
      // Reservations
      'my_reservations': 'Mes Réservations',
      'no_upcoming_reservations': 'Aucune réservation à venir',
      'make_reservation_prompt': 'Faites une réservation pour la voir ici',
      'cancel_reservation': 'Annuler la Réservation',
      'cancel_reservation_confirm': 'Êtes-vous sûr de vouloir annuler cette réservation ?',
      'keep_reservation': 'Garder la Réservation',
      'select_new_time_slot': 'Sélectionner un Nouveau Créneau',
      'modify': 'Modifier',
      'time_label': 'Heure',
      'price_label': 'Prix',
      'capacity_label': 'Capacité',
      'hours_until_meal': 'Heures jusqu\'au repas',
      'available_label': 'Disponible',
      'person_s': 'personne(s)',
      'cannot_cancel': 'Impossible d\'Annuler',
      'cannot_modify': 'Impossible de Modifier',
      'no_available_slots': 'Aucun Créneau Disponible',
      'no_alternative_slots': 'Aucun créneau alternatif disponible pour la modification.',
      'reservation_cancelled': 'Réservation annulée avec succès',
      'reservation_modified': 'Réservation modifiée avec succès',
      'failed_to_cancel': 'Échec de l\'annulation de la réservation',
      'failed_to_modify': 'Échec de la modification de la réservation',
      'error_cancelling': 'Erreur lors de l\'annulation de la réservation',
      'error_modifying': 'Erreur lors de la modification de la réservation',
      'failed_to_load_reservations': 'Échec du chargement des réservations',
      'error_loading_slots': 'Erreur lors du chargement des créneaux',
      'user_requested_cancellation': 'Annulation demandée par l\'utilisateur',
      'reservation_cancelled_status': 'Cette réservation a été annulée',
      'reservation_used_status': 'Cette réservation a été utilisée',
      'past_reservations_message': 'Les réservations passées ne peuvent pas être modifiées ou annulées',
      'two_hour_restriction': 'Impossible de modifier ou d\'annuler moins de 2 heures avant l\'heure du repas',
      'modification_not_available': 'Modification et annulation non disponibles',
      'cancellation_note': 'Note: Les annulations doivent être faites au moins 2 heures avant l\'heure du repas.',
      
      // Status labels
      'status_confirmed': 'Confirmé',
      'status_pending': 'En attente',
      'status_cancelled': 'Annulé',
      'status_used': 'Utilisé',
      'status_expired': 'Expiré',
    },
    
    'ar': {
      // Common
      'app_name': 'مطعم المعهد العالي للتكنولوجيا والاتصالات',
      'app_subtitle': 'مطعم جامعي المعهد العالي للتكنولوجيا',
      'system_name': 'نظام الحجز',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'ok': 'موافق',
      'retry': 'إعادة المحاولة',
      'back': 'رجوع',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      
      // Authentication
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'sign_in': 'دخول',
      'signing_in': 'جاري تسجيل الدخول...',
      'email_placeholder': 'your.email@isetcom.tn',
      'password_placeholder': 'كلمة المرور الخاصة بك',
      'forgot_password_title': 'نسيت كلمة المرور',
      'forgot_password_message': 'أدخل عنوان بريدك الإلكتروني لتلقي رابط إعادة التعيين.',
      'send': 'إرسال',
      'reset_email_sent': 'تم إرسال بريد إعادة التعيين! تحقق من صندوق الوارد.',
      'copyright': '© 2025 المعهد العالي للتكنولوجيا والاتصالات - جميع الحقوق محفوظة',
      
      // Home
      'greeting': 'مرحبا، {name}',
      'greeting_default': 'مرحبا، المستخدم',
      'class_label': 'الفصل: {class}',
      'current_balance': 'الرصيد الحالي',
      'tickets_available': '{count} تذكرة متاحة',
      'quick_actions': 'الإجراءات السريعة',
      'reserve_meal': 'احجز وجبة',
      'reserve_meal_subtitle': 'احجز وجبتك',
      'qr_code': 'رمز الاستجابة السريعة',
      'restaurant_access': 'دخول المطعم',
      'history': 'التاريخ',
      'your_reservations': 'حجوزاتك',
      'profile': 'الملف الشخصي',
      'my_information': 'معلوماتي',
      'todays_menu': 'قائمة اليوم',
      'no_menu_available': 'لا توجد قائمة متاحة اليوم',
      'data_refreshed': 'تم تحديث البيانات بنجاح',
      'no_confirmed_reservations': 'لم يتم العثور على حجوزات مؤكدة',
      'loading_user_data': 'جاري تحميل بيانات المستخدم...',
      'unable_to_load_user_data': 'غير قادر على تحميل بيانات المستخدم',
      
      // Profile
      'profile_settings': 'إعدادات الملف الشخصي',
      'login_to_view_profile': 'يرجى تسجيل الدخول لعرض ملفك الشخصي',
      'go_to_login': 'اذهب لتسجيل الدخول',
      'account_information': 'معلومات الحساب',
      'full_name': 'الاسم الكامل',
      'enter_full_name': 'أدخل اسمك الكامل',
      'enter_email': 'أدخل بريدك الإلكتروني',
      'phone_number': 'رقم الهاتف',
      'enter_phone': 'أدخل رقم هاتفك',
      'class': 'الفصل',
      'enter_class': 'أدخل فصلك (مثال: L3 INFO)',
      'preferences': 'التفضيلات',
      'language': 'اللغة',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'push_notifications': 'الإشعارات الفورية',
      'notification_subtitle': 'تلقي تذكيرات حول حجوزاتك',
      'update_profile': 'تحديث الملف الشخصي',
      'updating': 'جاري التحديث...',
      'profile_updated': 'تم تحديث الملف الشخصي بنجاح',
      'profile_update_error': 'خطأ في تحديث الملف الشخصي',
      'please_enter_name': 'يرجى إدخال اسمك',
      'please_enter_email': 'يرجى إدخال بريدك الإلكتروني',
      'invalid_email': 'يرجى إدخال بريد إلكتروني صحيح',
      
      // Reservations
      'my_reservations': 'حجوزاتي',
      'no_upcoming_reservations': 'لا توجد حجوزات قادمة',
      'make_reservation_prompt': 'قم بعمل حجز لرؤيته هنا',
      'cancel_reservation': 'إلغاء الحجز',
      'cancel_reservation_confirm': 'هل أنت متأكد من أنك تريد إلغاء هذا الحجز؟',
      'keep_reservation': 'الاحتفاظ بالحجز',
      'select_new_time_slot': 'اختر فترة زمنية جديدة',
      'modify': 'تعديل',
      'time_label': 'الوقت',
      'price_label': 'السعر',
      'capacity_label': 'السعة',
      'hours_until_meal': 'ساعات حتى الوجبة',
      'available_label': 'متاح',
      'person_s': 'شخص/أشخاص',
      'cannot_cancel': 'لا يمكن الإلغاء',
      'cannot_modify': 'لا يمكن التعديل',
      'no_available_slots': 'لا توجد فترات متاحة',
      'no_alternative_slots': 'لا توجد فترات زمنية بديلة متاحة للتعديل.',
      'reservation_cancelled': 'تم إلغاء الحجز بنجاح',
      'reservation_modified': 'تم تعديل الحجز بنجاح',
      'failed_to_cancel': 'فشل في إلغاء الحجز',
      'failed_to_modify': 'فشل في تعديل الحجز',
      'error_cancelling': 'خطأ في إلغاء الحجز',
      'error_modifying': 'خطأ في تعديل الحجز',
      'failed_to_load_reservations': 'فشل في تحميل الحجوزات',
      'error_loading_slots': 'خطأ في تحميل الفترات الزمنية',
      'user_requested_cancellation': 'طلب المستخدم الإلغاء',
      'reservation_cancelled_status': 'تم إلغاء هذا الحجز',
      'reservation_used_status': 'تم استخدام هذا الحجز',
      'past_reservations_message': 'لا يمكن تعديل أو إلغاء الحجوزات السابقة',
      'two_hour_restriction': 'لا يمكن التعديل أو الإلغاء قبل أقل من ساعتين من وقت الوجبة',
      'modification_not_available': 'التعديل والإلغاء غير متاحين',
      'cancellation_note': 'ملاحظة: يجب إجراء الإلغاءات قبل ساعتين على الأقل من وقت الوجبة.',
      
      // Status labels
      'status_confirmed': 'مؤكد',
      'status_pending': 'في الانتظار',
      'status_cancelled': 'ملغى',
      'status_used': 'مستخدم',
      'status_expired': 'منتهي الصلاحية',
    },
  };

  String translate(String key, {Map<String, String>? params}) {
    final languageCode = locale.languageCode;
    final translations = _localizedValues[languageCode] ?? _localizedValues['en']!;
    String text = translations[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return text;
  }

  // Convenience getters for common translations
  String get appName => translate('app_name');
  String get appSubtitle => translate('app_subtitle');
  String get systemName => translate('system_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get ok => translate('ok');
  String get retry => translate('retry');
  String get back => translate('back');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}