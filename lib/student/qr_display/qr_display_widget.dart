import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/design_system/app_theme.dart';
import '/l10n/app_localizations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/app_logger.dart';
import 'qr_display_model.dart';

/// Widget to display QR code for meal pickup
/// Shows QR code with reservation details and expiry countdown
class QRDisplayWidget extends StatefulWidget {
  final ReservationRecord reservation;

  const QRDisplayWidget({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  State<QRDisplayWidget> createState() => _QRDisplayWidgetState();
}

class _QRDisplayWidgetState extends State<QRDisplayWidget> {
  late QRDisplayModel _model;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _model = QRDisplayModel();
    _model.setReservation(widget.reservation);
    
    // Keep screen on while displaying QR
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _model.updateExpiryCountdown();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            l10n.translate('qr_code_title'),
            style: AppTypography.h4.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<QRDisplayModel>(
          builder: (context, model, child) {
            if (model.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    AppSpacing.verticalMD,
                    Text(
                      l10n.loading,
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            if (model.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: AppSpacing.paddingXL,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: AppIconSizes.xxxl,
                        color: AppColors.error,
                      ),
                      AppSpacing.verticalMD,
                      Text(
                        l10n.error,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      AppSpacing.verticalSM,
                      Text(
                        model.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.verticalXL,
                      FFButtonWidget(
                        onPressed: () => model.generateQRCode(),
                        text: l10n.retry,
                        options: FFButtonOptions(
                          color: AppColors.primary,
                          textStyle: AppTypography.buttonMedium.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!model.hasQRCode) {
              return Center(
                child: Padding(
                  padding: AppSpacing.paddingXL,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: AppIconSizes.xxxl,
                        color: AppColors.textTertiary,
                      ),
                      AppSpacing.verticalMD,
                      Text(
                        l10n.translate('no_qr_code'),
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.verticalXL,
                      FFButtonWidget(
                        onPressed: model.isGenerating ? null : () => model.generateQRCode(),
                        text: model.isGenerating 
                            ? l10n.loading 
                            : l10n.translate('generate_qr'),
                        options: FFButtonOptions(
                          color: AppColors.primary,
                          textStyle: AppTypography.buttonMedium.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Display QR code
            return SingleChildScrollView(
              child: Padding(
                padding: AppSpacing.paddingXL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppSpacing.verticalMD,
                    
                    // Instructions
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: AppColors.infoLight.withValues(alpha: 0.1),
                        borderRadius: AppBorders.borderMD,
                        border: Border.all(
                          color: AppColors.info,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          AppSpacing.horizontalSM,
                          Expanded(
                            child: Text(
                              l10n.translate('qr_instructions'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    AppSpacing.verticalXL,
                    
                    // QR Code
                    Container(
                      padding: AppSpacing.paddingXL,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppBorders.borderLG,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: model.qrCode!,
                        version: QrVersions.auto,
                        size: 280.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                    
                    AppSpacing.verticalXL,
                    
                    // Expiry status
                    if (model.isExpired)
                      Container(
                        padding: AppSpacing.paddingMD,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight.withValues(alpha: 0.1),
                          borderRadius: AppBorders.borderMD,
                          border: Border.all(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: AppColors.error),
                            AppSpacing.horizontalSM,
                            Text(
                              l10n.translate('qr_expired'),
                              style: AppTypography.h6.copyWith(
                                color: AppColors.error,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: AppSpacing.paddingMD,
                        decoration: BoxDecoration(
                          color: model.minutesUntilExpiry < 10
                              ? AppColors.warningLight.withValues(alpha: 0.1)
                              : AppColors.successLight.withValues(alpha: 0.1),
                          borderRadius: AppBorders.borderMD,
                          border: Border.all(
                            color: model.minutesUntilExpiry < 10
                                ? AppColors.warning
                                : AppColors.success,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              color: model.minutesUntilExpiry < 10
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            AppSpacing.horizontalSM,
                            Text(
                              l10n.translate('qr_expires_in', params: {
                                'minutes': model.minutesUntilExpiry.toString(),
                              }),
                              style: AppTypography.bodyLarge.copyWith(
                                color: model.minutesUntilExpiry < 10
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    AppSpacing.verticalXL,
                    
                    // Reservation details
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingLG,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppBorders.borderMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('reservation_details'),
                            style: AppTypography.h6.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.verticalMD,
                          _buildDetailRow(
                            Icons.restaurant,
                            l10n.translate('meal_type'),
                            widget.reservation.type,
                          ),
                          AppSpacing.verticalSM,
                          _buildDetailRow(
                            Icons.access_time,
                            l10n.translate('time_label'),
                            _formatDateTime(widget.reservation.creneaux!),
                          ),
                          AppSpacing.verticalSM,
                          _buildDetailRow(
                            Icons.confirmation_number,
                            l10n.translate('reservation_id'),
                            widget.reservation.reference.id.substring(0, 8),
                          ),
                        ],
                      ),
                    ),
                    
                    AppSpacing.verticalXL,
                    
                    // Regenerate button
                    if (model.isExpired || model.minutesUntilExpiry < 5)
                      SizedBox(
                        width: double.infinity,
                        child: FFButtonWidget(
                          onPressed: model.isGenerating ? null : () => model.generateQRCode(),
                          text: model.isGenerating
                              ? l10n.loading
                              : l10n.translate('regenerate_qr'),
                          icon: Icon(Icons.refresh, size: AppIconSizes.sm),
                          options: FFButtonOptions(
                            color: AppColors.primary,
                            textStyle: AppTypography.buttonMedium.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                            padding: AppSpacing.paddingMD,
                          ),
                        ),
                      ),
                    
                    AppSpacing.verticalXL,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppIconSizes.md, color: AppColors.primary),
        AppSpacing.horizontalSM,
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
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
}
