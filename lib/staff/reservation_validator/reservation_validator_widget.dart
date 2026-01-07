import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/design_system/app_theme.dart';
import '/l10n/app_localizations.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/config/app_config.dart';

/// Widget to display validation results after successful QR scan
/// Shows student details and reservation information
class ReservationValidatorWidget extends StatelessWidget {
  final ReservationRecord reservation;
  final UserRecord? user;
  final VoidCallback onContinue;

  const ReservationValidatorWidget({
    Key? key,
    required this.reservation,
    this.user,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.successLight.withValues(alpha: 0.1),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingXL,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.white,
                  ),
                ),

                AppSpacing.verticalXL,

                Text(
                  l10n.translate('scan_success'),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.success,
                    fontWeight: AppTypography.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.verticalXL,

                // Student details card
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingLG,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppBorders.borderLG,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: AppIconSizes.lg,
                          ),
                          AppSpacing.horizontalMD,
                          Text(
                            l10n.translate('student_information'),
                            style: AppTypography.h5.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalLG,
                      _buildInfoRow(
                        l10n.translate('full_name'),
                        user?.displayName ?? user?.nom ?? 'Unknown',
                      ),
                      AppSpacing.verticalMD,
                      _buildInfoRow(
                        l10n.translate('class'),
                        user?.classe ?? 'N/A',
                      ),
                      AppSpacing.verticalMD,
                      _buildInfoRow(
                        l10n.translate('email'),
                        user?.email ?? 'N/A',
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalLG,

                // Reservation details card
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingLG,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppBorders.borderLG,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: AppColors.primary,
                            size: AppIconSizes.lg,
                          ),
                          AppSpacing.horizontalMD,
                          Text(
                            l10n.translate('reservation_details'),
                            style: AppTypography.h5.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalLG,
                      _buildInfoRow(
                        l10n.translate('meal_type'),
                        _getMealTypeLabel(reservation.type, l10n),
                      ),
                      AppSpacing.verticalMD,
                      _buildInfoRow(
                        l10n.translate('time_label'),
                        _formatDateTime(reservation.creneaux!),
                      ),
                      AppSpacing.verticalMD,
                      _buildInfoRow(
                        l10n.translate('price_label'),
                        AppConfig.formatPrice(reservation.prix / 1000.0),
                      ),
                      AppSpacing.verticalMD,
                      _buildInfoRow(
                        l10n.translate('reservation_id'),
                        reservation.reference.id.substring(0, 12),
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalXL,

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: FFButtonWidget(
                    onPressed: onContinue,
                    text: l10n.translate('scan_another'),
                    icon: Icon(Icons.qr_code_scanner, size: AppIconSizes.md),
                    options: FFButtonOptions(
                      color: AppColors.primary,
                      textStyle: AppTypography.buttonLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                      padding: AppSpacing.paddingLG,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppSpacing.horizontalMD,
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMealTypeLabel(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return l10n.translate('breakfast');
      case 'lunch':
        return l10n.translate('lunch');
      case 'dinner':
        return l10n.translate('dinner');
      default:
        return type;
    }
  }
}
