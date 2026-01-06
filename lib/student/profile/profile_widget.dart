import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import '/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/app_state.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static const String routeName = 'Profile';
  static const String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: true,
        title: Text(
          l10n.translate('profile_settings'),
          style: AppTypography.h4.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        centerTitle: false,
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: Consumer<FFAppState>(
          builder: (context, appState, _) {
            final user = appState.currentUser;

            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: AppIconSizes.xxxl,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.verticalMD,
                    Text(
                      l10n.translate('login_to_view_profile'),
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalMD,
                    FFButtonWidget(
                      onPressed: () {
                        context.pushNamed('Login');
                      },
                      text: l10n.translate('go_to_login'),
                      options: FFButtonOptions(
                        height: AppButtonSizes.heightLarge,
                        padding: AppButtonSizes.paddingLarge,
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: AppColors.primary,
                        textStyle: AppTypography.button.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        elevation: 3.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: AppBorders.borderMD,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: AppSpacing.paddingMD,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: AppShadows.medium,
                      borderRadius: AppBorders.borderMD,
                    ),
                    child: Padding(
                      padding: AppSpacing.paddingMD,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            width: 60.0,
                            height: 60.0,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.textOnPrimary,
                              size: AppIconSizes.xl,
                            ),
                          ),
                          AppSpacing.horizontalMD,
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName
                                      : user.nom,
                                  style: AppTypography.h5.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (user.classe.isNotEmpty)
                                  Text(
                                    l10n.translate('class_label',
                                        params: {'class': user.classe}),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Read-only indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: AppBorders.borderSM,
                              border: Border.all(
                                color: AppColors.warning,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 16.0,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Read Only',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.verticalLG,

                  // Balance Card Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.balanceGradient,
                      borderRadius: AppBorders.borderLG,
                    ),
                    child: Padding(
                      padding: AppSpacing.paddingLG,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.translate('current_balance'),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textOnPrimary
                                      .withValues(alpha: 0.7),
                                  fontWeight: AppTypography.semiBold,
                                ),
                              ),
                              if (user != null)
                                InkWell(
                                  onTap: () {
                                    // TODO: Navigate to wallet top-up
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Wallet top-up feature coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.textOnPrimary,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Recharger',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: AppColors.textOnPrimary,
                                            fontWeight: AppTypography.semiBold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          AppSpacing.verticalSM,
                          Text(
                            user != null
                                ? AppConfig.formatPrice(user.pocket)
                                : AppConfig.formatPrice(0.0),
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          if (user != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text(
                                l10n.translate('tickets_available',
                                    params: {'count': user.tickets.toString()}),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textOnPrimary
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.verticalLG,

                  // Read-only notice
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: AppBorders.borderMD,
                      border: Border.all(
                        color: AppColors.info,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20.0,
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'Your profile information is managed by the administration and cannot be modified. Please contact support if you need to update your details.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.verticalLG,

                  // Account Information Section (Read-only)
                  Text(
                    l10n.translate('account_information'),
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.verticalMD,

                  // Read-only information cards
                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.person,
                    label: l10n.translate('full_name'),
                    value: user.displayName.isNotEmpty
                        ? user.displayName
                        : user.nom,
                  ),

                  AppSpacing.verticalMD,

                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.email,
                    label: l10n.translate('email'),
                    value: user.email,
                  ),

                  AppSpacing.verticalMD,

                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.phone,
                    label: l10n.translate('phone_number'),
                    value: user.phoneNumber.isNotEmpty
                        ? user.phoneNumber
                        : 'Not provided',
                  ),

                  AppSpacing.verticalMD,

                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.school,
                    label: l10n.translate('class'),
                    value:
                        user.classe.isNotEmpty ? user.classe : 'Not assigned',
                  ),

                  AppSpacing.verticalLG,

                  // Preferences Section (Read-only)
                  Text(
                    l10n.translate('preferences'),
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.verticalMD,

                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.language,
                    label: l10n.translate('language'),
                    value: _getLanguageDisplayName(user.language ?? 'en', l10n),
                  ),

                  AppSpacing.verticalMD,

                  _buildReadOnlyInfoCard(
                    context,
                    icon: Icons.notifications,
                    label: l10n.translate('push_notifications'),
                    value: (user.notificationsEnabled ?? true)
                        ? 'Enabled'
                        : 'Disabled',
                  ),

                  AppSpacing.verticalXL,

                  // Logout Button (only action allowed)
                  FFButtonWidget(
                    onPressed: () {
                      context.read<FFAppState>().logout();
                      context.goNamed('Login');
                    },
                    text: l10n.translate('logout'),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: AppButtonSizes.heightLarge,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: AppColors.surface,
                      textStyle: AppTypography.button.copyWith(
                        color: AppColors.error,
                      ),
                      elevation: 0.0,
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2.0,
                      ),
                      borderRadius: AppBorders.borderMD,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppBorders.borderSM,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20.0,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: AppColors.textTertiary,
            size: 16.0,
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'en':
        return l10n.translate('english');
      case 'fr':
        return l10n.translate('french');
      case 'ar':
        return l10n.translate('arabic');
      default:
        return 'English';
    }
  }
}
