import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/backend/services/time_slot_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';

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

  Widget _buildReservationCard(ReservationRecord reservation) {
    final now = DateTime.now();
    final hoursUntilMeal = reservation.creneaux?.difference(now).inHours ?? 0;
    final canModifyOrCancel = hoursUntilMeal >= 2 && 
                              reservation.creneaux!.isAfter(now) &&
                              (reservation.status == 'confirmed' || reservation.status == 'pending');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(reservation.creneaux!),
                  style: FlutterFlowTheme.of(context).headlineSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('HH:mm').format(reservation.creneaux!)}',
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
            Text(
              'Price: ${reservation.prix} TND',
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
            if (reservation.capacity > 1)
              Text(
                'Capacity: ${reservation.capacity} person(s)',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
            const SizedBox(height: 12),
            Text(
              'Hours until meal: $hoursUntilMeal',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Readex Pro',
                color: hoursUntilMeal < 2 ? Colors.red : Colors.grey,
              ),
            ),
            if (canModifyOrCancel) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _isProcessing ? null : () => _modifyReservation(reservation),
                      text: 'Modify',
                      icon: const Icon(Icons.edit, size: 16),
                      options: FFButtonOptions(
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _isProcessing ? null : () => _cancelReservation(reservation),
                      text: 'Cancel',
                      icon: const Icon(Icons.cancel, size: 16),
                      options: FFButtonOptions(
                        color: FlutterFlowTheme.of(context).error,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRestrictionMessage(reservation, hoursUntilMeal),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Readex Pro',
                    color: Colors.grey[600],
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

  String _getRestrictionMessage(ReservationRecord reservation, int hoursUntilMeal) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          'My Reservations',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            fontFamily: 'Outfit',
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadUserReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green[100],
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.green),
                    onPressed: () => setState(() => _successMessage = null),
                  ),
                ],
              ),
            ),
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[100],
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
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
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming reservations',
                              style: FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Outfit',
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Make a reservation to see it here',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Readex Pro',
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _userReservations.length,
                        itemBuilder: (context, index) {
                          return _buildReservationCard(_userReservations[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}