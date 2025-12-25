import '/flutter_flow/flutter_flow_model.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/backend/services/time_slot_service.dart';
import '/utils/app_logger.dart';
import 'reservation_management_widget.dart' show ReservationManagementWidget;
import 'package:flutter/material.dart';

class ReservationManagementModel extends FlutterFlowModel<ReservationManagementWidget> {
  /// State fields for reservation management
  List<ReservationRecord> userReservations = [];
  List<TimeSlotRecord> availableTimeSlots = [];
  
  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;
  String? successMessage;

  /// Services
  final ReservationService reservationService = ReservationService.instance;
  final TimeSlotService timeSlotService = TimeSlotService.instance;

  /// Unfocus node for form management
  final unfocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Load user's upcoming reservations
  Future<void> loadUserReservations(String userId) async {
    isLoading = true;
    errorMessage = null;
    
    try {
      userReservations = await reservationService.getUpcomingReservations(userId);
      isLoading = false;
    } catch (e) {
      errorMessage = 'Failed to load reservations: ${e.toString()}';
      isLoading = false;
    }
  }

  /// Load available time slots for modification
  Future<void> loadAvailableTimeSlots() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      availableTimeSlots = await timeSlotService.getAvailableTimeSlots(tomorrow);
    } catch (e) {
      AppLogger.e('Error loading time slots', error: e, tag: 'ReservationManagementModel');
    }
  }

  /// Check if a reservation can be cancelled
  Future<Map<String, dynamic>> checkCancellationEligibility(
    String reservationId,
    String userId,
  ) async {
    return await reservationService.canCancelReservation(
      reservationId: reservationId,
      userId: userId,
    );
  }

  /// Check if a reservation can be modified
  Future<Map<String, dynamic>> checkModificationEligibility(
    String reservationId,
    String userId,
  ) async {
    return await reservationService.canModifyReservation(
      reservationId: reservationId,
      userId: userId,
    );
  }

  /// Cancel a reservation
  Future<Map<String, dynamic>> cancelReservation(
    String reservationId,
    String reason,
  ) async {
    isProcessing = true;
    errorMessage = null;
    successMessage = null;

    try {
      final result = await reservationService.cancelReservationCloudFunction(
        reservationId: reservationId,
        reason: reason,
      );

      if (result['success']) {
        successMessage = 'Reservation cancelled successfully';
      } else {
        errorMessage = result['error'] ?? 'Failed to cancel reservation';
      }

      isProcessing = false;
      return result;
    } catch (e) {
      errorMessage = 'Error cancelling reservation: ${e.toString()}';
      isProcessing = false;
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Modify a reservation
  Future<Map<String, dynamic>> modifyReservation(
    String reservationId,
    String newTimeSlotId,
  ) async {
    isProcessing = true;
    errorMessage = null;
    successMessage = null;

    try {
      final result = await reservationService.modifyReservationCloudFunction(
        reservationId: reservationId,
        newTimeSlotId: newTimeSlotId,
      );

      if (result['success']) {
        successMessage = 'Reservation modified successfully';
      } else {
        errorMessage = result['error'] ?? 'Failed to modify reservation';
      }

      isProcessing = false;
      return result;
    } catch (e) {
      errorMessage = 'Error modifying reservation: ${e.toString()}';
      isProcessing = false;
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Clear messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  /// Get status color for reservation status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'used':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get restriction message for reservations that cannot be modified/cancelled
  String getRestrictionMessage(ReservationRecord reservation, int hoursUntilMeal) {
    if (reservation.status == 'cancelled') {
      return 'This reservation has been cancelled';
    }
    if (reservation.status == 'used') {
      return 'This reservation has been used';
    }
    if (reservation.creneaux!.isBefore(DateTime.now())) {
      return 'Past reservations cannot be modified or cancelled';
    }
    if (hoursUntilMeal < 2) {
      return 'Cannot modify or cancel less than 2 hours before meal time';
    }
    return 'Modification and cancellation not available';
  }

  /// Check if reservation can be modified or cancelled
  bool canModifyOrCancel(ReservationRecord reservation) {
    final now = DateTime.now();
    final hoursUntilMeal = reservation.creneaux?.difference(now).inHours ?? 0;
    
    return hoursUntilMeal >= 2 && 
           reservation.creneaux!.isAfter(now) &&
           (reservation.status == 'confirmed' || reservation.status == 'pending');
  }
}