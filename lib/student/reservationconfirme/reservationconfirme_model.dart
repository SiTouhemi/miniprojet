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
      // Get reservation
      final reservationDoc =
          await ReservationRecord.collection.doc(reservationId).get();
      if (reservationDoc.exists) {
        reservation = ReservationRecord.fromSnapshot(reservationDoc);

        // Get user data
        if (reservation!.userId.isNotEmpty) {
          final userDoc =
              await UserRecord.collection.doc(reservation!.userId).get();
          if (userDoc.exists) {
            user = UserRecord.fromSnapshot(userDoc);
          }
        }
      } else {
        errorMessage = 'Reservation not found';
      }
    } catch (e) {
      AppLogger.e('Error loading reservation data',
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
    return reservation?.type ?? 'Repas';
  }

  /// Get price
  String getPrice() {
    return '${reservation?.prix?.toStringAsFixed(2) ?? '0.00'} TND';
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
