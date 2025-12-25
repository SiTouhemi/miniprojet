import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_middleware.dart';
import '/utils/app_logger.dart';

/// NavigationService provides role-aware navigation and route management
/// Implements authorization guards for protected routes (Requirements 1.2, 1.3, 1.4)
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Get the current navigation context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a route with automatic permission checking
  static Future<void> navigateTo(String routeName, {Object? arguments}) async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Check authentication first
      await RoleMiddleware.requireAuthentication();
      
      // Check route permissions
      final canAccess = await RoleMiddleware.canAccessRoute(routeName);
      if (!canAccess) {
        // Redirect to appropriate default route based on role
        final role = await RoleMiddleware.getCurrentUserRole();
        final defaultRoute = _getDefaultRouteForRole(role);
        
        _showUnauthorizedMessage(context);
        Navigator.pushReplacementNamed(context, defaultRoute, arguments: arguments);
        return;
      }

      Navigator.pushNamed(context, routeName, arguments: arguments);
    } on UnauthenticatedException catch (e) {
      _showAuthenticationError(context, e.message);
      Navigator.pushReplacementNamed(context, '/login');
    } on UnauthorizedException catch (e) {
      _showUnauthorizedMessage(context, e.message);
      // Stay on current route or redirect to appropriate default
      final role = await RoleMiddleware.getCurrentUserRole();
      final defaultRoute = _getDefaultRouteForRole(role);
      Navigator.pushReplacementNamed(context, defaultRoute);
    } catch (e) {
      _showGenericError(context, e.toString());
    }
  }

  /// Replace current route with new route (with permission checking)
  static Future<void> navigateAndReplace(String routeName, {Object? arguments}) async {
    final context = currentContext;
    if (context == null) return;

    try {
      await RoleMiddleware.requireAuthentication();
      
      final canAccess = await RoleMiddleware.canAccessRoute(routeName);
      if (!canAccess) {
        final role = await RoleMiddleware.getCurrentUserRole();
        final defaultRoute = _getDefaultRouteForRole(role);
        
        _showUnauthorizedMessage(context);
        Navigator.pushReplacementNamed(context, defaultRoute, arguments: arguments);
        return;
      }

      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    } on UnauthenticatedException catch (e) {
      _showAuthenticationError(context, e.message);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showGenericError(context, e.toString());
    }
  }

  /// Navigate and clear all previous routes
  static Future<void> navigateAndClearStack(String routeName, {Object? arguments}) async {
    final context = currentContext;
    if (context == null) return;

    try {
      await RoleMiddleware.requireAuthentication();
      
      final canAccess = await RoleMiddleware.canAccessRoute(routeName);
      if (!canAccess) {
        final role = await RoleMiddleware.getCurrentUserRole();
        final defaultRoute = _getDefaultRouteForRole(role);
        
        _showUnauthorizedMessage(context);
        Navigator.pushNamedAndRemoveUntil(context, defaultRoute, (route) => false, arguments: arguments);
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false, arguments: arguments);
    } on UnauthenticatedException catch (e) {
      _showAuthenticationError(context, e.message);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showGenericError(context, e.toString());
    }
  }

  /// Navigate to the appropriate home screen based on user role
  static Future<void> navigateToRoleBasedHome() async {
    try {
      await RoleMiddleware.requireAuthentication();
      final role = await RoleMiddleware.getCurrentUserRole();
      final homeRoute = _getDefaultRouteForRole(role);
      
      // Validate that the target route is accessible
      final canAccess = await RoleMiddleware.canAccessRoute(homeRoute);
      if (!canAccess) {
        throw UnauthorizedException('Accès non autorisé à la page d\'accueil pour le rôle: ${role?.name ?? "inconnu"}');
      }
      
      await navigateAndClearStack(homeRoute);
    } catch (e) {
      // If role-based navigation fails, redirect to login
      await navigateAndClearStack('/login');
      
      final context = currentContext;
      if (context != null) {
        _showAuthenticationError(context, 'Erreur de navigation: ${e.toString()}');
      }
    }
  }

  /// Navigate to role-based home with enhanced error handling and validation
  static Future<void> navigateToRoleBasedHomeWithValidation() async {
    final context = currentContext;
    if (context == null) return;

    try {
      // Ensure user is authenticated
      await RoleMiddleware.requireAuthentication();
      
      // Get user role
      final role = await RoleMiddleware.getCurrentUserRole();
      if (role == null) {
        throw Exception('Rôle utilisateur non défini. Veuillez vous reconnecter.');
      }
      
      // Get appropriate home route
      final homeRoute = _getDefaultRouteForRole(role);
      
      // Validate route access
      final canAccess = await RoleMiddleware.canAccessRoute(homeRoute);
      if (!canAccess) {
        throw UnauthorizedException('Accès non autorisé à la page d\'accueil pour le rôle: ${role.name}');
      }
      
      // Navigate to home
      await navigateAndClearStack(homeRoute);
      
      // Show welcome message
      final welcomeMessage = _getWelcomeMessageForRole(role);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(welcomeMessage),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      
    } on UnauthenticatedException catch (e) {
      _showAuthenticationError(context, e.message);
      await navigateAndClearStack('/login');
    } on UnauthorizedException catch (e) {
      _showUnauthorizedMessage(context, e.message);
      await navigateAndClearStack('/login');
    } catch (e) {
      _showGenericError(context, 'Erreur de navigation: ${e.toString()}');
      await navigateAndClearStack('/login');
    }
  }

  /// Check if user can access a route without navigating
  static Future<bool> canAccessRoute(String routeName) async {
    try {
      await RoleMiddleware.requireAuthentication();
      return await RoleMiddleware.canAccessRoute(routeName);
    } catch (e) {
      return false;
    }
  }

  /// Get the default route for a specific role
  static String _getDefaultRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/adminDashboard';
      case UserRole.staff:
        return '/staffHome';
      case UserRole.student:
        return '/home';
      default:
        return '/login';
    }
  }

  /// Get welcome message for a specific role
  static String _getWelcomeMessageForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Bienvenue, Administrateur !';
      case UserRole.staff:
        return 'Bienvenue, Personnel !';
      case UserRole.student:
        return 'Bienvenue, Étudiant !';
      default:
        return 'Bienvenue !';
    }
  }

  /// Validate user role and redirect if necessary
  static Future<bool> validateUserRoleForRoute(String routeName) async {
    try {
      await RoleMiddleware.requireAuthentication();
      
      final role = await RoleMiddleware.getCurrentUserRole();
      if (role == null) {
        return false;
      }
      
      // Check if user can access the requested route
      final canAccess = await RoleMiddleware.canAccessRoute(routeName);
      if (!canAccess) {
        // Redirect to appropriate home if they can't access the requested route
        final homeRoute = _getDefaultRouteForRole(role);
        await navigateAndReplace(homeRoute);
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show unauthorized access message
  static void _showUnauthorizedMessage(BuildContext context, [String? customMessage]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? 'Accès non autorisé à cette section'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show authentication error message
  static void _showAuthenticationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show generic error message
  static void _showGenericError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle role validation errors and redirect appropriately
  static Future<void> handleRoleValidationError(BuildContext context, dynamic error) async {
    if (error is UnauthenticatedException) {
      _showAuthenticationError(context, error.message);
      await navigateAndClearStack('/login');
    } else if (error is UnauthorizedException) {
      _showUnauthorizedMessage(context, error.message);
      // Redirect to appropriate home based on current role
      try {
        final role = await RoleMiddleware.getCurrentUserRole();
        final homeRoute = _getDefaultRouteForRole(role);
        await navigateAndClearStack(homeRoute);
      } catch (e) {
        // If we can't determine role, go to login
        await navigateAndClearStack('/login');
      }
    } else {
      _showGenericError(context, error.toString());
      await navigateAndClearStack('/login');
    }
  }

  /// Validate current user's role and ensure they're on the correct home screen
  static Future<void> ensureCorrectHomeScreen() async {
    final context = currentContext;
    if (context == null) return;

    try {
      await RoleMiddleware.requireAuthentication();
      final role = await RoleMiddleware.getCurrentUserRole();
      
      if (role == null) {
        throw Exception('Rôle utilisateur non défini');
      }
      
      final expectedHomeRoute = _getDefaultRouteForRole(role);
      final currentRoute = GoRouterState.of(context).uri.toString();
      
      // If user is not on their appropriate home screen, redirect them
      if (currentRoute != expectedHomeRoute && 
          !await RoleMiddleware.canAccessRoute(currentRoute)) {
        await navigateAndReplace(expectedHomeRoute);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redirection vers votre page d\'accueil appropriée'),
            backgroundColor: Color(0xFF2196F3),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      await handleRoleValidationError(context, e);
    }
  }
}

/// Route generator that includes permission checking
class AuthorizedRouteGenerator {
  /// Generate routes with automatic permission checking
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => FutureBuilder<bool>(
        future: NavigationService.canAccessRoute(settings.name ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !(snapshot.data ?? false)) {
            return _buildUnauthorizedPage(context, settings.name);
          }

          // Return the actual page widget based on route name
          return _buildPageForRoute(settings.name ?? '', settings.arguments);
        },
      ),
    );
  }

  /// Build unauthorized access page
  static Widget _buildUnauthorizedPage(BuildContext context, String? routeName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès non autorisé'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Accès non autorisé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await NavigationService.navigateToRoleBasedHome();
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the actual page widget for a route
  /// This is a placeholder - in a real app, you'd have a proper route mapping
  static Widget _buildPageForRoute(String routeName, Object? arguments) {
    // This is a placeholder implementation
    // In the actual app, you would map route names to their corresponding widgets
    return Scaffold(
      appBar: AppBar(title: Text('Route: $routeName')),
      body: Center(
        child: Text('Page for route: $routeName'),
      ),
    );
  }
}

/// Middleware for checking permissions before route changes
class RoutePermissionMiddleware extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkRoutePermissions(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkRoutePermissions(newRoute);
    }
  }

  Future<void> _checkRoutePermissions(Route<dynamic> route) async {
    final routeName = route.settings.name;
    if (routeName == null) return;

    try {
      final canAccess = await NavigationService.canAccessRoute(routeName);
      if (!canAccess) {
        // Log unauthorized access attempt
        AppLogger.w('Unauthorized access attempt to route: $routeName', tag: 'NavigationService');
        
        // Optionally redirect to appropriate page
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await NavigationService.navigateToRoleBasedHome();
        });
      }
    } catch (e) {
      AppLogger.e('Error checking route permissions for $routeName', error: e, tag: 'NavigationService');
    }
  }
}