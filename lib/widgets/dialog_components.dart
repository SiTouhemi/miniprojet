/// Dialog components for safe and reliable dialog rendering
///
/// This library provides error-resistant dialog components that prevent
/// the "Cannot hit test a render box with no size" crashes and other
/// layout-related rendering issues.
///
/// Key components:
/// - [SafeAlertDialog]: Error-safe AlertDialog with fallback strategies
/// - [DialogErrorBoundary]: Error boundary for catching rendering exceptions
/// - [DialogTitle]: Safe dialog title with Column/Row layout options
/// - [ConfirmationRow]: Predictable label-value row layout
/// - [DialogFallbackStrategies]: Pre-built fallback dialog strategies
/// - [DialogErrorLogger]: Error logging utility for debugging
/// - [DialogErrorRecovery]: High-level error recovery utilities

export 'safe_alert_dialog.dart';
export 'dialog_error_boundary.dart';
export 'dialog_title.dart';
export 'confirmation_row.dart';
export 'dialog_error_recovery.dart';
