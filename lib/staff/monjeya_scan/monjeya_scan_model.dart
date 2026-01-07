import '/flutter_flow/flutter_flow_model.dart';
import '/backend/services/reservation_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';
import 'monjeya_scan_widget.dart' show MonjeyaScanWidget;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class MonjeyaScanModel extends FlutterFlowModel<MonjeyaScanWidget> {
  /// Mobile Scanner controller
  MobileScannerController? scannerController;

  /// State fields
  bool isScanning = false;
  bool isProcessing = false;
  String? lastScannedCode;
  String? successMessage;
  String? errorMessage;
  Map<String, dynamic>? validationResult;

  /// Callback for state updates
  VoidCallback? onStateChanged;

  /// Initialize scanner
  void initializeScanner() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  /// Handle barcode detection
  void onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !isProcessing) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code != lastScannedCode) {
        lastScannedCode = code;
        validateQRCode(code);
      }
    }
  }

  /// Validate scanned QR code
  Future<void> validateQRCode(String qrToken) async {
    if (isProcessing) return;

    isProcessing = true;
    errorMessage = null;
    successMessage = null;
    validationResult = null;
    onStateChanged?.call();

    try {
      // Pause scanning while processing
      await scannerController?.stop();

      final result = await ReservationService.instance.validateQRCode(
        qrCode: qrToken,
        staffId: currentUser?.uid ?? '',
      );

      if (result['success'] == true) {
        successMessage = result['message'] ?? 'QR code validated successfully';
        validationResult = result['reservation'];

        // Play success sound/vibration here if needed
        AppLogger.i('QR code validated successfully', tag: 'MonjeyaScanModel');

        // Auto-clear success message after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          clearMessages();
          resumeScanning();
        });
      } else {
        errorMessage = result['error'] ?? 'Failed to validate QR code';
        AppLogger.w('QR validation failed: ${errorMessage}',
            tag: 'MonjeyaScanModel');

        // Auto-clear error message after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          clearMessages();
          resumeScanning();
        });
      }
    } catch (e) {
      errorMessage = 'Error validating QR code: ${e.toString()}';
      AppLogger.e('Error validating QR code',
          error: e, tag: 'MonjeyaScanModel');

      // Auto-clear error message after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        clearMessages();
        resumeScanning();
      });
    } finally {
      isProcessing = false;
      onStateChanged?.call();
    }
  }

  /// Resume scanning
  Future<void> resumeScanning() async {
    lastScannedCode = null; // Reset to allow rescanning same code
    await scannerController?.start();
    onStateChanged?.call();
  }

  /// Clear messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    validationResult = null;
    onStateChanged?.call();
  }

  /// Toggle flashlight
  Future<void> toggleFlash() async {
    await scannerController?.toggleTorch();
  }

  /// Flip camera
  Future<void> flipCamera() async {
    await scannerController?.switchCamera();
  }

  /// Get student name from validation result
  String getStudentName() {
    return validationResult?['studentName'] ?? 'Unknown Student';
  }

  /// Get student class from validation result
  String getStudentClass() {
    return validationResult?['studentClass'] ?? '';
  }

  /// Get meal type from validation result
  String getMealType() {
    return validationResult?['mealType'] ?? 'Meal';
  }

  /// Get reservation time from validation result
  String getReservationTime() {
    final timeStr = validationResult?['reservationTime'];
    if (timeStr != null) {
      try {
        final dateTime = DateTime.parse(timeStr);
        return DateFormat('HH:mm').format(dateTime);
      } catch (e) {
        return 'Unknown time';
      }
    }
    return 'Unknown time';
  }

  /// Get price from validation result
  String getPrice() {
    final price = validationResult?['price'];
    return '${price?.toStringAsFixed(2) ?? '0.00'} TND';
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    scannerController?.dispose();
  }
}
