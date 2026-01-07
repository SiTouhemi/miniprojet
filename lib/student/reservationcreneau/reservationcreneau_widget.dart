import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'reservationcreneau_model.dart';
export 'reservationcreneau_model.dart';

/// Updated reservation widget with time-based locking logic
/// Time slots become grey and locked when their time has passed
/// The next day they return to being available for reservation
/// Restaurant is closed on Sundays
class ReservationcreneauWidget extends StatefulWidget {
  const ReservationcreneauWidget({super.key});

  static String routeName = 'Reservationcreneau';
  static String routePath = '/reservationcreneau';

  @override
  State<ReservationcreneauWidget> createState() =>
      _ReservationcreneauWidgetState();
}

class _ReservationcreneauWidgetState extends State<ReservationcreneauWidget> {
  late ReservationcreneauModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReservationcreneauModel());

    // Set up state change callback
    _model.onStateChanged = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Check if a time slot is locked (past time or Sunday)
  /// Combines individual slot expiry check with meal period business rules
  bool _isTimeSlotLocked(TimeSlotRecord timeSlot) {
    final now = DateTime.now();
    
    // Check if it's Sunday (restaurant closed)
    if (now.weekday == DateTime.sunday) {
      return true;
    }
    
    // FIRST: Check if this specific time slot has already ended
    // This is the primary check - if the slot's end time has passed, it's locked
    if (timeSlot.endTime != null && timeSlot.endTime!.isBefore(now)) {
      return true;
    }
    
    // SECOND: Check meal period business rules for future slots
    // This prevents booking slots that are outside business hours
    if (timeSlot.mealType == 'lunch') {
      // Lunch slots available until dinner starts (17:40)
      final dinnerStartTime = DateTime(now.year, now.month, now.day, 17, 40);
      return now.isAfter(dinnerStartTime);
    } else if (timeSlot.mealType == 'dinner') {
      // Dinner slots available until end of day (23:59)
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
      return now.isAfter(endOfDay);
    }
    
    // Default: not locked
    return false;
  }

  /// Show reservation confirmation dialog with simple layout
  Future<bool> _showReservationConfirmationDialog(BuildContext context) async {
    if (_model.selectedTimeSlot == null) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Text(
              'Reservation Confirmation',
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                    ),
                    color: Color(0xFF005BAA),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation details:',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                        color: Color(0xFF005BAA),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 12.0),

                // Simple text layout instead of complex Rows
                Text(
                    'Date: ${DateFormat('dd MMMM yyyy').format(_model.selectedTimeSlot!.date!)}'),
                SizedBox(height: 4.0),
                Text(
                    'Heure: ${DateFormat('HH:mm').format(_model.selectedTimeSlot!.startTime!)} - ${DateFormat('HH:mm').format(_model.selectedTimeSlot!.endTime!)}'),
                SizedBox(height: 4.0),
                Text(
                    'Type: ${_model.selectedTimeSlot!.mealType.toUpperCase()}'),
                SizedBox(height: 4.0),
                Text(
                    'Prix: ${_model.selectedTimeSlot!.price.toStringAsFixed(2)} TND'),

                SizedBox(height: 16.0),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Le montant sera débité de votre compte D17. Cette action est irréversible.',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: Color(0xFF005BAA),
                          letterSpacing: 0.0,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF005BAA),
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                child: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 12.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFFF8FBFF),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF005BAA),
                    size: 20.0,
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Reservation',
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                          color: Color(0xFF005BAA),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'ISETCOM Restaurant',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                          ),
                          color: Color(0xFF666666),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              actions: [],
              centerTitle: true,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // User balance card
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8.0,
                              color: Color(0x1A000000),
                              offset: Offset(0.0, 2.0),
                            )
                          ],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Balance',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      color: Color(0xFF005BAA),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _model.isLoadingBalance
                                        ? 'Loading...'
                                        : '${_model.userBalance.toStringAsFixed(2)} DT',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          color: Color(0xFF005BAA),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF00A4E4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: 20.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ),
                      ),
                    ),

                    // Time slots section with locking logic
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 0.0, 20.0, 0.0),
                          child: Text(
                            'Choose a Time Slot',
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: Color(0xFF005BAA),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),

                        // Time slot cards with locking logic
                        StreamBuilder<List<TimeSlotRecord>>(
                          stream: queryTimeSlotRecord(
                            queryBuilder: (timeSlotRecord) {
                              final today = DateTime.now();
                              final startOfDay = DateTime(today.year, today.month, today.day);
                              final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
                              
                              return timeSlotRecord
                                  .where('is_active', isEqualTo: true)
                                  .where('date', isGreaterThanOrEqualTo: startOfDay)
                                  .where('date', isLessThanOrEqualTo: endOfDay)
                                  .orderBy('date')
                                  .orderBy('start_time')
                                  .limit(20);
                            },
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Error loading time slots',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${snapshot.error}',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting || _model.isGeneratingSlots) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF005BAA),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          _model.isGeneratingSlots 
                                              ? 'Generating time slots...'
                                              : 'Loading time slots...',
                                          style: TextStyle(
                                            color: Color(0xFF005BAA),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final allTimeSlots = snapshot.data ?? [];

                            if (allTimeSlots.isEmpty) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(24.0),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: Color(0xFFFFB74D),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 48,
                                        color: Color(0xFFFF8F00),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No Time Slots Available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Time slots need to be created by an administrator.\n\nLunch: 11:40 - 14:00\nDinner: 17:40 - 18:40',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFBF360C),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: allTimeSlots.map((timeSlot) {
                                final startTime = timeSlot.startTime!;
                                final endTime = timeSlot.endTime!;
                                final availableSpots = timeSlot.maxCapacity -
                                    timeSlot.currentReservations;
                                final isSelected =
                                    _model.selectedTimeSlot?.reference ==
                                        timeSlot.reference;

                                // Check if time slot is locked (past time or Sunday)
                                final isLocked = _isTimeSlotLocked(timeSlot);
                                final isSunday = timeSlot.date?.weekday == DateTime.sunday;
                                
                                // Determine if slot is selectable
                                final isSelectable = !isLocked && !isSunday && availableSpots > 0;

                                return Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 8.0),
                                  child: IgnorePointer(
                                    ignoring: !isSelectable,
                                    child: InkWell(
                                      onTap: isSelectable
                                          ? () {
                                              if (mounted) {
                                                setState(() {
                                                  _model.selectedTimeSlot =
                                                      timeSlot;
                                                  _model.clearMessages();
                                                });
                                              }
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Container(
                                        width: double.infinity,
                                        constraints: BoxConstraints(
                                          minHeight: 80.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLocked || isSunday
                                              ? Color(0xFFF5F5F5) // Grey for locked slots
                                              : availableSpots > 0
                                                  ? Colors.white
                                                  : Color(0xFFF5F5F5),
                                          boxShadow: isSelectable
                                              ? [
                                                  BoxShadow(
                                                    blurRadius: 4.0,
                                                    color: isSelected
                                                        ? Color(0x1A00A4E4)
                                                        : Color(0x1A000000),
                                                    offset: Offset(0.0, 1.0),
                                                  )
                                                ]
                                              : [],
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: isLocked || isSunday
                                                ? Color(0xFFBDBDBD) // Grey border for locked
                                                : availableSpots == 0
                                                    ? Color(0xFFE74C3C)
                                                    : isSelected
                                                        ? Color(0xFF00A4E4)
                                                        : Color(0xFFE0E0E0),
                                            width: (isLocked || isSunday || availableSpots == 0 || isSelected)
                                                ? 2.0
                                                : 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Container(
                                                    width: 36.0,
                                                    height: 36.0,
                                                    decoration: BoxDecoration(
                                                      color: isLocked || isSunday
                                                          ? Color(0xFFBDBDBD) // Grey icon for locked
                                                          : isSelected
                                                              ? Color(0xFF00A4E4)
                                                              : Color(0xFF005BAA),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Icon(
                                                        isLocked || isSunday
                                                            ? Icons.lock // Lock icon for locked slots
                                                            : Icons.schedule,
                                                        color: Colors.white,
                                                        size: 18.0,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyLarge
                                                            .override(
                                                              font: GoogleFonts
                                                                  .inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              color: isLocked || isSunday
                                                                  ? Color(0xFF9E9E9E) // Grey text for locked
                                                                  : Color(0xFF005BAA),
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      Text(
                                                        isLocked
                                                            ? 'Expired'
                                                            : isSunday
                                                                ? 'Closed (Sunday)'
                                                                : availableSpots > 0
                                                                    ? '${availableSpots} places available'
                                                                    : 'Full',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              font: GoogleFonts
                                                                  .inter(),
                                                              color: isLocked || isSunday
                                                                  ? Color(0xFF9E9E9E) // Grey text for locked
                                                                  : availableSpots > 5
                                                                      ? Color(0xFF00A855)
                                                                      : availableSpots > 0
                                                                          ? Color(0xFFFF6B35)
                                                                          : Color(0xFFE74C3C),
                                                              fontSize: 12.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  (isLocked || isSunday || availableSpots == 0)
                                                                      ? FontWeight.bold
                                                                      : FontWeight.normal,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ].divide(SizedBox(width: 12.0)),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${timeSlot.price.toStringAsFixed(2)} TND',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          color: isLocked || isSunday
                                                              ? Color(0xFF9E9E9E) // Grey text for locked
                                                              : Color(0xFF005BAA),
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  if (isSelected && isSelectable)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8.0,
                                                              vertical: 2.0),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Color(0xFF00A4E4),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      child: Text(
                                                        'Selected',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              font: GoogleFonts
                                                                  .inter(),
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10.0,
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),

                    // Reserve button
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Error message
                          if (_model.errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              margin: EdgeInsets.only(bottom: 16.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade700, size: 20.0),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _model.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: Colors.red.shade700, size: 18.0),
                                    onPressed: () => _model.clearMessages(),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),

                          // Success message
                          if (_model.successMessage != null)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              margin: EdgeInsets.only(bottom: 16.0),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8.0),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green.shade700, size: 20.0),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _model.successMessage!,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Reserve button
                          FFButtonWidget(
                            onPressed: _model.selectedTimeSlot == null ||
                                    _model.isProcessingReservation ||
                                    _model.isLoadingBalance ||
                                    !_model.canAffordSelectedSlot()
                                ? null
                                : () async {
                                    // Show confirmation dialog
                                    final confirmed =
                                        await _showReservationConfirmationDialog(
                                            context);
                                    if (!confirmed) return;

                                    // Create reservation
                                    final result =
                                        await _model.createReservation();

                                    if (result['success']) {
                                      // Navigate to confirmation page
                                      context.pushNamed(
                                        'Reservationconfirme',
                                        queryParameters: {
                                          'reservationId':
                                              result['reservationId'],
                                          'paymentId': result['paymentId'],
                                        },
                                      );
                                    }
                                  },
                            text: _model.isProcessingReservation
                                ? 'Processing reservation...'
                                : _model.selectedTimeSlot == null
                                    ? 'Select a time slot'
                                    : !_model.canAffordSelectedSlot()
                                        ? 'Insufficient balance'
                                        : 'Reserve',
                            icon: _model.isProcessingReservation
                                ? SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56.0,
                              padding: EdgeInsets.all(8.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: _model.selectedTimeSlot == null ||
                                      _model.isProcessingReservation ||
                                      _model.isLoadingBalance ||
                                      !_model.canAffordSelectedSlot()
                                  ? Colors.grey.shade400
                                  : Color(0xFF005BAA),
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                              elevation: _model.selectedTimeSlot != null &&
                                      !_model.isProcessingReservation &&
                                      !_model.isLoadingBalance &&
                                      _model.canAffordSelectedSlot()
                                  ? 2.0
                                  : 0.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                      .divide(SizedBox(height: 24.0))
                      .addToStart(SizedBox(height: 16.0))
                      .addToEnd(SizedBox(height: 32.0)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}