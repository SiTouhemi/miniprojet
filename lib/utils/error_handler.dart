import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/config/app_config.dart';

/// Enhanced error handler with French error messages and retry mechanisms
/// Implements requirements 2.6, 6.1, 6.2, 6.3, 6.4, 6.5 for error handling and user feedback
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  static ErrorHandler get instance => _instance;

  // Error tracking
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};
  final List<ErrorLog> _errorHistory = [];
  
  static const int maxErrorHistory = 100;
  static const Duration errorCooldown = Duration(seconds: 30);

  /// Handle and format error messages in French
  /// Requirement 6.1: Standardize error messages to be in French
  String handleError(dynamic error, {String? context, bool logError = true}) {
    final errorMessage = _extractErrorMessage(error);
    final frenchMessage = _translateToFrench(errorMessage, context);
    
    if (logError) {
      _logError(errorMessage, frenchMessage, context);
    }
    
    return frenchMessage;
  }

  /// Get user-friendly error message with retry options
  /// Requirement 6.2: Add retry mechanisms for failed data loads
  ErrorResult getErrorWithRetry(dynamic error, {
    String? context,
    VoidCallback? onRetry,
    bool canRetry = true,
  }) {
    final frenchMessage = handleError(error, context: context);
    final errorType = _categorizeError(error);
    
    return ErrorResult(
      message: frenchMessage,
      type: errorType,
      canRetry: canRetry && _canRetry(errorType),
      onRetry: onRetry,
      isNetworkError: _isNetworkError(error),
      isTemporary: _isTemporaryError(error),
    );
  }

  /// Show error with appropriate UI feedback
  /// Requirement 6.3: Implement graceful offline mode handling
  void showError(BuildContext context, dynamic error, {
    String? contextInfo,
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    final errorResult = getErrorWithRetry(error, context: contextInfo, onRetry: onRetry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(errorResult.type),
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                errorResult.message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(errorResult.type),
        duration: duration ?? Duration(seconds: errorResult.isTemporary ? 3 : 5),
        action: errorResult.canRetry && errorResult.onRetry != null
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: errorResult.onRetry!,
              )
            : null,
      ),
    );
  }

  /// Get loading indicator with error fallback
  /// Requirement 6.5: Add clear loading indicators for all async operations
  Widget buildLoadingWithError({
    required bool isLoading,
    String? error,
    required Widget child,
    VoidCallback? onRetry,
    String loadingMessage = 'Chargement...',
  }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              loadingMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return child;
  }

  /// Build offline indicator widget
  /// Requirement 6.4: Add clear loading indicators for all async operations
  Widget buildOfflineIndicator({bool isOffline = false}) {
    if (!isOffline) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.0),
      color: Colors.orange[600],
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16.0,
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Mode hors ligne - Données mises en cache affichées',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get error statistics for debugging
  Map<String, dynamic> getErrorStatistics() {
    final now = DateTime.now();
    final recentErrors = _errorHistory.where((error) => 
      now.difference(error.timestamp) < Duration(hours: 24)
    ).toList();

    final errorsByType = <String, int>{};
    final errorsByContext = <String, int>{};

    for (final error in recentErrors) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
      if (error.context != null) {
        errorsByContext[error.context!] = (errorsByContext[error.context!] ?? 0) + 1;
      }
    }

    return {
      'totalErrors24h': recentErrors.length,
      'errorsByType': errorsByType,
      'errorsByContext': errorsByContext,
      'mostCommonError': errorsByType.isNotEmpty 
          ? errorsByType.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  // Legacy methods for backward compatibility
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('ERROR: $error');
      if (stackTrace != null) {
        debugPrint('STACK TRACE: $stackTrace');
      }
      if (context != null) {
        debugPrint('CONTEXT: $context');
      }
    }
    
    // Use new error handling
    instance.handleError(error, context: context);
    
    // In production, send to crash reporting service
    if (AppConfig.isProduction && AppConfig.enableCrashReporting) {
      // TODO: Send to Firebase Crashlytics
      // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    return instance.handleError(error, logError: false);
  }

  static bool isNetworkError(dynamic error) {
    return instance._isNetworkError(error);
  }

  static bool isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
           errorString.contains('unauthorized') ||
           errorString.contains('authentication') ||
           errorString.contains('token');
  }

  // Private helper methods

  String _extractErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      return error.message ?? error.code;
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  String _translateToFrench(String errorMessage, String? context) {
    // Network errors
    if (_isNetworkError(errorMessage)) {
      return 'Erreur de connexion. Vérifiez votre réseau et réessayez.';
    }

    // Firestore errors
    if (errorMessage.contains('permission-denied')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    }
    if (errorMessage.contains('not-found')) {
      return 'Données introuvables. Elles ont peut-être été supprimées.';
    }
    if (errorMessage.contains('already-exists')) {
      return 'Ces données existent déjà.';
    }
    if (errorMessage.contains('deadline-exceeded') || errorMessage.contains('timeout')) {
      return 'Délai d\'attente dépassé. Veuillez réessayer.';
    }
    if (errorMessage.contains('unavailable')) {
      return 'Service temporairement indisponible. Réessayez dans quelques instants.';
    }

    // Authentication errors
    if (errorMessage.contains('user-not-found')) {
      return 'Utilisateur introuvable. Vérifiez votre adresse e-mail.';
    }
    if (errorMessage.contains('wrong-password')) {
      return 'Mot de passe incorrect.';
    }
    if (errorMessage.contains('invalid-email')) {
      return 'Adresse e-mail invalide.';
    }
    if (errorMessage.contains('user-disabled')) {
      return 'Ce compte a été désactivé.';
    }
    if (errorMessage.contains('too-many-requests')) {
      return 'Trop de tentatives. Attendez avant de réessayer.';
    }

    // Data validation errors
    if (errorMessage.contains('validation')) {
      return 'Données invalides. Vérifiez les informations saisies.';
    }

    // Context-specific errors
    if (context != null) {
      switch (context.toLowerCase()) {
        case 'user_data':
          return 'Erreur lors du chargement des données utilisateur.';
        case 'reservations':
          return 'Erreur lors du chargement des réservations.';
        case 'menu':
          return 'Erreur lors du chargement du menu.';
        case 'time_slots':
          return 'Erreur lors du chargement des créneaux horaires.';
        case 'payment':
          return 'Erreur lors du traitement du paiement.';
        default:
          break;
      }
    }

    // Generic error with original message if no translation found
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  ErrorType _categorizeError(dynamic error) {
    final message = _extractErrorMessage(error);
    
    if (_isNetworkError(message)) return ErrorType.network;
    if (message.contains('permission') || message.contains('unauthorized')) return ErrorType.permission;
    if (message.contains('not-found')) return ErrorType.notFound;
    if (message.contains('timeout') || message.contains('deadline')) return ErrorType.timeout;
    if (message.contains('validation') || message.contains('invalid')) return ErrorType.validation;
    
    return ErrorType.unknown;
  }

  bool _isNetworkError(dynamic error) {
    final message = _extractErrorMessage(error);
    return message.contains('network') || 
           message.contains('connection') || 
           message.contains('internet') ||
           message.contains('offline') ||
           message.contains('dns') ||
           message.contains('host');
  }

  bool _isTemporaryError(dynamic error) {
    final message = _extractErrorMessage(error);
    return message.contains('timeout') ||
           message.contains('unavailable') ||
           message.contains('deadline-exceeded') ||
           message.contains('too-many-requests') ||
           _isNetworkError(error);
  }

  bool _canRetry(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
      case ErrorType.unknown:
        return true;
      case ErrorType.permission:
      case ErrorType.validation:
        return false;
      case ErrorType.notFound:
        return true; // Might be temporary
    }
  }

  void _logError(String originalMessage, String frenchMessage, String? context) {
    final errorLog = ErrorLog(
      originalMessage: originalMessage,
      frenchMessage: frenchMessage,
      context: context,
      timestamp: DateTime.now(),
      type: _categorizeError(originalMessage).toString(),
    );

    _errorHistory.add(errorLog);
    
    // Keep only recent errors
    if (_errorHistory.length > maxErrorHistory) {
      _errorHistory.removeAt(0);
    }

    // Track error frequency
    final key = '$context:$originalMessage';
    _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
    _lastErrorTimes[key] = DateTime.now();

    // Log to console for debugging
    if (AppConfig.enableDebugLogging) {
      debugPrint('Error [${context ?? 'Unknown'}]: $originalMessage -> $frenchMessage');
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.permission:
        return Icons.lock;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange[700]!;
      case ErrorType.permission:
        return Colors.red[700]!;
      case ErrorType.notFound:
        return Colors.blue[700]!;
      case ErrorType.timeout:
        return Colors.amber[700]!;
      case ErrorType.validation:
        return Colors.purple[700]!;
      case ErrorType.unknown:
        return Colors.grey[700]!;
    }
  }
}

/// Error result with retry information
class ErrorResult {
  final String message;
  final ErrorType type;
  final bool canRetry;
  final VoidCallback? onRetry;
  final bool isNetworkError;
  final bool isTemporary;

  ErrorResult({
    required this.message,
    required this.type,
    required this.canRetry,
    this.onRetry,
    required this.isNetworkError,
    required this.isTemporary,
  });
}

/// Error type enumeration
enum ErrorType {
  network,
  permission,
  notFound,
  timeout,
  validation,
  unknown,
}

/// Error log entry
class ErrorLog {
  final String originalMessage;
  final String frenchMessage;
  final String? context;
  final DateTime timestamp;
  final String type;

  ErrorLog({
    required this.originalMessage,
    required this.frenchMessage,
    this.context,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'originalMessage': originalMessage,
      'frenchMessage': frenchMessage,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }
}