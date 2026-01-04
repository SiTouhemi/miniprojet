import 'package:flutter/material.dart';
import '/l10n/app_localizations.dart';

/// Helper extension to make localization easier throughout the app
extension LocalizationHelper on BuildContext {
  /// Get the current AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Quick translate method
  String translate(String key, {Map<String, String>? params}) {
    return l10n.translate(key, params: params);
  }
  
  /// Get status label with localization
  String getStatusLabel(String status) {
    return translate('status_$status');
  }
}

/// Helper class for status translations
class StatusHelper {
  static String getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        return l10n.translate('status_confirmed');
      case 'pending':
        return l10n.translate('status_pending');
      case 'cancelled':
        return l10n.translate('status_cancelled');
      case 'used':
        return l10n.translate('status_used');
      case 'expired':
        return l10n.translate('status_expired');
      default:
        return status;
    }
  }
}