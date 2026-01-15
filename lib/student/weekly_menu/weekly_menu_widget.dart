import '/backend/backend.dart';
import '/backend/services/menu_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/error_handler.dart';
import '/config/app_config.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import 'package:flutter/material.dart';
import 'weekly_menu_model.dart';
export 'weekly_menu_model.dart';

/// Weekly Menu Widget - Shows menu for Monday through Saturday
/// Displays lunch and dinner menus for each day with pull-to-refresh
class WeeklyMenuWidget extends StatefulWidget {
  const WeeklyMenuWidget({super.key});

  static const String routeName = 'WeeklyMenu';
  static const String routePath = '/weekly-menu';

  @override
  State<WeeklyMenuWidget> createState() => _WeeklyMenuWidgetState();
}

class _WeeklyMenuWidgetState extends State<WeeklyMenuWidget> {
  late WeeklyMenuModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ErrorHandler _errorHandler = ErrorHandler.instance;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WeeklyMenuModel());
    
    // Load weekly menu data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeeklyMenu();
    });
  }

  Future<void> _loadWeeklyMenu() async {
    try {
      await _model.loadWeeklyMenu();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'weekly_menu_load',
        onRetry: _loadWeeklyMenu,
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      setState(() {});
      await _model.refreshWeeklyMenu();
      setState(() {});
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'weekly_menu_refresh',
        onRetry: _handleRefresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          leading: FlutterFlowIconButton(
            borderRadius: AppBorders.radiusLG,
            buttonSize: 40.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: AppIconSizes.lg,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            'Weekly Menu',
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
                fillColor: AppColors.primary.withValues(alpha: 0.1),
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: AppIconSizes.lg,
                ),
                onPressed: _handleRefresh,
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
              // Error display
              if (_model.errorMessage != null)
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
                          _model.errorMessage!,
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

              // Main content
              Expanded(
                child: _errorHandler.buildLoadingWithError(
                  isLoading: _model.isLoading,
                  error: _model.errorMessage,
                  onRetry: _handleRefresh,
                  loadingMessage: 'Loading weekly menu...',
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: _buildWeeklyMenuContent(_model, l10n),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyMenuContent(WeeklyMenuModel model, AppLocalizations l10n) {
    if (model.weeklyMenu.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.verticalMD,
          
          // Week overview
          _buildWeekOverview(l10n),
          
          AppSpacing.verticalLG,
          
          // Daily menus (Monday to Saturday)
          ...List.generate(6, (index) {
            final dayOfWeek = index + 1; // 1=Monday, 6=Saturday
            final dayMenus = model.weeklyMenu[dayOfWeek] ?? [];
            return _buildDaySection(dayOfWeek, dayMenus, l10n);
          }),
          
          AppSpacing.verticalXL,
        ],
      ),
    );
  }

  Widget _buildWeekOverview(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppBorders.borderLG,
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: AppColors.textOnPrimary,
                size: AppIconSizes.lg,
              ),
              AppSpacing.horizontalSM,
              Text(
                'This Week\'s Menu',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSM,
          Text(
            'Monday through Saturday • Restaurant closed on Sunday',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(int dayOfWeek, List<DailyMenuRecord> dayMenus, AppLocalizations l10n) {
    final dayName = MenuService.getDayName(dayOfWeek, locale: 'en');
    final lunchMenus = dayMenus.where((menu) => menu.mealType == 'lunch').toList();
    final dinnerMenus = dayMenus.where((menu) => menu.mealType == 'dinner').toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.borderLG,
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppBorders.borderMD,
                  ),
                  child: Center(
                    child: Text(
                      dayOfWeek.toString(),
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ),
                AppSpacing.horizontalSM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: AppTypography.h5.copyWith(
                          color: AppColors.primary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        '${lunchMenus.length + dinnerMenus.length} menu(s) available',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu content
          if (lunchMenus.isEmpty && dinnerMenus.isEmpty)
            _buildNoMenuForDay(l10n)
          else
            Padding(
              padding: AppSpacing.paddingMD,
              child: Column(
                children: [
                  // Lunch section
                  if (lunchMenus.isNotEmpty) ...[
                    _buildMealTypeSection(
                      'Lunch',
                      Icons.wb_sunny,
                      Colors.orange,
                      lunchMenus,
                      l10n,
                    ),
                    if (dinnerMenus.isNotEmpty) AppSpacing.verticalLG,
                  ],
                  
                  // Dinner section
                  if (dinnerMenus.isNotEmpty)
                    _buildMealTypeSection(
                      'Dinner',
                      Icons.nightlight_round,
                      Colors.indigo,
                      dinnerMenus,
                      l10n,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoMenuForDay(AppLocalizations l10n) {
    return Padding(
      padding: AppSpacing.paddingMD,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: AppBorders.borderMD,
          border: Border.all(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: AppIconSizes.xl,
              color: AppColors.gray400,
            ),
            AppSpacing.verticalSM,
            Text(
              'No menu available for this day',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSection(
    String mealType,
    IconData icon,
    Color color,
    List<DailyMenuRecord> menus,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
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
          // Meal type header
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorders.radiusMD),
                topRight: Radius.circular(AppBorders.radiusMD),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: AppIconSizes.md,
                ),
                AppSpacing.horizontalSM,
                Text(
                  mealType,
                  style: AppTypography.h6.copyWith(
                    color: color,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu items
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              children: menus.map((menu) => _buildMenuItemCard(menu, l10n)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(DailyMenuRecord menu, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.borderMD,
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu image
          if (menu.imageUrl.isNotEmpty)
            _buildMenuImage(menu),
          
          // Menu details
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main dish and availability status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        menu.mainDish,
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                    // Price - Hidden for staff view
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: AppSpacing.sm,
                    //     vertical: AppSpacing.xs,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.success.withValues(alpha: 0.1),
                    //     borderRadius: AppBorders.borderSM,
                    //   ),
                    //   child: Text(
                    //     AppConfig.formatPrice(menu.price),
                    //     style: AppTypography.bodyMedium.copyWith(
                    //       color: AppColors.success,
                    //       fontWeight: AppTypography.bold,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                
                // Description
                if (menu.description.isNotEmpty) ...[
                  AppSpacing.verticalSM,
                  Text(
                    menu.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                AppSpacing.verticalSM,
                
                // Menu components
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (menu.salad.isNotEmpty)
                      _buildMenuComponent('Salad', menu.salad, Icons.eco, Colors.green),
                    if (menu.accompaniment.isNotEmpty)
                      _buildMenuComponent('Side', menu.accompaniment, Icons.rice_bowl, Colors.brown),
                    if (menu.accompaniments.isNotEmpty)
                      ...menu.accompaniments.map((acc) => 
                        _buildMenuComponent('Side', acc, Icons.restaurant, Colors.orange)),
                    if (menu.dessert.isNotEmpty)
                      _buildMenuComponent('Dessert', menu.dessert, Icons.cake, Colors.pink),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuImage(DailyMenuRecord menu) {
    return Container(
      height: 180,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorders.radiusMD),
          topRight: Radius.circular(AppBorders.radiusMD),
        ),
        child: Image.network(
          menu.imageUrl,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.gray100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: AppIconSizes.xl,
                    color: AppColors.gray400,
                  ),
                  AppSpacing.verticalSM,
                  Text(
                    menu.mainDish,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week,
              size: AppIconSizes.xxxl,
              color: AppColors.gray400,
            ),
            AppSpacing.verticalLG,
            Text(
              'No Weekly Menu Available',
              style: AppTypography.h5.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalSM,
            Text(
              'The weekly menu is not available at the moment. Please try again later.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalLG,
            ElevatedButton(
              onPressed: _handleRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: AppSpacing.paddingMD,
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorders.borderMD,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: AppIconSizes.sm,
                  ),
                  AppSpacing.horizontalSM,
                  Text(
                    'Refresh',
                    style: AppTypography.button,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}