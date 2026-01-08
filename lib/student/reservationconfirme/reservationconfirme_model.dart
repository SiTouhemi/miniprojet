import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/utils/app_logger.dart';
import 'reservationconfirme_widget.dart' show ReservationconfirmeWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReservationconfirmeModel
    extends FlutterFlowModel<ReservationconfirmeWidget> {
  /// State fields
  ReservationRecord? reservation;
  UserRecord? user;
  bool isLoading = true;
  String? errorMessage;

  /// Load reservation data
  Future<void> loadReservationData(String reservationId) async {
    isLoading = true;
    errorMessage = null;

    try {
      // Simulate loading time for demo
      await Future.delayed(Duration(milliseconds: 500));

      // Create demo reservation data
      final now = DateTime.now();
      final demoReservationData = {
        'user_id': 'demo_user_123',
        'type': 'lunch',
        'creneaux': now.add(Duration(hours: 2)),
        'prix': 5000, // 5.00 TND in millimes
        'status': 'confirmed',
        'qr_code': 'DEMO_QR_CODE_${now.millisecondsSinceEpoch}',
        'created_at': now,
      };

      // Create demo user data
      final demoUserData = {
        'nom': 'Ahmed Zouari',
        'email': 'ahmed.zouari@etudiant.isetcom.tn',
        'classe': '3DSI2',
        'pocket': 35.55,
        'display_name': 'Ahmed Zouari',
      };

      // Create demo objects (without actually saving to Firestore)
      reservation = ReservationRecord.getDocumentFromData(
        demoReservationData,
        ReservationRecord.collection.doc(reservationId),
      );

      user = UserRecord.getDocumentFromData(
        demoUserData,
        UserRecord.collection.doc('demo_user_123'),
      );
    } catch (e) {
      AppLogger.e('Error loading demo reservation data',
          error: e, tag: 'ReservationconfirmeModel');
      errorMessage = 'Failed to load reservation: ${e.toString()}';
    } finally {
      isLoading = false;
    }
  }

  /// Get formatted date
  String getFormattedDate() {
    if (reservation?.creneaux == null) return 'Date non disponible';
    return DateFormat('dd MMMM yyyy').format(reservation!.creneaux!);
  }

  /// Get formatted time
  String getFormattedTime() {
    if (reservation?.creneaux == null) return 'Heure non disponible';
    return DateFormat('HH:mm').format(reservation!.creneaux!);
  }

  /// Get meal type
  String getMealType() {
    final type = reservation?.type ?? 'lunch';
    return type == 'lunch' ? 'Déjeuner' : 'Dîner';
  }

  /// Get price
  String getPrice() {
    if (reservation?.prix == null) return '0.00 TND';
    // Convert from millimes to TND
    final priceInTND = reservation!.prix / 1000.0;
    return '${priceInTND.toStringAsFixed(2)} TND';
  }

  /// Get payment status
  String getPaymentStatus() {
    return reservation?.status == 'confirmed' || reservation?.status == 'used'
        ? 'Payé'
        : 'En attente';
  }

  /// Get payment status color
  Color getPaymentStatusColor(BuildContext context) {
    final status = reservation?.status;
    if (status == 'confirmed' || status == 'used') {
      return FlutterFlowTheme.of(context).success;
    } else if (status == 'cancelled') {
      return FlutterFlowTheme.of(context).error;
    } else {
      return FlutterFlowTheme.of(context).warning;
    }
  }

  /// Check if QR code is available
  bool hasQRCode() {
    return reservation?.qrCode?.isNotEmpty == true;
  }

  /// Get QR code data
  String getQRCodeData() {
    return reservation?.qrCode ?? '';
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
