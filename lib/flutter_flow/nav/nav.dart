import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';
import '/auth/role_middleware.dart';
import '/auth/firebase_auth/auth_util.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      ),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => LoginWidget(),
        ),
        // Student routes
        FFRoute(
          name: HomeWidget.routeName,
          path: HomeWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => HomeWidget(),
        ),
        FFRoute(
          name: EnhancedHomeWidget.routeName,
          path: EnhancedHomeWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => EnhancedHomeWidget(),
        ),
        FFRoute(
          name: ReservationWidget.routeName,
          path: ReservationWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => ReservationWidget(),
        ),
        FFRoute(
          name: ReservationconfirmeWidget.routeName,
          path: ReservationconfirmeWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => ReservationconfirmeWidget(),
        ),
        FFRoute(
          name: ReservationcreneauWidget.routeName,
          path: ReservationcreneauWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => ReservationcreneauWidget(),
        ),
        FFRoute(
          name: HistoryWidget.routeName,
          path: HistoryWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => HistoryWidget(),
        ),
        FFRoute(
          name: LastQRWidget.routeName,
          path: LastQRWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => LastQRWidget(),
        ),
        FFRoute(
          name: BrowseSlotsWidget.routeName,
          path: BrowseSlotsWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => BrowseSlotsWidget(),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.student, UserRole.staff, UserRole.admin],
          builder: (context, params) => ProfileWidget(),
        ),
        // Staff routes
        FFRoute(
          name: StaffHomeWidget.routeName,
          path: StaffHomeWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.staff, UserRole.admin],
          builder: (context, params) => StaffHomeWidget(),
        ),
        FFRoute(
          name: MonjeyaScanWidget.routeName,
          path: MonjeyaScanWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.staff, UserRole.admin],
          builder: (context, params) => MonjeyaScanWidget(),
        ),
        FFRoute(
          name: MealManagementWidget.routeName,
          path: MealManagementWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.staff, UserRole.admin],
          builder: (context, params) => MealManagementWidget(),
        ),
        FFRoute(
          name: DailyMenuManagementWidget.routeName,
          path: DailyMenuManagementWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.staff, UserRole.admin],
          builder: (context, params) => DailyMenuManagementWidget(),
        ),
        // Admin routes
        FFRoute(
          name: AdminDashboardWidget.routeName,
          path: AdminDashboardWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.admin],
          builder: (context, params) => AdminDashboardWidget(),
        ),
        FFRoute(
          name: CreateUserWidget.routeName,
          path: CreateUserWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.admin],
          builder: (context, params) => CreateUserWidget(),
        ),
        FFRoute(
          name: UserManagementWidget.routeName,
          path: UserManagementWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.admin],
          builder: (context, params) => UserManagementWidget(),
        ),
        FFRoute(
          name: AjoutPlatWidget.routeName,
          path: AjoutPlatWidget.routePath,
          requireAuth: true,
          allowedRoles: [UserRole.admin],
          builder: (context, params) => AjoutPlatWidget(),
        ),
        // Public routes
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.allowedRoles,
    this.requiredPermission,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final List<UserRole>? allowedRoles;
  final String? requiredPermission;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          
          // Create the page widget
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);

          // Wrap with role-based access control if needed
          Widget child;
          if (requireAuth || allowedRoles != null || requiredPermission != null) {
            child = RoleGuardWrapper(
              allowedRoles: allowedRoles,
              requiredPermission: requiredPermission,
              requireAuth: requireAuth,
              routePath: path,
              child: page,
            );
          } else {
            child = page;
          }

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

/// Widget that wraps route content with role-based access control
/// Implements authorization guards for protected routes (Requirements 1.2, 1.3, 1.4)
class RoleGuardWrapper extends StatefulWidget {
  final List<UserRole>? allowedRoles;
  final String? requiredPermission;
  final bool requireAuth;
  final String routePath;
  final Widget child;

  const RoleGuardWrapper({
    Key? key,
    this.allowedRoles,
    this.requiredPermission,
    this.requireAuth = false,
    required this.routePath,
    required this.child,
  }) : super(key: key);

  @override
  State<RoleGuardWrapper> createState() => _RoleGuardWrapperState();
}

class _RoleGuardWrapperState extends State<RoleGuardWrapper> {
  bool _isLoading = true;
  bool _hasAccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      // Check authentication if required
      if (widget.requireAuth || widget.allowedRoles != null || widget.requiredPermission != null) {
        await RoleMiddleware.requireAuthentication();
      }

      // Check specific permission if provided
      if (widget.requiredPermission != null) {
        await RoleMiddleware.requirePermission(widget.requiredPermission!);
        setState(() {
          _hasAccess = true;
          _isLoading = false;
        });
        return;
      }

      // Check role-based access if roles are specified
      if (widget.allowedRoles != null) {
        await RoleMiddleware.requireAnyRole(widget.allowedRoles!);
        setState(() {
          _hasAccess = true;
          _isLoading = false;
        });
        return;
      }

      // Check route-based access using the route path
      final canAccess = await RoleMiddleware.canAccessRoute(widget.routePath);
      if (!canAccess) {
        // Get user role to provide better error message
        final role = await RoleMiddleware.getCurrentUserRole();
        final roleMessage = role != null ? 'Rôle actuel: ${role.name}' : 'Rôle non défini';
        throw UnauthorizedException('Accès non autorisé à cette page. $roleMessage');
      }
      
      setState(() {
        _hasAccess = true;
        _isLoading = false;
      });

    } on UnauthenticatedException catch (e) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
        _errorMessage = e.message;
      });
      
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      
    } on UnauthorizedException catch (e) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
        _errorMessage = e.message;
      });
      
      // Redirect to appropriate home based on role
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final role = await RoleMiddleware.getCurrentUserRole();
        final homeRoute = _getHomeRouteForRole(role);
        
        // Show error message before redirecting
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Accès non autorisé'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        context.go(homeRoute);
      });
      
    } catch (e) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
        _errorMessage = 'Erreur d\'accès: ${e.toString()}';
      });
      
      // For unknown errors, redirect to login for safety
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
    }
  }

  String _getHomeRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/adminDashboard';
      case UserRole.staff:
        return '/staffHome';
      case UserRole.student:
        return '/home';
      case null:
        // Handle null role - redirect to login
        return '/login';
      default:
        // Handle any unexpected role values - redirect to login for safety
        return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasAccess) {
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
                _errorMessage ?? 'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final role = await RoleMiddleware.getCurrentUserRole();
                  final homeRoute = _getHomeRouteForRole(role);
                  context.go(homeRoute);
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
