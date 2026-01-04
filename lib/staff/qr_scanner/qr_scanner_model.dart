import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '/backend/backend.dart';
import '/backend/services/qr_service.dart';
import '/utils/app_logger.dart';

class QRScannerModel extends ChangeNotifier {
  final QRService _qrService = QRService.instance;
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _scanSuccess = false;
  String? _errorMessage;
  String? _errorCode;
  Map<String, dynamic>? _validationResult;
  ReservationRecord? _scannedReservation;
  UserRecord? _scannedUser;
  List<Map<String, dynamic>> _scanHistory = [];

  bool get isProcessing => _isProcessing;
  bool get scanSuccess => _scanSuccess;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get validationResult => _validationResult;
  ReservationRecord? get scannedReservation => _scannedReservation;
  UserRecord? get scannedUser => _scannedUser;
  List<Map<String, dynamic>> get scanHistory => _scanHistory;

  Future<void> handleBarcode(BarcodeCapture capture, String staffId) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    await validateScannedCode(code, staffId);
  }

  Future<void> validateScannedCode(String qrCode, String staffId) async {
    _isProcessing = true;
    _scanSuccess = false;
    _errorMessage = null;
    _errorCode = null;
    _validationResult = null;
    _scannedReservation = null;
    _scannedUser = null;
    notifyListeners();

    try {
      final result = await _qrService.validateQRCode(
        qrCodeString: qrCode,
        staffId: staffId,
      );

      _validationResult = result;

      if (result['success']) {
        _scanSuccess = true;
        _scannedReservation = result['reservation'];
        _scannedUser = result['user'];
        
        // Add to scan history
        _scanHistory.insert(0, {
          'timestamp': DateTime.now(),
          'success': true,
          'reservation': _scannedReservation,
          'user': _scannedUser,
        });

        AppLogger.i('QR code scanned successfully', tag: 'QRScannerModel');
      } else {
        _errorMessage = result['error'];
        _errorCode = result['errorCode'];
        
        // Add to scan history
        _scanHistory.insert(0, {
          'timestamp': DateTime.now(),
          'success': false,
          'error': _errorMessage,
          'errorCode': _errorCode,
        });

        AppLogger.w('QR code validation failed: $_errorMessage', tag: 'QRScannerModel');
      }

      // Limit history to 50 items
      if (_scanHistory.length > 50) {
        _scanHistory = _scanHistory.sublist(0, 50);
      }
    } catch (e) {
      _errorMessage = 'Error validating QR code: ${e.toString()}';
      _errorCode = 'VALIDATION_ERROR';
      AppLogger.e('Error in QR validation', error: e, tag: 'QRScannerModel');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void resetScan() {
    _scanSuccess = false;
    _errorMessage = null;
    _errorCode = null;
    _validationResult = null;
    _scannedReservation = null;
    _scannedUser = null;
    notifyListeners();
  }

  void toggleTorch() {
    scannerController.toggleTorch();
    notifyListeners();
  }

  void switchCamera() {
    scannerController.switchCamera();
    notifyListeners();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }
}
