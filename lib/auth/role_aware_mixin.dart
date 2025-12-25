import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Mixin that provides role-aware functionality to widgets
mixin RoleAwareMixin<T extends StatefulWidget> on State<T> {
  UserRole? _currentUserRole;
  bool _isLoadingRole = true;

  UserRole? get currentUserRole => _currentUserRole;
  bool get isLoadingRole => _isLoadingRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await authService.getUserRole();
      if (mounted) {
        setState(() {
          _currentUserRole = role;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUserRole = null;
          _isLoadingRole = false;
        });
      }
    }
  }

  /// Check if current user has the specified role
  bool hasRole(UserRole role) {
    return _currentUserRole == role;
  }

  /// Check if current user has any of the specified roles
  bool hasAnyRole(List<UserRole> roles) {
    return _currentUserRole != null && roles.contains(_currentUserRole);
  }

  /// Check if current user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  /// Check if current user is staff
  bool get isStaff => hasRole(UserRole.staff);

  /// Check if current user is student
  bool get isStudent => hasRole(UserRole.student);

  /// Refresh user role (useful after role changes)
  Future<void> refreshUserRole() async {
    setState(() {
      _isLoadingRole = true;
    });
    await _loadUserRole();
  }
}

/// Widget that shows content only to users with specific roles
class RoleBasedWidget extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return fallback ?? SizedBox.shrink();
        }

        final userRole = snapshot.data;
        if (userRole != null && allowedRoles.contains(userRole)) {
          return child;
        }

        return fallback ?? SizedBox.shrink();
      },
    );
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
      allowedRoles: [UserRole.admin],
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
      allowedRoles: [UserRole.staff, UserRole.admin],
      child: child,
      fallback: fallback,
    );
  }
}

/// Widget that shows content only to student users
class StudentOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const StudentOnlyWidget({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: [UserRole.student],
      child: child,
      fallback: fallback,
    );
  }
}