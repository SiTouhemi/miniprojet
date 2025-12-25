import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/app_service.dart';
import '/backend/services/time_slot_service.dart';
import '/backend/services/data_validation_service.dart';
import '/backend/services/sync_performance_monitor.dart';
import '/config/app_config.dart';
import '/utils/error_handler.dart';
import '/utils/performance_monitor.dart';
import '/utils/app_logger.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();
  factory FFAppState() => _instance;
  FFAppState._internal();

  // User session data
  UserRecord? _currentUser;
  UserRecord? get currentUser => _currentUser;
  
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Real-time listeners
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  StreamSubscription<QuerySnapshot>? _reservationsSubscription;
  StreamSubscription<QuerySnapshot>? _menuSubscription;
  StreamSubscription<List<TimeSlotRecord>>? _timeSlotsSubscription;

  // Network connectivity state
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Error state
  String? _lastError;
  String? get lastError => _lastError;

  // Data validation and performance monitoring
  final DataValidationService _validationService = DataValidationService.instance;
  final SyncPerformanceMonitor _performanceMonitor = SyncPerformanceMonitor.instance;
  DateTime? _lastDataValidation;
  Timer? _validationTimer;
  Timer? _performanceCleanupTimer;

  // Sync failure tracking
  final Map<String, int> _syncFailureCounts = {};
  final Map<String, DateTime> _lastSyncAttempts = {};
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // App settings
  AppSettingsRecord? _appSettings;
  AppSettingsRecord? get appSettings => _appSettings;

  // Current language
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  // Available time slots cache
  List<TimeSlotRecord> _availableTimeSlots = [];
  List<TimeSlotRecord> get availableTimeSlots => _availableTimeSlots;

  // User's reservations cache
  List<ReservationRecord> _userReservations = [];
  List<ReservationRecord> get userReservations => _userReservations;

  // Today's menu cache
  List<PlatRecord> _todaysMenu = [];
  List<PlatRecord> get todaysMenu => _todaysMenu;

  // Loading states
  bool _isLoadingSettings = false;
  bool get isLoadingSettings => _isLoadingSettings;

  bool _isLoadingTimeSlots = false;
  bool get isLoadingTimeSlots => _isLoadingTimeSlots;

  bool _isLoadingReservations = false;
  bool get isLoadingReservations => _isLoadingReservations;

  // Selected date for time slots
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Initialize app state with real-time listeners
  Future<void> initializeApp() async {
    try {
      // Start performance monitoring
      _performanceCleanupTimer = _performanceMonitor.startPeriodicCleanup();
      
      // Start periodic data validation
      _startPeriodicValidation();
      
      await loadAppSettings();
      await loadTodaysMenu();
      
      // Setup menu listener for real-time updates
      _setupMenuListener();
    } catch (e) {
      AppLogger.e('Error initializing app', error: e, tag: 'FFAppState');
      _setLastError('Failed to initialize app');
    }
  }

  // User authentication with real-time synchronization
  void setCurrentUser(UserRecord? user) {
    _currentUser = user;
    _isLoggedIn = user != null;
    _clearError();
    notifyListeners();
    
    if (user != null) {
      _setupUserDataListener(user.uid);
      _setupReservationsListener(user.uid);
    } else {
      _cleanupListeners();
      _userReservations.clear();
    }
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    _userReservations.clear();
    _cleanupListeners();
    _clearError();
    notifyListeners();
  }

  // Setup real-time listener for user data changes
  void _setupUserDataListener(String uid) {
    _userDataSubscription?.cancel();
    
    final operationId = _performanceMonitor.startSyncOperation('user_data_sync', metadata: {'uid': uid});
    
    _userDataSubscription = FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              try {
                final updatedUser = UserRecord.fromSnapshot(snapshot);
                if (_currentUser != null) {
                  // Check if critical data has changed
                  final balanceChanged = _currentUser!.pocket != updatedUser.pocket;
                  final ticketsChanged = _currentUser!.tickets != updatedUser.tickets;
                  final roleChanged = _currentUser!.role != updatedUser.role;
                  
                  _currentUser = updatedUser;
                  _clearError();
                  
                  // Log significant changes for debugging
                  if (balanceChanged) {
                    AppLogger.sync('User balance updated: ${updatedUser.pocket} DT', success: true);
                  }
                  if (ticketsChanged) {
                    AppLogger.sync('User tickets updated: ${updatedUser.tickets}', success: true);
                  }
                  if (roleChanged) {
                    AppLogger.i('User role changed to: ${updatedUser.role}', tag: 'FFAppState');
                  }
                  
                  // Validate data consistency
                  _validateUserDataConsistency(updatedUser);
                  
                  _performanceMonitor.completeSyncOperation(operationId, success: true, recordsProcessed: 1);
                  _syncFailureCounts.remove('user_data_sync');
                  
                  notifyListeners();
                }
              } catch (e) {
                _handleSyncError('user_data_sync', 'Error updating user data: $e', operationId);
              }
            } else {
              // User document was deleted - handle this case
              _handleSyncError('user_data_sync', 'User document not found. Please contact support.', operationId);
            }
          },
          onError: (error) {
            _handleSyncError('user_data_sync', 'User data sync error: $error', operationId);
          },
        );
  }

  // Setup real-time listener for user reservations
  void _setupReservationsListener(String uid) {
    _reservationsSubscription?.cancel();
    
    final operationId = _performanceMonitor.startSyncOperation('reservations_sync', metadata: {'uid': uid});
    
    _reservationsSubscription = FirebaseFirestore.instance
        .collection('reservation')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              _userReservations = snapshot.docs
                  .map((doc) => ReservationRecord.fromSnapshot(doc))
                  .toList();
              _clearError();
              
              _performanceMonitor.completeSyncOperation(operationId, success: true, recordsProcessed: snapshot.docs.length);
              _syncFailureCounts.remove('reservations_sync');
              
              notifyListeners();
            } catch (e) {
              _handleSyncError('reservations_sync', 'Error updating reservations: $e', operationId);
            }
          },
          onError: (error) {
            _handleSyncError('reservations_sync', 'Reservations sync error: $error', operationId);
          },
        );
  }

  // Setup real-time listener for today's menu
  void _setupMenuListener() {
    _menuSubscription?.cancel();
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final operationId = _performanceMonitor.startSyncOperation('menu_sync', metadata: {'date': today.toIso8601String()});
    
    _menuSubscription = FirebaseFirestore.instance
        .collection('plat')
        .where('availableDate', isGreaterThanOrEqualTo: startOfDay)
        .where('availableDate', isLessThanOrEqualTo: endOfDay)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              _todaysMenu = snapshot.docs
                  .map((doc) => PlatRecord.fromSnapshot(doc))
                  .toList();
              _clearError();
              
              _performanceMonitor.completeSyncOperation(operationId, success: true, recordsProcessed: snapshot.docs.length);
              _syncFailureCounts.remove('menu_sync');
              
              notifyListeners();
            } catch (e) {
              _handleSyncError('menu_sync', 'Error updating menu: $e', operationId);
            }
          },
          onError: (error) {
            _handleSyncError('menu_sync', 'Menu sync error: $error', operationId);
          },
        );
  }

  // Cleanup all listeners
  void _cleanupListeners() {
    _userDataSubscription?.cancel();
    _reservationsSubscription?.cancel();
    _menuSubscription?.cancel();
    _timeSlotsSubscription?.cancel();
    
    _userDataSubscription = null;
    _reservationsSubscription = null;
    _menuSubscription = null;
    _timeSlotsSubscription = null;
  }

  // Enhanced sync error handling with retry mechanism
  void _handleSyncError(String syncType, String error, String? operationId) {
    AppLogger.e('FFAppState Sync Error ($syncType): $error', tag: 'FFAppState');
    
    // Complete performance monitoring
    if (operationId != null) {
      _performanceMonitor.completeSyncOperation(operationId, success: false, errorMessage: error);
    }
    
    // Track failure count
    _syncFailureCounts[syncType] = (_syncFailureCounts[syncType] ?? 0) + 1;
    _lastSyncAttempts[syncType] = DateTime.now();
    
    // Set appropriate error message based on sync type
    String userFriendlyError;
    switch (syncType) {
      case 'user_data_sync':
        userFriendlyError = 'Erreur de synchronisation des données utilisateur';
        break;
      case 'reservations_sync':
        userFriendlyError = 'Erreur de synchronisation des réservations';
        break;
      case 'menu_sync':
        userFriendlyError = 'Erreur de synchronisation du menu';
        break;
      case 'time_slots_sync':
        userFriendlyError = 'Erreur de synchronisation des créneaux';
        break;
      default:
        userFriendlyError = 'Erreur de synchronisation des données';
    }
    
    _setLastError(userFriendlyError);
    
    // Attempt retry if under limit
    final failureCount = _syncFailureCounts[syncType] ?? 0;
    if (failureCount < maxSyncRetries) {
      Timer(syncRetryDelay, () => _retrySyncOperation(syncType));
    } else {
      _setOfflineMode();
    }
    
    notifyListeners();
  }

  // Retry sync operation after failure
  void _retrySyncOperation(String syncType) {
    if (_currentUser == null) return;
    
    AppLogger.d('Retrying sync operation: $syncType', tag: 'FFAppState');
    
    switch (syncType) {
      case 'user_data_sync':
        _setupUserDataListener(_currentUser!.uid);
        break;
      case 'reservations_sync':
        _setupReservationsListener(_currentUser!.uid);
        break;
      case 'menu_sync':
        _setupMenuListener();
        break;
      case 'time_slots_sync':
        loadTimeSlots(_selectedDate);
        break;
    }
  }

  // Validate user data consistency
  Future<void> _validateUserDataConsistency(UserRecord user) async {
    try {
      final validation = await _validationService.validateUserData(user, user.uid);
      if (!validation.isValid) {
        AppLogger.w('User data validation failed: ${validation.errors}', tag: 'FFAppState');
        // Log validation errors but don't show to user unless critical
        if (validation.errors.any((error) => error.contains('Balance') || error.contains('Role'))) {
          _setLastError('Incohérence détectée dans les données. Actualisation en cours...');
          // Force refresh from Firestore
          await refreshUserData();
        }
      }
    } catch (e) {
      AppLogger.e('Data validation error', error: e, tag: 'FFAppState');
    }
  }

  // Start periodic data validation
  void _startPeriodicValidation() {
    _validationTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      if (_currentUser != null) {
        await _validateAllData();
      }
    });
  }

  // Validate all data consistency
  Future<void> _validateAllData() async {
    if (_currentUser == null) return;
    
    try {
      final validation = await _validationService.validateAllUserData(
        _currentUser,
        _userReservations,
        _todaysMenu,
        _availableTimeSlots,
        _selectedDate,
      );
      
      _lastDataValidation = DateTime.now();
      
      if (!validation.isValid) {
        AppLogger.w('Comprehensive data validation failed:', tag: 'FFAppState');
        for (final error in validation.allErrors) {
          AppLogger.d('  - $error', tag: 'FFAppState');
        }
        
        // If critical data is inconsistent, force refresh
        if (validation.userValidation.errors.isNotEmpty) {
          await refreshUserData();
        }
      }
    } catch (e) {
      AppLogger.e('Comprehensive data validation error', error: e, tag: 'FFAppState');
    }
  }

  // Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Error handling
  void _handleError(String error) {
    _lastError = error;
    AppLogger.e('FFAppState Error: $error', tag: 'FFAppState');
    notifyListeners();
  }

  void setLastError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _setLastError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Network state management with connectivity checking
  void _setOfflineMode() {
    if (_isOnline) {
      _isOnline = false;
      AppLogger.i('App switched to offline mode', tag: 'FFAppState');
      notifyListeners();
    }
  }

  void _setOnlineMode() {
    if (!_isOnline) {
      _isOnline = true;
      _clearError();
      AppLogger.i('App switched to online mode', tag: 'FFAppState');
      notifyListeners();
    }
  }

  // Enhanced retry connection with network checking
  Future<void> retryConnection() async {
    try {
      // Check network connectivity first
      final hasNetwork = await _checkNetworkConnectivity();
      if (!hasNetwork) {
        _setLastError('Aucune connexion réseau détectée');
        return;
      }
      
      // Test connection by making a simple Firestore query
      await FirebaseFirestore.instance
          .collection('app_settings')
          .limit(1)
          .get();
      
      _setOnlineMode();
      
      // Reset failure counts
      _syncFailureCounts.clear();
      
      // Re-establish listeners if user is logged in
      if (_currentUser != null) {
        _setupUserDataListener(_currentUser!.uid);
        _setupReservationsListener(_currentUser!.uid);
      }
      _setupMenuListener();
      
      AppLogger.i('Connection restored and listeners re-established', tag: 'FFAppState');
    } catch (e) {
      _handleError('Connection retry failed: $e');
    }
  }

  // Initialize user data synchronization after authentication
  Future<void> initializeUserSync(String uid) async {
    try {
      // First, get the current user document
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final user = UserRecord.fromSnapshot(userDoc);
        setCurrentUser(user);
        
        // Ensure all real-time listeners are active
        _setupUserDataListener(uid);
        _setupReservationsListener(uid);
        
        AppLogger.i('User data synchronization initialized for: ${user.nom}', tag: 'FFAppState');
      } else {
        _handleError('User document not found. Creating new document...');
        // The auth service should handle creating the user document
      }
    } catch (e) {
      _handleError('Failed to initialize user sync: $e');
    }
  }

  // Force refresh user data from Firestore with validation
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;
    
    final operationId = _performanceMonitor.startSyncOperation('user_data_refresh', metadata: {'uid': _currentUser!.uid});
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(_currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final updatedUser = UserRecord.fromSnapshot(userDoc);
        
        // Validate the refreshed data
        final validation = _validationService.validateNoHardcodedData(updatedUser);
        if (!validation.isValid) {
          AppLogger.w('Potentially hardcoded data detected: ${validation.errors}', tag: 'FFAppState');
        }
        
        _currentUser = updatedUser;
        _clearError();
        
        _performanceMonitor.completeSyncOperation(operationId, success: true, recordsProcessed: 1);
        
        notifyListeners();
        AppLogger.i('User data refreshed successfully', tag: 'FFAppState');
      } else {
        _performanceMonitor.completeSyncOperation(operationId, success: false, errorMessage: 'User document not found');
        _handleError('Document utilisateur introuvable');
      }
    } catch (e) {
      _performanceMonitor.completeSyncOperation(operationId, success: false, errorMessage: e.toString());
      _handleError('Failed to refresh user data: $e');
    }
  }

  // Retry connection and re-establish listeners (duplicate method removed)

  // App settings management
  Future<void> loadAppSettings() async {
    _isLoadingSettings = true;
    notifyListeners();

    try {
      _appSettings = await AppService.instance.getAppSettings();
    } catch (e) {
      AppLogger.e('Error loading app settings', error: e, tag: 'FFAppState');
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> updateAppSettings(Map<String, dynamic> updates) async {
    final success = await AppService.instance.updateAppSettings(updates);
    if (success) {
      await loadAppSettings(); // Refresh settings
    }
  }

  // Language management
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
    
    // Update user preference if logged in
    if (_currentUser != null) {
      _currentUser!.reference.update({'language': languageCode});
    }
  }

  // Time slots management with real-time updates and enhanced error handling
  // Requirement 4.5: Update time slot availability in real-time using Firestore listeners
  Future<void> loadTimeSlots(DateTime date) async {
    _selectedDate = date;
    _isLoadingTimeSlots = true;
    notifyListeners();

    final operationId = _performanceMonitor.startSyncOperation('time_slots_sync', metadata: {'date': date.toIso8601String()});

    try {
      // Cancel existing listener if any
      _timeSlotsSubscription?.cancel();
      
      // Setup real-time listener for time slots
      // Requirement 4.1: Query Firestore for slots matching the selected date
      _timeSlotsSubscription = TimeSlotService.instance
          .getAvailableTimeSlotsStream(date)
          .listen(
            (timeSlots) {
              _availableTimeSlots = timeSlots;
              _isLoadingTimeSlots = false;
              _clearError();
              
              _performanceMonitor.completeSyncOperation(operationId, success: true, recordsProcessed: timeSlots.length);
              _syncFailureCounts.remove('time_slots_sync');
              
              notifyListeners();
              
              // Requirement 4.6: Admin modifications immediately reflect to all connected clients
              AppLogger.sync('Time slots updated: ${timeSlots.length} slots available', success: true, recordCount: timeSlots.length);
            },
            onError: (error) {
              _handleSyncError('time_slots_sync', 'Time slots sync error: $error', operationId);
              _isLoadingTimeSlots = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _performanceMonitor.completeSyncOperation(operationId, success: false, errorMessage: e.toString());
      _handleError('Error setting up time slots sync: $e');
      _availableTimeSlots = [];
      _isLoadingTimeSlots = false;
      notifyListeners();
    }
  }

  void refreshTimeSlots() {
    loadTimeSlots(_selectedDate);
  }

  // User reservations management with real-time sync
  Future<void> loadUserReservations() async {
    if (_currentUser == null) return;

    _isLoadingReservations = true;
    notifyListeners();

    try {
      // Setup real-time listener instead of one-time load
      _setupReservationsListener(_currentUser!.uid);
    } catch (e) {
      _handleError('Error setting up reservations sync: $e');
      // Fallback to one-time load if real-time fails
      try {
        _userReservations = await AppService.instance.getUserReservations(_currentUser!.uid);
      } catch (fallbackError) {
        _handleError('Error loading user reservations: $fallbackError');
        _userReservations = [];
      }
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
    }
  }

  void addReservation(ReservationRecord reservation) {
    _userReservations.insert(0, reservation);
    notifyListeners();
  }

  void updateReservation(ReservationRecord updatedReservation) {
    final index = _userReservations.indexWhere((r) => r.reference.id == updatedReservation.reference.id);
    if (index != -1) {
      _userReservations[index] = updatedReservation;
      notifyListeners();
    }
  }

  void removeReservation(String reservationId) {
    _userReservations.removeWhere((r) => r.reference.id == reservationId);
    notifyListeners();
  }

  // Menu management with real-time sync
  Future<void> loadTodaysMenu() async {
    try {
      // Setup real-time listener for menu updates
      _setupMenuListener();
    } catch (e) {
      _handleError('Error setting up menu sync: $e');
      // Fallback to one-time load if real-time fails
      try {
        _todaysMenu = await AppService.instance.getTodaysMenu();
        notifyListeners();
      } catch (fallbackError) {
        _handleError('Error loading today\'s menu: $fallbackError');
        _todaysMenu = [];
      }
    }
  }

  void refreshMenu() {
    // Real-time listener will automatically update, but we can force a refresh
    loadTodaysMenu();
  }

  // Utility methods
  String getAppName() {
    return _appSettings?.appName ?? 'ISET Com Restaurant';
  }

  String getWelcomeMessage() {
    return _appSettings?.welcomeMessage ?? 'Welcome to our restaurant reservation system';
  }

  String getContactEmail() {
    return _appSettings?.contactEmail ?? 'contact@isetcom.tn';
  }

  String getContactPhone() {
    return _appSettings?.contactPhone ?? '+216 XX XXX XXX';
  }

  double getDefaultMealPrice() {
    return _appSettings?.defaultMealPrice ?? 5.0;
  }

  int getMaxReservationsPerUser() {
    return _appSettings?.maxReservationsPerUser ?? 3;
  }

  // Get user's active reservations count
  int getActiveReservationsCount() {
    if (_currentUser == null) return 0;
    
    final now = DateTime.now();
    return _userReservations.where((reservation) => 
      reservation.status == 'confirmed' && 
      reservation.creneaux != null && 
      reservation.creneaux!.isAfter(now)
    ).length;
  }

  // Check if user can make more reservations
  bool canMakeMoreReservations() {
    return getActiveReservationsCount() < getMaxReservationsPerUser();
  }

  // Get upcoming reservations
  List<ReservationRecord> getUpcomingReservations() {
    final now = DateTime.now();
    return _userReservations.where((reservation) => 
      reservation.status == 'confirmed' && 
      reservation.creneaux != null && 
      reservation.creneaux!.isAfter(now)
    ).toList()..sort((a, b) => a.creneaux!.compareTo(b.creneaux!));
  }

  // Get past reservations
  List<ReservationRecord> getPastReservations() {
    final now = DateTime.now();
    return _userReservations.where((reservation) => 
      reservation.creneaux != null && 
      reservation.creneaux!.isBefore(now)
    ).toList()..sort((a, b) => b.creneaux!.compareTo(a.creneaux!));
  }

  // Clear all cached data and cleanup listeners
  void clearCache() {
    _availableTimeSlots.clear();
    _userReservations.clear();
    _todaysMenu.clear();
    _cleanupListeners();
    notifyListeners();
  }

  // Refresh all data with real-time sync
  Future<void> refreshAll() async {
    await Future.wait([
      loadAppSettings(),
      loadTodaysMenu(),
      if (_currentUser != null) loadUserReservations(),
      loadTimeSlots(_selectedDate),
    ]);
  }

  // Dispose method to cleanup listeners and timers
  void dispose() {
    _cleanupListeners();
    _validationTimer?.cancel();
    _performanceCleanupTimer?.cancel();
    super.dispose();
  }

  // Get sync performance stats for debugging
  Map<String, dynamic> getSyncPerformanceStats() {
    return _performanceMonitor.getDetailedMetrics();
  }

  // Get sync health status
  SyncHealthStatus getSyncHealthStatus() {
    return _performanceMonitor.getOverallHealth();
  }
}