import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '/config/app_config.dart';

/// Log levels for the application
enum LogLevel { debug, info, warning, error, critical }

/// Centralized logging service for the ISET Restaurant application.
/// 
/// Features:
/// - Multiple log levels (debug, info, warning, error, critical)
/// - Automatic environment-based filtering (debug logs disabled in production)
/// - Timestamps, class/method names, and line numbers
/// - Emoji-based formatting for development readability
/// - Optional remote error reporting (Firebase Crashlytics integration ready)
/// 
/// Usage:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.w('Warning message');
/// AppLogger.e('Error message', error: exception, stackTrace: stackTrace);
/// AppLogger.critical('Critical error', error: exception, stackTrace: stackTrace);
/// ```
class AppLogger {
  static AppLogger? _instance;
  static late Logger _logger;
  static bool _initialized = false;
  
  // Configuration
  static bool _enableRemoteLogging = false;
  static bool _enableFileLogging = false;
  static LogLevel _minimumLevel = LogLevel.debug;
  
  AppLogger._internal() {
    _initializeLogger();
  }
  
  factory AppLogger() {
    _instance ??= AppLogger._internal();
    return _instance!;
  }
  
  /// Initialize the logger with custom configuration
  static void initialize({
    bool enableRemoteLogging = false,
    bool enableFileLogging = false,
    LogLevel minimumLevel = LogLevel.debug,
  }) {
    _enableRemoteLogging = enableRemoteLogging;
    _enableFileLogging = enableFileLogging;
    _minimumLevel = minimumLevel;
    _initializeLogger();
  }
  
  static void _initializeLogger() {
    if (_initialized) return;
    
    _logger = Logger(
      filter: _AppLogFilter(),
      printer: _AppLogPrinter(),
      output: _AppLogOutput(),
      level: AppConfig.isProduction ? Level.info : Level.debug,
    );
    
    _initialized = true;
  }
  
  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      _instance ??= AppLogger._internal();
    }
  }
  
  // ============================================
  // PUBLIC LOGGING METHODS
  // ============================================
  
  /// Debug log - for development debugging
  /// Automatically disabled in production
  static void d(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _ensureInitialized();
    if (_shouldLog(LogLevel.debug)) {
      final formattedMessage = _formatMessage(message, tag: tag);
      _logger.d(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Info log - for general information
  static void i(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _ensureInitialized();
    if (_shouldLog(LogLevel.info)) {
      final formattedMessage = _formatMessage(message, tag: tag);
      _logger.i(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Warning log - for potential issues
  static void w(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _ensureInitialized();
    if (_shouldLog(LogLevel.warning)) {
      final formattedMessage = _formatMessage(message, tag: tag);
      _logger.w(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Error log - for errors and exceptions
  static void e(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _ensureInitialized();
    if (_shouldLog(LogLevel.error)) {
      final formattedMessage = _formatMessage(message, tag: tag);
      _logger.e(formattedMessage, error: error, stackTrace: stackTrace);
      
      // Send to remote logging if enabled
      if (_enableRemoteLogging) {
        _sendToRemote(LogLevel.error, message, error, stackTrace);
      }
    }
  }
  
  /// Critical log - for critical errors that need immediate attention
  /// Always sent to remote logging if enabled
  static void critical(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _ensureInitialized();
    final formattedMessage = _formatMessage(message, tag: tag);
    _logger.f(formattedMessage, error: error, stackTrace: stackTrace);
    
    // Always send critical errors to remote logging
    if (_enableRemoteLogging) {
      _sendToRemote(LogLevel.critical, message, error, stackTrace);
    }
  }
  
  // ============================================
  // SPECIALIZED LOGGING METHODS
  // ============================================
  
  /// Log authentication events
  static void auth(String message, {bool success = true, String? userId}) {
    final emoji = success ? '🔐' : '❌';
    final tag = 'AUTH';
    if (success) {
      i('$emoji $message', tag: tag);
    } else {
      w('$emoji $message', tag: tag);
    }
  }
  
  /// Log network/API events
  static void network(String message, {bool success = true, int? statusCode}) {
    final emoji = success ? '🌐' : '📡';
    final tag = 'NETWORK';
    final statusInfo = statusCode != null ? ' [Status: $statusCode]' : '';
    if (success) {
      d('$emoji $message$statusInfo', tag: tag);
    } else {
      w('$emoji $message$statusInfo', tag: tag);
    }
  }
  
  /// Log database/Firestore events
  static void database(String message, {String? collection, String? operation}) {
    final tag = 'DATABASE';
    final details = [
      if (collection != null) 'collection: $collection',
      if (operation != null) 'operation: $operation',
    ].join(', ');
    d('🗄️ $message${details.isNotEmpty ? ' ($details)' : ''}', tag: tag);
  }
  
  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? params}) {
    final tag = 'USER_ACTION';
    final paramsStr = params != null ? ' $params' : '';
    d('👤 $action$paramsStr', tag: tag);
  }
  
  /// Log performance metrics
  static void performance(String metric, {Duration? duration, int? value}) {
    final tag = 'PERFORMANCE';
    final details = [
      if (duration != null) '${duration.inMilliseconds}ms',
      if (value != null) 'value: $value',
    ].join(', ');
    d('⚡ $metric${details.isNotEmpty ? ' ($details)' : ''}', tag: tag);
  }
  
  /// Log sync operations
  static void sync(String message, {bool success = true, int? recordCount}) {
    final emoji = success ? '🔄' : '⚠️';
    final tag = 'SYNC';
    final countInfo = recordCount != null ? ' [$recordCount records]' : '';
    if (success) {
      d('$emoji $message$countInfo', tag: tag);
    } else {
      w('$emoji $message$countInfo', tag: tag);
    }
  }
  
  /// Log navigation events
  static void navigation(String route, {String? from}) {
    final tag = 'NAV';
    final fromInfo = from != null ? ' (from: $from)' : '';
    d('🧭 Navigating to: $route$fromInfo', tag: tag);
  }
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  static bool _shouldLog(LogLevel level) {
    if (AppConfig.isProduction && level == LogLevel.debug) {
      return false;
    }
    return level.index >= _minimumLevel.index;
  }
  
  static String _formatMessage(String message, {String? tag}) {
    if (tag != null) {
      return '[$tag] $message';
    }
    return message;
  }
  
  /// Send error to remote logging service (Firebase Crashlytics)
  static Future<void> _sendToRemote(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    // TODO: Implement Firebase Crashlytics integration
    // Example:
    // if (error != null) {
    //   await FirebaseCrashlytics.instance.recordError(
    //     error,
    //     stackTrace,
    //     reason: message,
    //     fatal: level == LogLevel.critical,
    //   );
    // } else {
    //   await FirebaseCrashlytics.instance.log(message);
    // }
  }
  
  /// Enable/disable remote logging at runtime
  static void setRemoteLogging(bool enabled) {
    _enableRemoteLogging = enabled;
  }
  
  /// Set minimum log level at runtime
  static void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }
  
  /// Get current configuration
  static Map<String, dynamic> getConfiguration() {
    return {
      'initialized': _initialized,
      'enableRemoteLogging': _enableRemoteLogging,
      'enableFileLogging': _enableFileLogging,
      'minimumLevel': _minimumLevel.name,
      'isProduction': AppConfig.isProduction,
    };
  }
}

/// Custom log filter based on environment
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (AppConfig.isProduction) {
      // In production, only log info and above
      return event.level.index >= Level.info.index;
    }
    // In development, log everything
    return true;
  }
}

/// Custom log printer with emojis and formatting
class _AppLogPrinter extends LogPrinter {
  static final Map<Level, String> _levelEmojis = {
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💀',
  };
  
  static final Map<Level, String> _levelPrefixes = {
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARN',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  @override
  List<String> log(LogEvent event) {
    final emoji = _levelEmojis[event.level] ?? '📝';
    final prefix = _levelPrefixes[event.level] ?? 'LOG';
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final message = event.message;
    
    final lines = <String>[];
    
    // Main log line
    lines.add('$emoji [$timestamp] $prefix: $message');
    
    // Add error details if present
    if (event.error != null) {
      lines.add('   └─ Error: ${event.error}');
    }
    
    // Add stack trace for errors (limited lines in production)
    if (event.stackTrace != null && event.level.index >= Level.error.index) {
      final stackLines = event.stackTrace.toString().split('\n');
      final maxLines = AppConfig.isProduction ? 5 : 10;
      for (var i = 0; i < stackLines.length && i < maxLines; i++) {
        if (stackLines[i].trim().isNotEmpty) {
          lines.add('   │ ${stackLines[i]}');
        }
      }
      if (stackLines.length > maxLines) {
        lines.add('   └─ ... and ${stackLines.length - maxLines} more lines');
      }
    }
    
    return lines;
  }
}

/// Custom log output
class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      // Use debugPrint for better handling of long messages
      debugPrint(line);
    }
  }
}
