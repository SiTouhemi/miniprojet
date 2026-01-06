import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Reusable logout confirmation dialog
/// Eliminates code duplication across multiple pages
class LogoutDialog {
  /// Show logout confirmation dialog
  /// Returns true if user confirms logout, false otherwise
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle logout process with error handling
  /// Shows confirmation dialog and performs logout if confirmed
  static Future<void> handleLogout(BuildContext context) async {
    final shouldLogout = await show(context);
    
    if (shouldLogout == true) {
      try {
        await signOut();
        if (context.mounted) {
          context.goNamed('Login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}