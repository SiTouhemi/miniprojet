import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/error_handler.dart';
import '/utils/app_logger.dart';
import '/widgets/logout_dialog.dart';
import '/config/app_config.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_model.dart';
export 'home_model.dart';

/// Enhanced home widget with improved error handling and user feedback
/// Main home page for students with comprehensive error handling and real-time data
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ErrorHandler _errorHandler = ErrorHandler.instance;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());
    
    // Load user data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  Future<void> _initializeUserData() async {
    final appState = Provider.of<FFAppState>(context, listen: false);
    
    try {
      // Check if user is authenticated
      if (!authService.isLoggedIn) {
        // Redirect to login if not authenticated
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      
      // If user is already loaded in app state, no need to reload
      if (appState.currentUser != null) {
        setState(() {
          _isInitializing = false;
        });
        return;
      }
      
      // Load user data and initialize real-time sync
      final userDoc = await authService.getCurrentUserDocument();
      if (userDoc != null) {
        appState.setCurrentUser(userDoc);
        AppLogger.i('User data loaded: ${userDoc.nom} (${userDoc.pocket} DT)', tag: 'HomeWidget');
      } else if (authService.isLoggedIn) {
        // User is logged in but document doesn't exist - this shouldn't happen
        AppLogger.w('User is authenticated but no user document found', tag: 'HomeWidget');
        appState.setLastError('Données utilisateur introuvables. Veuillez vous reconnecter.');
      }
    } catch (e) {
      AppLogger.e('Error loading current user', error: e, tag: 'HomeWidget');
      final errorMessage = _errorHandler.handleError(e, context: 'user_data');
      appState.setLastError(errorMessage);
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final appState = Provider.of<FFAppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      await appState.refreshAll();
      _errorHandler.showError(
        context,
        l10n.translate('data_refreshed'),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'refresh',
        onRetry: _handleRefresh,
      );
    }
  }

  void _handleQRCodeAccess(FFAppState appState) {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final upcomingReservations = appState.getUpcomingReservations();
      if (upcomingReservations.isNotEmpty) {
        context.pushNamed('LastQR');
      } else {
        _errorHandler.showError(
          context,
          l10n.translate('no_confirmed_reservations'),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'qr_access',
      );
    }
  }

  void _handleReservationAccess() {
    try {
      context.pushNamed('Reservationcreneau');
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'reservation_access',
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        final user = appState.currentUser;
        
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              automaticallyImplyLeading: false,
              title: Text(
                l10n.appName,
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FlutterFlowIconButton(
                    borderRadius: AppBorders.radiusLG,
                    buttonSize: 40.0,
                    fillColor: AppColors.errorLight.withValues(alpha: 0.1),
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: AppIconSizes.lg,
                    ),
                    onPressed: () => LogoutDialog.handleLogout(context),
                  ),
                ),
              ],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Column(
                children: [
                  // Enhanced error message display
                  if (appState.lastError != null)
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMD,
                      color: AppColors.error,
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.textOnPrimary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.horizontalSM,
                          Expanded(
                            child: Text(
                              appState.lastError!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _handleRefresh,
                            child: Text(
                              l10n.retry,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Enhanced offline indicator
                  _errorHandler.buildOfflineIndicator(isOffline: !appState.isOnline),

                  // Main content with enhanced loading and error handling
                  Expanded(
                    child: _errorHandler.buildLoadingWithError(
                      isLoading: _isInitializing,
                      error: _isInitializing ? null : (user == null ? l10n.translate('unable_to_load_user_data') : null),
                      onRetry: _initializeUserData,
                      loadingMessage: l10n.translate('loading_user_data'),
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.verticalMD,
                                
                                // User greeting with enhanced data validation
                                _buildUserGreeting(user, l10n),
                                
                                AppSpacing.verticalLG,
                                
                                // Balance card with real-time data and validation
                                _buildBalanceCard(user, l10n),
                                
                                AppSpacing.verticalLG,
                                
                                Text(
                                  l10n.translate('quick_actions'),
                                  style: AppTypography.h5,
                                ),
                                
                                AppSpacing.verticalMD,
                                
                                // Enhanced action cards with error handling
                                _buildActionCards(appState, l10n),
                                
                                AppSpacing.verticalLG,
                                
                                // Today's menu section with error handling
                                _buildTodaysMenu(appState, l10n),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserGreeting(UserRecord? user, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user != null 
                    ? l10n.translate('greeting', params: {
                        'name': user.nom.isNotEmpty ? user.nom : user.displayName
                      })
                    : l10n.translate('greeting_default'),
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.appSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (user?.classe != null && user!.classe.isNotEmpty)
                Text(
                  l10n.translate('class_label', params: {'class': user.classe}),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: 80.0,
          height: 80.0,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40.0),
            child: Image.asset(
              AppConfig.getAsset('logo'),
              width: 80.0,
              height: 80.0,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  size: 40,
                  color: AppColors.primary,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(UserRecord? user, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 140.0,
      decoration: const BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: AppBorders.borderLG,
      ),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('current_balance'),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      user != null 
                        ? AppConfig.formatPrice(user.pocket)
                        : AppConfig.formatPrice(0.0),
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.translate('tickets_available', params: {
                          'count': user.tickets.toString()
                        }),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(FFAppState appState, AppLocalizations l10n) {
    return GridView(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
      ),
      primary: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: [
        // Reservation card with error handling
        _buildActionCard(
          icon: Icons.restaurant_menu,
          iconColor: AppColors.primary,
          title: l10n.translate('reserve_meal'),
          subtitle: l10n.translate('reserve_meal_subtitle'),
          onTap: _handleReservationAccess,
        ),
        
        // QR Code card with enhanced error handling
        _buildActionCard(
          icon: Icons.qr_code,
          iconColor: AppColors.secondary,
          title: l10n.translate('qr_code'),
          subtitle: l10n.translate('restaurant_access'),
          onTap: () => _handleQRCodeAccess(appState),
        ),
        
        // History card
        _buildActionCard(
          icon: Icons.history,
          iconColor: AppColors.secondary,
          title: l10n.translate('history'),
          subtitle: l10n.translate('your_reservations'),
          onTap: () {
            try {
              context.pushNamed('history');
            } catch (e) {
              _errorHandler.showError(
                context,
                e,
                contextInfo: 'history_access',
              );
            }
          },
        ),
        
        // Profile card
        _buildActionCard(
          icon: Icons.person,
          iconColor: AppColors.primary,
          title: l10n.translate('profile'),
          subtitle: l10n.translate('my_information'),
          onTap: () {
            try {
              context.pushNamed('Profile');
            } catch (e) {
              _errorHandler.showError(
                context,
                e,
                contextInfo: 'profile_access',
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.borderMD,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.medium,
          borderRadius: AppBorders.borderMD,
        ),
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: AppIconSizes.xl,
              ),
              AppSpacing.verticalSM,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysMenu(FFAppState appState, AppLocalizations l10n) {
    final menu = appState.todaysMenu;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('todays_menu'),
          style: AppTypography.h5,
        ),
        AppSpacing.verticalMD,
        if (menu.isEmpty)
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorders.borderMD,
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant,
                  size: AppIconSizes.xxxl,
                  color: AppColors.gray400,
                ),
                AppSpacing.verticalSM,
                Text(
                  l10n.translate('no_menu_available'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...menu.map((dailyMenu) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorders.borderMD,
              boxShadow: AppShadows.small,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyMenu.mainDish,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (dailyMenu.description.isNotEmpty)
                        Text(
                          dailyMenu.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  AppConfig.formatPrice(dailyMenu.price),
                  style: AppTypography.h6.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }
}