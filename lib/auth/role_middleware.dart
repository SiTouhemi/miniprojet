import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';

/// RoleMiddleware provides authorization guards and role checking functions
/// for UI components and API calls, implementing requirements 1.2, 1.3, 1.4
class RoleMiddleware {
  static final AuthService _authService = authService;

  /// Check if current user has permission to access a specific route
  /// Implements authorization guards for protected routes
  static Future<bool> canAccessRoute(String routeName) async {
    final role = await _authService.getUserRole();
    if (role == null) return false;

    switch (routeName) {
      // Admin-only routes
      case '/adminDashboard':
      case '/admin_dashboard':
      case '/admin/users':
      case '/admin/time_slots':
      case '/admin/menu':
      case '/admin/analytics':
      case '/admin/settings':
      case '/createUser':
      case '/ajoutPlat':
        return role == UserRole.admin;

      // Staff and Admin routes
      case '/staffHome':
      case '/monjeyaScan':
      case '/monjeya_scan':
      case '/staff/scan':
      case '/staff/validate':
        return role == UserRole.staff || role == UserRole.admin;

      // Student, Staff, and Admin routes (general access)
      case '/home':
      case '/student/home':
      case '/student/reservations':
      case '/student/profile':
      case '/student/history':
      case '/browse-slots':
      case '/reservation':
      case '/reservationcreneau':
      case '/reservationconfirme':
      case '/history':
      case '/lastQR':
      case '/profile':
        return role == UserRole.student || 
               role == UserRole.staff || 
               role == UserRole.admin;

      // Public routes (login, etc.)
      case '/login':
      case '/':
        return true;

      default:
        // For unknown routes, deny access by default for security
        return false;
    }
  }

  /// Validate user role before performing an operation
  /// Throws exception if user doesn't have required permissions
  static Future<void> requireRole(UserRole requiredRole, [String? operation]) async {
    final hasRole = await _authService.hasRole(requiredRole);
    if (!hasRole) {
      final operationText = operation != null ? ' pour $operation' : '';
      throw UnauthorizedException(
        'Accès non autorisé. Rôle ${requiredRole.name} requis$operationText.'
      );
    }
  }

  /// Validate user has any of the specified roles
  /// Throws exception if user doesn't have any of the required roles
  static Future<void> requireAnyRole(List<UserRole> requiredRoles, [String? operation]) async {
    final hasAnyRole = await _authService.hasAnyRole(requiredRoles);
    if (!hasAnyRole) {
      final roleNames = requiredRoles.map((r) => r.name).join(' ou ');
      final operationText = operation != null ? ' pour $operation' : '';
      throw UnauthorizedException(
        'Accès non autorisé. Rôle $roleNames requis$operationText.'
      );
    }
  }

  /// Validate user has permission for a specific operation
  /// Uses the AuthService permission system
  static Future<void> requirePermission(String operation) async {
    final hasPermission = await _authService.hasPermission(operation);
    if (!hasPermission) {
      throw UnauthorizedException(
        'Accès non autorisé pour l\'opération: $operation'
      );
    }
  }

  /// Check if current user is authenticated
  /// Throws exception if user is not logged in
  static Future<void> requireAuthentication() async {
    if (!_authService.isLoggedIn) {
      throw UnauthenticatedException('Authentification requise');
    }

    // Check session expiration
    try {
      await _authService.refreshSessionIfNeeded();
    } catch (e) {
      throw UnauthenticatedException('Session expirée. Veuillez vous reconnecter.');
    }
  }

  /// Get current user role safely
  /// Returns null if user is not authenticated or role cannot be determined
  static Future<UserRole?> getCurrentUserRole() async {
    try {
      return await _authService.getUserRole();
    } catch (e) {
      return null;
    }
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    return await _authService.hasRole(UserRole.admin);
  }

  /// Check if current user is staff or admin
  static Future<bool> isStaffOrAdmin() async {
    return await _authService.hasAnyRole([UserRole.staff, UserRole.admin]);
  }

  /// Check if current user is student, staff, or admin (any authenticated user)
  static Future<bool> isAuthenticatedUser() async {
    return await _authService.hasAnyRole([
      UserRole.student, 
      UserRole.staff, 
      UserRole.admin
    ]);
  }
}

/// Route guard that checks permissions before navigation
/// Implements protected route authorization
class RouteGuard {
  /// Check if user can navigate to the specified route
  /// Returns true if allowed, false otherwise
  static Future<bool> canNavigate(String routeName) async {
    try {
      await RoleMiddleware.requireAuthentication();
      return await RoleMiddleware.canAccessRoute(routeName);
    } catch (e) {
      return false;
    }
  }

  /// Navigate to route with permission check
  /// Throws exception if user doesn't have permission
  static Future<void> navigateWithPermissionCheck(
    BuildContext context,
    String routeName,
  ) async {
    final canAccess = await canNavigate(routeName);
    if (!canAccess) {
      throw UnauthorizedException(
        'Accès non autorisé à la route: $routeName'
      );
    }

    Navigator.pushNamed(context, routeName);
  }

  /// Navigate to route with fallback for unauthorized access
  static Future<void> navigateWithFallback(
    BuildContext context,
    String routeName,
    String fallbackRoute,
  ) async {
    final canAccess = await canNavigate(routeName);
    final targetRoute = canAccess ? routeName : fallbackRoute;
    Navigator.pushNamed(context, targetRoute);
  }
}

/// Exception thrown when user is not authenticated
class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException(this.message);

  @override
  String toString() => 'UnauthenticatedException: $message';
}

/// Exception thrown when user doesn't have required permissions
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}