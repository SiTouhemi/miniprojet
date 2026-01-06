import '/flutter_flow/flutter_flow_model.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/backend/services/time_slot_service.dart';
import '/backend/services/payment_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';
import 'reservationcreneau_widget.dart' show ReservationcreneauWidget;
import 'package:flutter/material.dart';

class ReservationcreneauModel
    extends FlutterFlowModel<ReservationcreneauWidget> {
  /// Services
  final ReservationService _reservationService = ReservationService.instance;
  final TimeSlotService _timeSlotService = TimeSlotService.instance;

  /// State field for selected time slot
  TimeSlotRecord? selectedTimeSlot;

  /// State fields for reservation process
  bool isProcessingReservation = false;
  String? errorMessage;
  String? successMessage;
  
  /// Additional state management for button interactions
  DateTime? _lastReservationAttempt;
  static const Duration _reservationCooldown = Duration(seconds: 2);

  /// State fields for user balance
  double userBalance = 0.0;
  bool isLoadingBalance = false;

  /// Callback for state updates
  VoidCallback? onStateChanged;

  /// Check if reservation can be attempted (prevents rapid submissions)
  bool canAttemptReservation() {
    if (isProcessingReservation) return false;
    
    if (_lastReservationAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastReservationAttempt!);
      if (timeSinceLastAttempt < _reservationCooldown) {
        return false;
      }
    }
    
    return true;
  }

  /// Load user balance
  Future<void> loadUserBalance() async {
    if (!authService.isLoggedIn) return;

    isLoadingBalance = true;
    onStateChanged?.call();

    try {
      final userId = currentUser!.uid;
      userBalance = await PaymentService.instance.getUserBalance(userId);
    } catch (e) {
      AppLogger.e('Error loading user balance',
          error: e, tag: 'ReservationcreneauModel');
      userBalance = 0.0;
    } finally {
      isLoadingBalance = false;
      onStateChanged?.call();
    }
  }

  /// Validate if user can make reservation
  Future<Map<String, dynamic>> validateReservation() async {
    if (!authService.isLoggedIn) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    if (selectedTimeSlot == null) {
      return {
        'success': false,
        'error': 'Please select a time slot',
      };
    }

    // Validate time slot
    final timeSlotValidation =
        await _timeSlotService.validateTimeSlotForReservation(
      selectedTimeSlot!.reference.id,
    );

    if (!timeSlotValidation.isValid) {
      return {
        'success': false,
        'error':
            timeSlotValidation.errorMessage ?? 'Time slot is not available',
      };
    }

    // Validate payment
    final paymentValidation = await PaymentService.instance.validatePayment(
      userId: currentUser!.uid,
      amount: selectedTimeSlot!.price,
    );

    if (!paymentValidation['success']) {
      return {
        'success': false,
        'error': paymentValidation['message'] ?? 'Payment validation failed',
      };
    }

    return {
      'success': true,
      'timeSlot': timeSlotValidation.timeSlot,
      'balance': paymentValidation['balance'],
    };
  }

  /// Create reservation
  Future<Map<String, dynamic>> createReservation() async {
    // Check if reservation can be attempted
    if (!canAttemptReservation()) {
      return {
        'success': false, 
        'error': isProcessingReservation 
            ? 'Already processing' 
            : 'Please wait before trying again'
      };
    }

    // Record attempt timestamp
    _lastReservationAttempt = DateTime.now();
    
    isProcessingReservation = true;
    errorMessage = null;
    successMessage = null;
    onStateChanged?.call();

    try {
      // Validate reservation
      final validation = await validateReservation();
      if (!validation['success']) {
        errorMessage = validation['error'];
        return validation;
      }

      final userId = currentUser!.uid;
      final timeSlotId = selectedTimeSlot!.reference.id;
      final amount = selectedTimeSlot!.price;

      // Create reservation with wallet deduction (no separate payment processing needed)
      final reservationResult = await _reservationService.createReservation(
        userId: userId,
        timeSlotId: timeSlotId,
        mealType: selectedTimeSlot!.mealType,
        amount: amount,
        capacity: 1,
      );

      if (reservationResult['success']) {
        successMessage = 'Reservation created successfully! ${amount.toStringAsFixed(2)} TND deducted from wallet.';

        // Reload user balance to reflect the deduction
        await loadUserBalance();

        // Clear selected time slot to prevent accidental re-submission
        selectedTimeSlot = null;

        return {
          'success': true,
          'reservationId': reservationResult['reservationId'],
          'newBalance': reservationResult['newBalance'],
          'deductedAmount': amount,
          'message': successMessage,
        };
      } else {
        errorMessage = reservationResult['error'] ?? 'Failed to create reservation';
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      errorMessage = 'Unexpected error: ${e.toString()}';
      AppLogger.e('Error creating reservation',
          error: e, tag: 'ReservationcreneauModel');
      return {
        'success': false,
        'error': errorMessage,
      };
    } finally {
      isProcessingReservation = false;
      onStateChanged?.call();
    }
  }

  /// Clear messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    onStateChanged?.call();
  }

  /// Reset reservation state (useful for cleanup)
  void resetReservationState() {
    isProcessingReservation = false;
    errorMessage = null;
    successMessage = null;
    _lastReservationAttempt = null;
    onStateChanged?.call();
  }

  /// Check if user can afford the selected time slot
  bool canAffordSelectedSlot() {
    if (selectedTimeSlot == null) return false;
    return userBalance >= selectedTimeSlot!.price;
  }

  @override
  void initState(BuildContext context) {
    // Load user balance when model initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserBalance();
    });
  }

  @override
  void dispose() {
    // Clean up any ongoing operations
    resetReservationState();
    onStateChanged = null;
  }
}
