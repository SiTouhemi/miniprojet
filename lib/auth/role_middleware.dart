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

/// Widget that conditionally shows content based on user role
/// Implements UI-level authorization guards
class RoleBasedWidget extends StatefulWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;
  final String? operation;

  const RoleBasedWidget({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.operation,
  }) : super(key: key);

  @override
  State<RoleBasedWidget> createState() => _RoleBasedWidgetState();
}

class _RoleBasedWidgetState extends State<RoleBasedWidget> {
  bool _hasAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      await RoleMiddleware.requireAuthentication();
      
      if (widget.operation != null) {
        await RoleMiddleware.requirePermission(widget.operation!);
        setState(() {
          _hasAccess = true;
          _isLoading = false;
        });
      } else {
        final hasRole = await authService.hasAnyRole(widget.allowedRoles);
        setState(() {
          _hasAccess = hasRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasAccess) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows content only to admin users
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const [UserRole.admin],
      child: child,
      fallback: fallback,
    );
  }
}

/// Widget that shows content only to staff and admin users
class StaffOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const StaffOnlyWidget({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const [UserRole.staff, UserRole.admin],
      child: child,
      fallback: fallback,
    );
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

/// Mixin for widgets that need role-based functionality
mixin RoleAwareMixin<T extends StatefulWidget> on State<T> {
  UserRole? _currentRole;
  bool _isLoadingRole = true;

  UserRole? get currentRole => _currentRole;
  bool get isLoadingRole => _isLoadingRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    try {
      final role = await RoleMiddleware.getCurrentUserRole();
      if (mounted) {
        setState(() {
          _currentRole = role;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentRole = null;
          _isLoadingRole = false;
        });
      }
    }
  }

  /// Refresh the current user role
  Future<void> refreshRole() async {
    setState(() {
      _isLoadingRole = true;
    });
    await _loadCurrentRole();
  }

  /// Check if current user has specific role
  bool hasRole(UserRole role) {
    return _currentRole == role;
  }

  /// Check if current user has any of the specified roles
  bool hasAnyRole(List<UserRole> roles) {
    return _currentRole != null && roles.contains(_currentRole);
  }

  /// Check if current user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  /// Check if current user is staff or admin
  bool get isStaffOrAdmin => hasAnyRole([UserRole.staff, UserRole.admin]);

  /// Check if current user is authenticated
  bool get isAuthenticated => _currentRole != null;
}