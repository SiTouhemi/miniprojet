import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
        AppLogger.i('User data loaded: ${userDoc.nom} (${userDoc.pocket} DT)',
            tag: 'HomeWidget');
      } else if (authService.isLoggedIn) {
        // User is logged in but document doesn't exist - this shouldn't happen
        AppLogger.w('User is authenticated but no user document found',
            tag: 'HomeWidget');
        appState.setLastError(
            'Données utilisateur introuvables. Veuillez vous reconnecter.');
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
    // Simple demo QR - always show QR page for presentation
    context.pushNamed('LastQR');
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
                  _errorHandler.buildOfflineIndicator(
                      isOffline: !appState.isOnline),

                  // Main content with enhanced loading and error handling
                  Expanded(
                    child: _errorHandler.buildLoadingWithError(
                      isLoading: _isInitializing,
                      error: _isInitializing
                          ? null
                          : (user == null
                              ? l10n.translate('unable_to_load_user_data')
                              : null),
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
                        'name':
                            user.nom.isNotEmpty ? user.nom : user.displayName
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
                        l10n.translate('tickets_available',
                            params: {'count': user.tickets.toString()}),
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

        // Weekly Menu card
        _buildActionCard(
          icon: Icons.calendar_view_week,
          iconColor: AppColors.success,
          title: l10n.translate('weekly_menu'),
          subtitle: l10n.translate('view_weekly_menu'),
          onTap: () {
            try {
              context.pushNamed('WeeklyMenu');
            } catch (e) {
              _errorHandler.showError(
                context,
                e,
                contextInfo: 'weekly_menu_access',
              );
            }
          },
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

  /// Fetches real dish images from PlatRecord collection for menu components
  Future<Map<String, String>> _fetchDishImages(DailyMenuRecord menu) async {
    Map<String, String> dishImages = {};
    
    try {
      // Fetch image for main dish
      if (menu.mainDish.isNotEmpty) {
        final platQuery = await queryPlatRecordOnce(
          queryBuilder: (query) => query
              .where('nom', isEqualTo: menu.mainDish)
              .limit(1),
        );
        if (platQuery.isNotEmpty && platQuery.first.image.isNotEmpty) {
          dishImages['mainDish'] = platQuery.first.image;
        }
      }
      
      // Fetch image for salad
      if (menu.salad.isNotEmpty) {
        final platQuery = await queryPlatRecordOnce(
          queryBuilder: (query) => query
              .where('nom', isEqualTo: menu.salad)
              .limit(1),
        );
        if (platQuery.isNotEmpty && platQuery.first.image.isNotEmpty) {
          dishImages['salad'] = platQuery.first.image;
        }
      }
      
      // Fetch image for dessert
      if (menu.dessert.isNotEmpty) {
        final platQuery = await queryPlatRecordOnce(
          queryBuilder: (query) => query
              .where('nom', isEqualTo: menu.dessert)
              .limit(1),
        );
        if (platQuery.isNotEmpty && platQuery.first.image.isNotEmpty) {
          dishImages['dessert'] = platQuery.first.image;
        }
      }
      
      // Fetch image for accompaniment
      if (menu.accompaniment.isNotEmpty) {
        final platQuery = await queryPlatRecordOnce(
          queryBuilder: (query) => query
              .where('nom', isEqualTo: menu.accompaniment)
              .limit(1),
        );
        if (platQuery.isNotEmpty && platQuery.first.image.isNotEmpty) {
          dishImages['accompaniment'] = platQuery.first.image;
        }
      }
      
      // Fetch images for accompaniments list
      for (int i = 0; i < menu.accompaniments.length; i++) {
        final accompanimentName = menu.accompaniments[i];
        if (accompanimentName.isNotEmpty) {
          final platQuery = await queryPlatRecordOnce(
            queryBuilder: (query) => query
                .where('nom', isEqualTo: accompanimentName)
                .limit(1),
          );
          if (platQuery.isNotEmpty && platQuery.first.image.isNotEmpty) {
            dishImages['accompaniments_$i'] = platQuery.first.image;
          }
        }
      }
      
    } catch (e) {
      AppLogger.w('Error fetching dish images: $e', tag: 'HomeWidget');
    }
    
    return dishImages;
  }
  Widget _buildTodaysMenu(FFAppState appState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('todays_menu'),
          style: AppTypography.h5,
        ),
        AppSpacing.verticalMD,
        
        // Stream today's menu from Firestore with simplified filtering
        StreamBuilder<List<DailyMenuRecord>>(
          stream: queryDailyMenuRecord(
            queryBuilder: (query) {
              final today = DateTime.now();
              final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday
              
              // Simplified query - remove orderBy to avoid index requirement
              return query
                  .where('day_of_week', isEqualTo: dayOfWeek)
                  .where('available', isEqualTo: true);
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
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
              );
            }

            final menuItems = snapshot.data!;
            // Sort by created_at in code instead of query
            menuItems.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            
            final lunchItems = menuItems.where((item) => item.mealType == 'lunch').toList();
            final dinnerItems = menuItems.where((item) => item.mealType == 'dinner').toList();

            return Column(
              children: [
                // Lunch Section
                if (lunchItems.isNotEmpty) ...[
                  _buildMealSection(
                    title: 'Lunch',
                    icon: Icons.wb_sunny,
                    iconColor: Colors.orange,
                    menuItems: lunchItems,
                    l10n: l10n,
                  ),
                  AppSpacing.verticalLG,
                ],
                
                // Dinner Section
                if (dinnerItems.isNotEmpty) ...[
                  _buildMealSection(
                    title: 'Dinner',
                    icon: Icons.nightlight_round,
                    iconColor: Colors.indigo,
                    menuItems: dinnerItems,
                    l10n: l10n,
                  ),
                ],
                
                // Weekly Menu Button
                AppSpacing.verticalLG,
                _buildWeeklyMenuButton(l10n),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<DailyMenuRecord> menuItems,
    required AppLocalizations l10n,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.borderLG,
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withValues(alpha: 0.1), iconColor.withValues(alpha: 0.05)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorders.radiusLG),
                topRight: Radius.circular(AppBorders.radiusLG),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: AppIconSizes.lg,
                ),
                AppSpacing.horizontalSM,
                Text(
                  title,
                  style: AppTypography.h5.copyWith(
                    color: iconColor,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Details
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              children: menuItems.map((item) => _buildMenuItemCard(item, l10n)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(DailyMenuRecord item, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppBorders.borderMD,
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Image - Show menu image or fetch main dish image
          if (item.imageUrl.isNotEmpty)
            _buildMainMenuImage(item),
          
          // Menu content
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main dish name
                Text(
                  item.mainDish,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                
                AppSpacing.verticalSM,
                
                // Complete menu composition
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                AppSpacing.verticalSM,
                
                // Menu components
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (item.salad.isNotEmpty)
                      _buildMenuComponent('Salad', item.salad, Icons.eco, Colors.green),
                    if (item.accompaniment.isNotEmpty)
                      _buildMenuComponent('Side', item.accompaniment, Icons.rice_bowl, Colors.brown),
                    if (item.accompaniments.isNotEmpty)
                      ...item.accompaniments.map((acc) => 
                        _buildMenuComponent('Side', acc, Icons.restaurant, Colors.orange)),
                    if (item.dessert.isNotEmpty)
                      _buildMenuComponent('Dessert', item.dessert, Icons.cake, Colors.pink),
                  ],
                ),
                
                AppSpacing.verticalSM,
                
                // Tap to see individual dish images
                _buildViewDishImagesButton(item, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuImage(DailyMenuRecord item) {
    // Use a default meal image if imageUrl is empty
    final imageUrl = item.imageUrl.isNotEmpty 
        ? item.imageUrl 
        : 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80'; // Default food image
    
    return Container(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorders.radiusMD),
          topRight: Radius.circular(AppBorders.radiusMD),
        ),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.gray100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: AppIconSizes.xxxl,
                    color: AppColors.gray400,
                  ),
                  AppSpacing.verticalSM,
                  Text(
                    item.mainDish,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.gray100,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewDishImagesButton(DailyMenuRecord item, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _showDishImagesDialog(item, l10n),
      borderRadius: AppBorders.borderSM,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppBorders.borderSM,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: AppIconSizes.sm,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'View Individual Dish Images',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_forward_ios,
              size: AppIconSizes.xs,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDishImagesDialog(DailyMenuRecord item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorders.borderLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppBorders.radiusLG),
                      topRight: Radius.circular(AppBorders.radiusLG),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: AppIconSizes.md,
                      ),
                      AppSpacing.horizontalSM,
                      Expanded(
                        child: Text(
                          item.mainDish,
                          style: AppTypography.h6.copyWith(
                            color: AppColors.primary,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Dish Images List
                Flexible(
                  child: FutureBuilder<Map<String, String>>(
                    future: _fetchDishImages(item),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.primary),
                                AppSpacing.verticalSM,
                                Text(
                                  'Loading dish images...',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final dishImages = snapshot.data ?? <String, String>{};
                      final dishList = <Map<String, String>>[];
                      
                      // Add dishes with their images
                      if (item.mainDish.isNotEmpty) {
                        dishList.add({
                          'name': item.mainDish,
                          'type': 'Main Dish',
                          'image': dishImages['mainDish'] ?? item.imageUrl,
                        });
                      }
                      
                      if (item.salad.isNotEmpty) {
                        dishList.add({
                          'name': item.salad,
                          'type': 'Salad',
                          'image': dishImages['salad'] ?? '',
                        });
                      }
                      
                      if (item.accompaniment.isNotEmpty) {
                        dishList.add({
                          'name': item.accompaniment,
                          'type': 'Side',
                          'image': dishImages['accompaniment'] ?? '',
                        });
                      }
                      
                      for (int i = 0; i < item.accompaniments.length; i++) {
                        dishList.add({
                          'name': item.accompaniments[i],
                          'type': 'Side',
                          'image': dishImages['accompaniments_$i'] ?? '',
                        });
                      }
                      
                      if (item.dessert.isNotEmpty) {
                        dishList.add({
                          'name': item.dessert,
                          'type': 'Dessert',
                          'image': dishImages['dessert'] ?? '',
                        });
                      }
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: AppSpacing.paddingMD,
                        itemCount: dishList.length,
                        itemBuilder: (context, index) {
                          final dish = dishList[index];
                          return _buildDishImageItem(dish);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDishImageItem(Map<String, String> dish) {
    final hasImage = dish['image']?.isNotEmpty == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppBorders.borderMD,
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorders.radiusMD),
                bottomLeft: Radius.circular(AppBorders.radiusMD),
              ),
              child: hasImage
                  ? Image.network(
                      dish['image']!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDishPlaceholder(dish);
                      },
                    )
                  : _buildDishPlaceholder(dish),
            ),
          ),
          
          // Dish Info
          Expanded(
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish['name']!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    dish['type']!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!hasImage)
                    Text(
                      'Image not available',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishPlaceholder(Map<String, String> dish) {
    return Container(
      color: AppColors.gray100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getComponentIcon(dish['type']!),
            size: AppIconSizes.md,
            color: AppColors.gray400,
          ),
        ],
      ),
    );
  }
  IconData _getComponentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'salad':
        return Icons.eco;
      case 'side':
        return Icons.rice_bowl;
      case 'dessert':
        return Icons.cake;
      case 'main dish':
        return Icons.restaurant_menu;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildMenuComponent(String type, String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppBorders.borderSM,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIconSizes.sm,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            name,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMenuButton(AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        try {
          context.pushNamed('WeeklyMenu');
        } catch (e) {
          _errorHandler.showError(
            context,
            e,
            contextInfo: 'weekly_menu_access',
          );
        }
      },
      borderRadius: AppBorders.borderMD,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.medium,
          borderRadius: AppBorders.borderMD,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week,
              color: AppColors.primary,
              size: AppIconSizes.lg,
            ),
            AppSpacing.horizontalSM,
            Text(
              'View Weekly Menu',
              style: AppTypography.h6.copyWith(
                color: AppColors.primary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            AppSpacing.horizontalSM,
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: AppIconSizes.sm,
            ),
          ],
        ),
      ),
    );
  }
}