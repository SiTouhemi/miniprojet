import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/qr_service.dart';
import '/utils/app_logger.dart';

class QRDisplayModel extends ChangeNotifier {
  final QRService _qrService = QRService.instance;

  ReservationRecord? _reservation;
  String? _qrCode;
  Map<String, dynamic>? _qrData;
  DateTime? _expiresAt;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  int _minutesUntilExpiry = 0;

  ReservationRecord? get reservation => _reservation;
  String? get qrCode => _qrCode;
  Map<String, dynamic>? get qrData => _qrData;
  DateTime? get expiresAt => _expiresAt;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  int get minutesUntilExpiry => _minutesUntilExpiry;
  bool get isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);
  bool get hasQRCode => _qrCode != null && _qrCode!.isNotEmpty;

  void setReservation(ReservationRecord reservation) {
    _reservation = reservation;
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    if (_reservation == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if reservation already has a QR code
      if (_reservation!.qrCode.isNotEmpty) {
        _qrCode = _reservation!.qrCode;

        // Parse QR data
        try {
          final qrData = await _qrService.checkQRCode(_qrCode!);
          if (qrData['valid']) {
            _expiresAt = qrData['expiresAt'];
            _minutesUntilExpiry = qrData['minutesUntilExpiry'];
          } else {
            // QR code is invalid or expired, generate new one
            await generateQRCode();
            return;
          }
        } catch (e) {
          AppLogger.w('Error parsing existing QR code',
              error: e, tag: 'QRDisplayModel');
          await generateQRCode();
          return;
        }
      } else {
        // No QR code exists, generate one
        await generateQRCode();
        return;
      }
    } catch (e) {
      _errorMessage = 'Failed to load QR code: ${e.toString()}';
      AppLogger.e('Error loading QR code', error: e, tag: 'QRDisplayModel');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateQRCode() async {
    if (_reservation == null) return;

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _qrService.generateQRCode(
        reservationId: _reservation!.reference.id,
        userId: _reservation!.userId,
        creneaux: _reservation!.creneaux!,
        mealType: _reservation!.type,
      );

      if (result['success']) {
        _qrCode = result['qrCode'];
        _qrData = result['qrData'];
        _expiresAt = result['expiresAt'];
        _minutesUntilExpiry = _expiresAt!.difference(DateTime.now()).inMinutes;
      } else {
        _errorMessage = result['error'];
      }
    } catch (e) {
      _errorMessage = 'Failed to generate QR code: ${e.toString()}';
      AppLogger.e('Error generating QR code', error: e, tag: 'QRDisplayModel');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void updateExpiryCountdown() {
    if (_expiresAt != null) {
      _minutesUntilExpiry = _expiresAt!.difference(DateTime.now()).inMinutes;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
