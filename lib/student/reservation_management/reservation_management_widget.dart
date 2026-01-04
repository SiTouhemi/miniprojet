import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/backend/services/time_slot_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import '/config/app_config.dart';

/// Widget for managing user reservations with cancellation and modification
/// Implements Requirements 5.5, 5.7 for reservation management
class ReservationManagementWidget extends StatefulWidget {
  const ReservationManagementWidget({Key? key}) : super(key: key);

  @override
  State<ReservationManagementWidget> createState() => _ReservationManagementWidgetState();
}

class _ReservationManagementWidgetState extends State<ReservationManagementWidget> {
  final ReservationService _reservationService = ReservationService.instance;
  final TimeSlotService _timeSlotService = TimeSlotService.instance;
  
  List<ReservationRecord> _userReservations = [];
  List<TimeSlotRecord> _availableTimeSlots = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserReservations();
  }

  Future<void> _loadUserReservations() async {
    if (!authService.isLoggedIn) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = currentUser!.uid;
      final reservations = await _reservationService.getUpcomingReservations(userId);
      
      setState(() {
        _userReservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reservations: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final timeSlots = await _timeSlotService.getAvailableTimeSlots(tomorrow);
      
      setState(() {
        _availableTimeSlots = timeSlots;
      });
    } catch (e) {
      AppLogger.e('Error loading time slots', error: e, tag: 'ReservationManagementWidget');
    }
  }

  Future<void> _cancelReservation(ReservationRecord reservation) async {
    // First check if cancellation is allowed
    final canCancelResult = await _reservationService.canCancelReservation(
      reservationId: reservation.reference.id,
      userId: currentUser!.uid,
    );

    if (!canCancelResult['canCancel']) {
      _showErrorDialog('Cannot Cancel', canCancelResult['reason']);
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showCancellationDialog(reservation);
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Use Cloud Function for atomic operations
      final result = await _reservationService.cancelReservationCloudFunction(
        reservationId: reservation.reference.id,
        reason: 'User requested cancellation',
      );

      if (result['success']) {
        setState(() {
          _successMessage = 'Reservation cancelled successfully';
          _isProcessing = false;
        });
        
        // Reload reservations
        await _loadUserReservations();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to cancel reservation';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cancelling reservation: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _modifyReservation(ReservationRecord reservation) async {
    // First check if modification is allowed
    final canModifyResult = await _reservationService.canModifyReservation(
      reservationId: reservation.reference.id,
      userId: currentUser!.uid,
    );

    if (!canModifyResult['canModify']) {
      _showErrorDialog('Cannot Modify', canModifyResult['reason']);
      return;
    }

    // Load available time slots
    await _loadAvailableTimeSlots();

    if (_availableTimeSlots.isEmpty) {
      _showErrorDialog('No Available Slots', 'No alternative time slots are available for modification.');
      return;
    }

    // Show time slot selection dialog
    final selectedTimeSlot = await _showTimeSlotSelectionDialog();
    if (selectedTimeSlot == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Use Cloud Function for atomic operations
      final result = await _reservationService.modifyReservationCloudFunction(
        reservationId: reservation.reference.id,
        newTimeSlotId: selectedTimeSlot.reference.id,
      );

      if (result['success']) {
        setState(() {
          _successMessage = 'Reservation modified successfully';
          _isProcessing = false;
        });
        
        // Reload reservations
        await _loadUserReservations();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to modify reservation';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error modifying reservation: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<bool> _showCancellationDialog(ReservationRecord reservation) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this reservation?'),
            const SizedBox(height: 16),
            Text('Time: ${DateFormat('MMM dd, yyyy - HH:mm').format(reservation.creneaux!)}'),
            Text('Price: ${reservation.prix} TND'),
            const SizedBox(height: 16),
            const Text(
              'Note: Cancellations must be made at least 2 hours before the meal time.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Reservation'),
          ),
          FFButtonWidget(
            onPressed: () => Navigator.of(context).pop(true),
            text: 'Cancel Reservation',
            options: FFButtonOptions(
              color: FlutterFlowTheme.of(context).error,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Readex Pro',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<TimeSlotRecord?> _showTimeSlotSelectionDialog() async {
    return await showDialog<TimeSlotRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select New Time Slot'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _availableTimeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _availableTimeSlots[index];
              final availableSpots = timeSlot.maxCapacity - timeSlot.currentReservations;
              
              return ListTile(
                title: Text(DateFormat('MMM dd, yyyy - HH:mm').format(timeSlot.startTime!)),
                subtitle: Text('Available: $availableSpots/${timeSlot.maxCapacity} - ${timeSlot.price} TND'),
                trailing: availableSpots > 0 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
                enabled: availableSpots > 0,
                onTap: availableSpots > 0 
                  ? () => Navigator.of(context).pop(timeSlot)
                  : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(ReservationRecord reservation, AppLocalizations l10n) {
    final now = DateTime.now();
    final hoursUntilMeal = reservation.creneaux?.difference(now).inHours ?? 0;
    final canModifyOrCancel = hoursUntilMeal >= 2 && 
                              reservation.creneaux!.isAfter(now) &&
                              (reservation.status == 'confirmed' || reservation.status == 'pending');

    return Card(
      margin: AppSpacing.marginMD.copyWith(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(reservation.creneaux!),
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status),
                    borderRadius: AppBorders.borderMD,
                  ),
                  child: Text(
                    l10n.translate('status_${reservation.status.toLowerCase()}'),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSM,
            Text(
              '${l10n.translate('time_label')}: ${DateFormat('HH:mm').format(reservation.creneaux!)}',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${l10n.translate('price_label')}: ${AppConfig.formatPrice(reservation.prix.toDouble())}',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (reservation.capacity > 1)
              Text(
                '${l10n.translate('capacity_label')}: ${reservation.capacity} ${l10n.translate('person_s')}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            AppSpacing.verticalMD,
            Text(
              '${l10n.translate('hours_until_meal')}: $hoursUntilMeal',
              style: AppTypography.bodySmall.copyWith(
                color: hoursUntilMeal < 2 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            if (canModifyOrCancel) ...[
              AppSpacing.verticalMD,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _isProcessing ? null : () => _modifyReservation(reservation),
                      text: l10n.translate('modify'),
                      icon: Icon(Icons.edit, size: AppIconSizes.sm),
                      options: FFButtonOptions(
                        color: AppColors.primary,
                        textStyle: AppTypography.buttonSmall.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.horizontalMD,
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _isProcessing ? null : () => _cancelReservation(reservation),
                      text: l10n.cancel,
                      icon: Icon(Icons.cancel, size: AppIconSizes.sm),
                      options: FFButtonOptions(
                        color: AppColors.error,
                        textStyle: AppTypography.buttonSmall.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              AppSpacing.verticalMD,
              Container(
                padding: AppSpacing.paddingSM,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppBorders.borderMD,
                ),
                child: Text(
                  _getRestrictionMessage(reservation, hoursUntilMeal, l10n),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  String _getRestrictionMessage(ReservationRecord reservation, int hoursUntilMeal, AppLocalizations l10n) {
    if (reservation.status == 'cancelled') {
      return l10n.translate('reservation_cancelled_status');
    }
    if (reservation.status == 'used') {
      return l10n.translate('reservation_used_status');
    }
    if (reservation.creneaux!.isBefore(DateTime.now())) {
      return l10n.translate('past_reservations_message');
    }
    if (hoursUntilMeal < 2) {
      return l10n.translate('two_hour_restriction');
    }
    return l10n.translate('modification_not_available');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          l10n.translate('my_reservations'),
          style: AppTypography.h4.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: _isLoading ? null : _loadUserReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingMD,
              color: AppColors.errorLight.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error),
                  AppSpacing.horizontalSM,
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.error),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingMD,
              color: AppColors.successLight.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  AppSpacing.horizontalSM,
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.success),
                    onPressed: () => setState(() => _successMessage = null),
                  ),
                ],
              ),
            ),
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingMD,
              color: AppColors.infoLight.withValues(alpha: 0.1),
              child: Row(
                children: [
                  SizedBox(
                    width: AppIconSizes.md,
                    height: AppIconSizes.md,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  AppSpacing.horizontalMD,
                  Text(
                    'Processing...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _userReservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: AppIconSizes.xxxl,
                              color: AppColors.textTertiary,
                            ),
                            AppSpacing.verticalMD,
                            Text(
                              l10n.translate('no_upcoming_reservations'),
                              style: AppTypography.h5.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.verticalSM,
                            Text(
                              l10n.translate('make_reservation_prompt'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _userReservations.length,
                        itemBuilder: (context, index) {
                          return _buildReservationCard(_userReservations[index], l10n);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}