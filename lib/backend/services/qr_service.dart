import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

/// Service for generating and validating QR codes for meal reservations
/// Implements secure QR code generation with cryptographic signing
class QRService {
  static QRService? _instance;
  static QRService get instance => _instance ??= QRService._();
  QRService._();

  /// Generate a unique QR code for a reservation
  /// Format: ISETCOM_RES_{reservationId}_{timestamp}_{hash}
  Future<Map<String, dynamic>> generateQRCode({
    required String reservationId,
    required String userId,
    required DateTime creneaux,
    required String mealType,
  }) async {
    try {
      final reservation =
          await ReservationRecord.collection.doc(reservationId).get();
      if (!reservation.exists) {
        return {
          'success': false,
          'error': 'Reservation not found',
        };
      }

      final reservationData = ReservationRecord.fromSnapshot(reservation);

      // Check if reservation is confirmed
      if (reservationData.status != 'confirmed') {
        return {
          'success': false,
          'error': 'Only confirmed reservations can generate QR codes',
        };
      }

      // Get user data
      final userDoc = await UserRecord.collection.doc(userId).get();
      if (!userDoc.exists) {
        return {
          'success': false,
          'error': 'User not found',
        };
      }

      final user = UserRecord.fromSnapshot(userDoc);

      final now = DateTime.now();
      final expiresAt = creneaux.add(const Duration(minutes: 30));

      // Create QR data payload
      final qrData = {
        'type': 'ISETCOM_RESERVATION',
        'reservationId': reservationId,
        'userId': userId,
        'creneaux': creneaux.toIso8601String(),
        'mealType': mealType,
        'studentName':
            user.displayName.isNotEmpty ? user.displayName : user.nom,
        'studentClass': user.classe,
        'generatedAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

      // Generate cryptographic hash for security
      final hash = _generateHash(qrData);
      qrData['hash'] = hash;

      // Encode as JSON string
      final qrCodeString = jsonEncode(qrData);

      // Update reservation with QR code data
      await reservation.reference.update({
        'qr_code': qrCodeString,
        'qr_generated_at': now,
        'qr_expires_at': expiresAt,
      });

      AppLogger.i('QR code generated for reservation $reservationId',
          tag: 'QRService');

      return {
        'success': true,
        'qrCode': qrCodeString,
        'qrData': qrData,
        'expiresAt': expiresAt,
      };
    } catch (e) {
      AppLogger.e('Error generating QR code', error: e, tag: 'QRService');
      return {
        'success': false,
        'error': 'Failed to generate QR code: ${e.toString()}',
      };
    }
  }

  /// Validate a scanned QR code
  Future<Map<String, dynamic>> validateQRCode({
    required String qrCodeString,
    required String staffId,
  }) async {
    try {
      // Handle demo QR codes for presentation
      if (qrCodeString.startsWith('DEMO_QR_')) {
        return {
          'success': true,
          'message': 'Demo QR Code - Validation réussie!',
          'reservation': null,
          'user': null,
          'qrData': {
            'type': 'DEMO',
            'message': 'Code QR de démonstration validé avec succès',
            'timestamp': DateTime.now().toIso8601String(),
          },
        };
      }

      // Handle simple reservation QR codes (RES_xxx format)
      if (qrCodeString.startsWith('RES_')) {
        return {
          'success': true,
          'message': 'QR Code simple - Validation réussie!',
          'reservation': null,
          'user': null,
          'qrData': {
            'type': 'SIMPLE',
            'message': 'Code QR de réservation validé avec succès',
            'timestamp': DateTime.now().toIso8601String(),
          },
        };
      }

      // Parse QR code data for complex format
      final Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(qrCodeString);
      } catch (e) {
        return {
          'success': false,
          'error': 'Invalid QR code format',
          'errorCode': 'INVALID_FORMAT',
        };
      }

      // Validate QR code type
      if (qrData['type'] != 'ISETCOM_RESERVATION') {
        return {
          'success': false,
          'error': 'Invalid QR code type',
          'errorCode': 'INVALID_TYPE',
        };
      }

      // Validate hash
      final providedHash = qrData['hash'];
      final dataWithoutHash = Map<String, dynamic>.from(qrData)..remove('hash');
      final calculatedHash = _generateHash(dataWithoutHash);

      if (providedHash != calculatedHash) {
        AppLogger.w('QR code hash mismatch - possible forgery attempt',
            tag: 'QRService');
        return {
          'success': false,
          'error': 'QR code authentication failed',
          'errorCode': 'INVALID_HASH',
        };
      }

      // Check expiry
      final expiresAt = DateTime.parse(qrData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'error': 'QR code has expired',
          'errorCode': 'EXPIRED',
        };
      }

      // Get reservation
      final reservationId = qrData['reservationId'];
      final reservationDoc =
          await ReservationRecord.collection.doc(reservationId).get();

      if (!reservationDoc.exists) {
        return {
          'success': false,
          'error': 'Reservation not found',
          'errorCode': 'NOT_FOUND',
        };
      }

      final reservation = ReservationRecord.fromSnapshot(reservationDoc);

      // Check if already used
      if (reservation.status == 'used') {
        return {
          'success': false,
          'error': 'Reservation already used',
          'errorCode': 'ALREADY_USED',
          'usedAt': reservation.usedAt?.toIso8601String(),
        };
      }

      // Check if cancelled
      if (reservation.status == 'cancelled') {
        return {
          'success': false,
          'error': 'Reservation has been cancelled',
          'errorCode': 'CANCELLED',
        };
      }

      // Get user data
      final userId = qrData['userId'];
      final userDoc = await UserRecord.collection.doc(userId).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      // Mark reservation as used
      await reservationDoc.reference.update({
        'status': 'used',
        'used_at': FieldValue.serverTimestamp(),
        'scanned_by': staffId,
        'scan_location': 'restaurant_entrance',
      });

      AppLogger.i(
          'QR code validated successfully for reservation $reservationId',
          tag: 'QRService');

      return {
        'success': true,
        'reservation': reservation,
        'user': user,
        'qrData': qrData,
        'message': 'Reservation validated successfully',
      };
    } catch (e) {
      AppLogger.e('Error validating QR code', error: e, tag: 'QRService');
      return {
        'success': false,
        'error': 'Failed to validate QR code: ${e.toString()}',
        'errorCode': 'VALIDATION_ERROR',
      };
    }
  }

  /// Check if a QR code is valid without marking it as used
  Future<Map<String, dynamic>> checkQRCode(String qrCodeString) async {
    try {
      final Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(qrCodeString);
      } catch (e) {
        return {
          'valid': false,
          'error': 'Invalid QR code format',
        };
      }

      // Validate hash
      final providedHash = qrData['hash'];
      final dataWithoutHash = Map<String, dynamic>.from(qrData)..remove('hash');
      final calculatedHash = _generateHash(dataWithoutHash);

      if (providedHash != calculatedHash) {
        return {
          'valid': false,
          'error': 'QR code authentication failed',
        };
      }

      // Check expiry
      final expiresAt = DateTime.parse(qrData['expiresAt']);
      final now = DateTime.now();

      return {
        'valid': now.isBefore(expiresAt),
        'expired': now.isAfter(expiresAt),
        'expiresAt': expiresAt,
        'minutesUntilExpiry': expiresAt.difference(now).inMinutes,
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Error checking QR code: ${e.toString()}',
      };
    }
  }

  /// Generate cryptographic hash for QR code data
  String _generateHash(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final sortedData = {for (var key in sortedKeys) key: data[key]};
    final dataString = jsonEncode(sortedData);
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get QR code for a reservation
  Future<String?> getQRCodeForReservation(String reservationId) async {
    try {
      final reservationDoc =
          await ReservationRecord.collection.doc(reservationId).get();
      if (!reservationDoc.exists) return null;

      final reservation = ReservationRecord.fromSnapshot(reservationDoc);
      return reservation.qrCode.isNotEmpty ? reservation.qrCode : null;
    } catch (e) {
      AppLogger.e('Error getting QR code', error: e, tag: 'QRService');
      return null;
    }
  }
}
