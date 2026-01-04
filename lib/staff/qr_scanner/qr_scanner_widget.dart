import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/design_system/app_theme.dart';
import '/l10n/app_localizations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'qr_scanner_model.dart';
import '/staff/reservation_validator/reservation_validator_widget.dart';

/// QR Scanner widget for staff to validate student reservations
/// Uses mobile_scanner for real-time QR code detection
class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({Key? key}) : super(key: key);

  static String routeName = 'QRScanner';
  static String routePath = '/qr-scanner';

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late QRScannerModel _model;

  @override
  void initState() {
    super.initState();
    _model = QRScannerModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            l10n.translate('scan_qr_title'),
            style: AppTypography.h4.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: AppColors.textOnPrimary),
              onPressed: () => _showScanHistory(context),
            ),
          ],
        ),
        body: Consumer<QRScannerModel>(
          builder: (context, model, child) {
            if (model.scanSuccess && model.scannedReservation != null) {
              // Show validation result
              return ReservationValidatorWidget(
                reservation: model.scannedReservation!,
                user: model.scannedUser,
                onContinue: () => model.resetScan(),
              );
            }

            if (model.errorMessage != null) {
              // Show error overlay
              return Stack(
                children: [
                  _buildScanner(model),
                  _buildErrorOverlay(model, l10n),
                ],
              );
            }

            return _buildScanner(model);
          },
        ),
      ),
    );
  }

  Widget _buildScanner(QRScannerModel model) {
    final l10n = AppLocalizations.of(context)!;
    
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: model.scannerController,
          onDetect: (capture) {
            if (!model.isProcessing && currentUser != null) {
              model.handleBarcode(capture, currentUser!.uid);
            }
          },
        ),
        
        // Scanning overlay
        CustomPaint(
          painter: ScannerOverlayPainter(),
          child: Container(),
        ),
        
        // Instructions
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: AppBorders.borderMD,
            ),
            child: Text(
              l10n.translate('scan_instructions'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Controls
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.flash_on,
                label: l10n.translate('torch'),
                onPressed: () => model.toggleTorch(),
              ),
              _buildControlButton(
                icon: Icons.flip_camera_android,
                label: l10n.translate('flip_camera'),
                onPressed: () => model.switchCamera(),
              ),
            ],
          ),
        ),
        
        // Processing indicator
        if (model.isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  AppSpacing.verticalMD,
                  Text(
                    l10n.translate('validating'),
                    style: AppTypography.h6.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorOverlay(QRScannerModel model, AppLocalizations l10n) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getErrorIcon(model.errorCode),
                size: AppIconSizes.xxxl * 1.5,
                color: _getErrorColor(model.errorCode),
              ),
              AppSpacing.verticalXL,
              Text(
                _getErrorTitle(model.errorCode, l10n),
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontWeight: AppTypography.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalMD,
              Text(
                model.errorMessage ?? l10n.error,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalXL,
              SizedBox(
                width: double.infinity,
                child: FFButtonWidget(
                  onPressed: () => model.resetScan(),
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
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: AppIconSizes.lg),
            onPressed: onPressed,
          ),
        ),
        AppSpacing.verticalSM,
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  IconData _getErrorIcon(String? errorCode) {
    switch (errorCode) {
      case 'EXPIRED':
        return Icons.access_time;
      case 'ALREADY_USED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'INVALID_FORMAT':
      case 'INVALID_TYPE':
      case 'INVALID_HASH':
        return Icons.warning;
      default:
        return Icons.error;
    }
  }

  Color _getErrorColor(String? errorCode) {
    switch (errorCode) {
      case 'EXPIRED':
        return AppColors.warning;
      case 'ALREADY_USED':
        return AppColors.info;
      case 'CANCELLED':
      case 'INVALID_FORMAT':
      case 'INVALID_TYPE':
      case 'INVALID_HASH':
        return AppColors.error;
      default:
        return AppColors.error;
    }
  }

  String _getErrorTitle(String? errorCode, AppLocalizations l10n) {
    switch (errorCode) {
      case 'EXPIRED':
        return l10n.translate('scan_expired');
      case 'ALREADY_USED':
        return l10n.translate('scan_already_used');
      case 'CANCELLED':
        return l10n.translate('reservation_cancelled');
      case 'INVALID_FORMAT':
      case 'INVALID_TYPE':
      case 'INVALID_HASH':
        return l10n.translate('scan_invalid');
      default:
        return l10n.error;
    }
  }

  void _showScanHistory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<QRScannerModel>(
        builder: (context, model, child) {
          return Container(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('scan_history'),
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.verticalMD,
                Expanded(
                  child: model.scanHistory.isEmpty
                      ? Center(
                          child: Text(
                            l10n.translate('no_scans_yet'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: model.scanHistory.length,
                          itemBuilder: (context, index) {
                            final scan = model.scanHistory[index];
                            return _buildHistoryItem(scan, l10n);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> scan, AppLocalizations l10n) {
    final timestamp = scan['timestamp'] as DateTime;
    final success = scan['success'] as bool;
    
    return Card(
      margin: AppSpacing.marginSM.copyWith(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? AppColors.success : AppColors.error,
        ),
        title: Text(
          success
              ? '${scan['user']?.displayName ?? scan['user']?.nom ?? 'Unknown'}'
              : scan['error'] ?? 'Error',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw overlay with transparent scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bracketLength = 30.0;

    // Top-left
    canvas.drawLine(Offset(left, top + bracketLength), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLength, top), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top), 
        Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), 
        Offset(left + scanAreaSize, top + bracketLength), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanAreaSize - bracketLength), 
        Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), 
        Offset(left + bracketLength, top + scanAreaSize), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top + scanAreaSize), 
        Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize - bracketLength), 
        Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
