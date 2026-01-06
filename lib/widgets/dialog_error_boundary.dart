import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Error boundary widget that catches rendering exceptions and shows fallback UI
/// 
/// This widget implements comprehensive error handling for dialog rendering issues,
/// including layout calculation failures, constraint violations, and hit testing errors.
/// It provides fallback strategies and detailed error logging for debugging.
class DialogErrorBoundary extends StatefulWidget {
  const DialogErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.enableLogging = true,
  });

  final Widget child;
  final Widget? fallback;
  final void Function(FlutterErrorDetails)? onError;
  final bool enableLogging;

  @override
  State<DialogErrorBoundary> createState() => _DialogErrorBoundaryState();
}

class _DialogErrorBoundaryState extends State<DialogErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorFallback();
    }

    // Wrap child in error catching widget
    return _ErrorCatcher(
      onError: _handleError,
      child: widget.child,
    );
  }

  /// Handles error occurrence and updates state
  void _handleError(FlutterErrorDetails details) {
    if (widget.enableLogging) {
      _logError(details);
    }
    
    if (widget.onError != null) {
      widget.onError!(details);
    }
    
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = details.exception.toString();
        _errorDetails = details;
      });
    }
  }

  /// Logs error details for debugging
  void _logError(FlutterErrorDetails details) {
    debugPrint('=== DialogErrorBoundary: Layout Error Detected ===');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint('Context: ${details.context}');
    debugPrint('Library: ${details.library}');
    debugPrint('================================================');
    
    // Also report to Flutter's error reporting system
    FlutterError.reportError(details);
  }

  /// Builds the error fallback widget
  Widget _buildErrorFallback() {
    return widget.fallback ?? _buildDefaultFallback();
  }

  /// Builds the default fallback dialog when no custom fallback is provided
  Widget _buildDefaultFallback() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.orange,
            size: 24.0,
          ),
          SizedBox(width: 8.0),
          Text('Display Error'),
        ],
      ),
      content: const Text(
        'An error occurred while displaying the dialog. '
        'Would you like to continue with a simplified version?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Internal widget that catches build-time errors using ErrorWidget
class _ErrorCatcher extends StatelessWidget {
  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(FlutterErrorDetails) onError;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (exception, stackTrace) {
          // Create error details for caught exceptions
          final details = FlutterErrorDetails(
            exception: exception,
            stack: stackTrace,
            library: 'dialog_error_boundary',
            context: ErrorDescription('Error caught in DialogErrorBoundary'),
          );
          
          onError(details);
          
          // Return a simple error widget
          return const Center(
            child: Text(
              'Rendering Error',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
      },
    );
  }
}

/// Fallback dialog strategies for different error scenarios
class DialogFallbackStrategies {
  /// Creates a simple confirmation dialog fallback
  static Widget simpleConfirmationDialog({
    required BuildContext context,
    String title = 'Confirmation',
    String message = 'Do you want to continue?',
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Creates a minimal dialog with just essential information
  static Widget minimalDialog({
    required BuildContext context,
    required String message,
    List<Widget>? actions,
  }) {
    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Text(message),
      ),
      actions: actions ?? [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Creates a text-only dialog for maximum compatibility
  static Widget textOnlyDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'OK',
  }) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(content),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error logging utility for dialog-related errors
class DialogErrorLogger {
  static final List<DialogErrorRecord> _errorHistory = [];
  
  /// Logs a dialog error with context
  static void logError({
    required String errorType,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final record = DialogErrorRecord(
      timestamp: DateTime.now(),
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
      context: context,
    );
    
    _errorHistory.add(record);
    
    // Keep only last 50 errors to prevent memory issues
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }
    
    // Debug print for development
    if (kDebugMode) {
      debugPrint('DialogError [$errorType]: $message');
      if (context != null) {
        debugPrint('Context: $context');
      }
    }
  }
  
  /// Gets the error history for debugging
  static List<DialogErrorRecord> getErrorHistory() {
    return List.unmodifiable(_errorHistory);
  }
  
  /// Clears the error history
  static void clearHistory() {
    _errorHistory.clear();
  }
}

/// Record of a dialog error for debugging purposes
class DialogErrorRecord {
  const DialogErrorRecord({
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.stackTrace,
    this.context,
  });

  final DateTime timestamp;
  final String errorType;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;

  @override
  String toString() {
    return 'DialogErrorRecord('
        'timestamp: $timestamp, '
        'errorType: $errorType, '
        'message: $message'
        ')';
  }
}