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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('todays_menu'),
          style: AppTypography.h5,
        ),
        AppSpacing.verticalMD,
        
        // Stream today's menu from Firestore
        StreamBuilder<List<DailyMenuRecord>>(
          stream: queryDailyMenuRecord(
            queryBuilder: (query) {
              final today = DateTime.now();
              final dayOfWeek = today.weekday; // 1=Monday, 7=Sunday
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
    // Collect all available images from the menu components
    List<String> allImages = [];
    List<String> imageLabels = [];
    
    if (item.imageUrl.isNotEmpty) {
      allImages.add(item.imageUrl);
      imageLabels.add(item.mainDish);
    }
    
    // For demo purposes, we'll create placeholder images for different components
    // In a real implementation, you'd fetch these from related Plat records
    final components = <Map<String, String>>[];
    
    if (item.salad.isNotEmpty) {
      components.add({'name': item.salad, 'type': 'Salad', 'image': item.imageUrl});
    }
    if (item.accompaniment.isNotEmpty) {
      components.add({'name': item.accompaniment, 'type': 'Side', 'image': item.imageUrl});
    }
    if (item.accompaniments.isNotEmpty) {
      for (String acc in item.accompaniments) {
        components.add({'name': acc, 'type': 'Side', 'image': item.imageUrl});
      }
    }
    if (item.dessert.isNotEmpty) {
      components.add({'name': item.dessert, 'type': 'Dessert', 'image': item.imageUrl});
    }

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
          // Image Carousel with Navigation Arrows
          if (allImages.isNotEmpty || components.isNotEmpty)
            _buildImageCarousel(item, components),
          
          // Menu content
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main dish name (removed price)
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(DailyMenuRecord item, List<Map<String, String>> components) {
    // Create a list of all images with their labels
    List<Map<String, String>> allImageData = [];
    
    // Add main dish image
    if (item.imageUrl.isNotEmpty) {
      allImageData.add({
        'image': item.imageUrl,
        'label': item.mainDish,
        'type': 'Main Dish'
      });
    }
    
    // Add component images (for demo, using the same image with different labels)
    // In production, you'd fetch actual component images from the Plat collection
    for (var component in components) {
      if (component['image']?.isNotEmpty == true) {
        allImageData.add({
          'image': component['image']!,
          'label': component['name']!,
          'type': component['type']!
        });
      }
    }
    
    if (allImageData.isEmpty) return const SizedBox.shrink();
    
    return StatefulBuilder(
      builder: (context, setState) {
        int currentImageIndex = 0;
        final PageController pageController = PageController();
        
        return Container(
          height: 200,
          child: Stack(
            children: [
              // Image PageView
              PageView.builder(
                controller: pageController,
                itemCount: allImageData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imageData = allImageData[index];
                  
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppBorders.borderMD,
                          child: Image.network(
                            imageData['image']!,
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
                                      _getComponentIcon(imageData['type']!),
                                      size: AppIconSizes.xxxl,
                                      color: AppColors.gray400,
                                    ),
                                    AppSpacing.verticalSM,
                                    Text(
                                      imageData['label']!,
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
                        
                        // Image label overlay
                        Positioned(
                          bottom: AppSpacing.sm,
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: AppBorders.borderSM,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  imageData['label']!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                                Text(
                                  imageData['type']!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Navigation Arrows
              if (allImageData.length > 1) ...[
                // Left Arrow
                Positioned(
                  left: AppSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        final newIndex = currentImageIndex > 0 
                            ? currentImageIndex - 1 
                            : allImageData.length - 1;
                        pageController.animateToPage(
                          newIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Right Arrow
                Positioned(
                  right: AppSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        final newIndex = currentImageIndex < allImageData.length - 1 
                            ? currentImageIndex + 1 
                            : 0;
                        pageController.animateToPage(
                          newIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Page Indicators
              if (allImageData.length > 1)
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: AppBorders.borderSM,
                    ),
                    child: Text(
                      '${currentImageIndex + 1}/${allImageData.length}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
}
