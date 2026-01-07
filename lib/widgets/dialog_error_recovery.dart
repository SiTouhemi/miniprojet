import 'package:flutter/material.dart';
import 'dialog_error_boundary.dart';

/// Utility class for managing dialog error recovery strategies
///
/// This class provides methods to handle different types of dialog errors
/// and implement appropriate recovery strategies based on the error type
/// and context.
class DialogErrorRecovery {
  /// Shows a dialog with error recovery capabilities
  ///
  /// This method wraps the dialog in error boundaries and provides
  /// fallback strategies if the main dialog fails to render.
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    Widget? fallbackDialog,
    void Function(FlutterErrorDetails)? onError,
  }) async {
    try {
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
        builder: (context) => DialogErrorBoundary(
          fallback: fallbackDialog ?? _buildDefaultFallback(context),
          onError: onError ?? _defaultErrorHandler,
          child: builder(context),
        ),
      );
    } catch (e) {
      // If showDialog itself fails, show a simple fallback
      DialogErrorLogger.logError(
        errorType: 'showSafeDialog',
        message: e.toString(),
        context: {'barrierDismissible': barrierDismissible},
      );

      return await _showFallbackDialog<T>(context);
    }
  }

  /// Shows a confirmation dialog with error recovery
  static Future<bool?> showSafeConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    return await showSafeDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: icon != null
            ? Row(
                children: [
                  Icon(icon, color: iconColor ?? Colors.blue),
                  const SizedBox(width: 8.0),
                  Expanded(child: Text(title)),
                ],
              )
            : Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop(true);
            },
            child: Text(confirmText),
          ),
        ],
      ),
      fallbackDialog: DialogFallbackStrategies.simpleConfirmationDialog(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Shows an information dialog with error recovery
  static Future<void> showSafeInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) async {
    await showSafeDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: icon != null
            ? Row(
                children: [
                  Icon(icon, color: iconColor ?? Colors.blue),
                  const SizedBox(width: 8.0),
                  Expanded(child: Text(title)),
                ],
              )
            : Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
      fallbackDialog: DialogFallbackStrategies.textOnlyDialog(
        context: context,
        title: title,
        content: message,
        buttonText: buttonText,
      ),
    );
  }

  /// Shows an error dialog with recovery options
  static Future<void> showSafeErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onRetry,
    String retryText = 'Réessayer',
  }) async {
    await showSafeDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8.0),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryText),
            ),
        ],
      ),
      fallbackDialog: DialogFallbackStrategies.textOnlyDialog(
        context: context,
        title: title,
        content: message,
        buttonText: buttonText,
      ),
    );
  }

  /// Builds the default fallback dialog
  static Widget _buildDefaultFallback(BuildContext context) {
    return AlertDialog(
      title: const Text('Error'),
      content: const Text(
        'An error occurred while displaying the dialog.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Default error handler
  static void _defaultErrorHandler(FlutterErrorDetails details) {
    DialogErrorLogger.logError(
      errorType: 'DialogRendering',
      message: details.exception.toString(),
      stackTrace: details.stack.toString(),
    );
  }

  /// Shows a simple fallback dialog when all else fails
  static Future<T?> _showFallbackDialog<T>(BuildContext context) async {
    return await showDialog<T>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Error'),
        content: Text(
          'A critical error occurred. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: null, // Will be handled by Navigator.pop
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Extension methods for BuildContext to make safe dialog usage easier
extension SafeDialogExtension on BuildContext {
  /// Shows a safe confirmation dialog
  Future<bool?> showSafeConfirmation({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    IconData? icon,
    Color? iconColor,
  }) {
    return DialogErrorRecovery.showSafeConfirmationDialog(
      context: this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      iconColor: iconColor,
    );
  }

  /// Shows a safe information dialog
  Future<void> showSafeInfo({
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return DialogErrorRecovery.showSafeInfoDialog(
      context: this,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: icon,
      iconColor: iconColor,
    );
  }

  /// Shows a safe error dialog
  Future<void> showSafeError({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onRetry,
    String retryText = 'Réessayer',
  }) {
    return DialogErrorRecovery.showSafeErrorDialog(
      context: this,
      title: title,
      message: message,
      buttonText: buttonText,
      onRetry: onRetry,
      retryText: retryText,
    );
  }
}
