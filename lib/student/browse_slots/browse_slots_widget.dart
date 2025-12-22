import '/backend/backend.dart';
import '/backend/services/app_service.dart';
import '/backend/services/time_slot_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/app_state.dart';

class BrowseSlotsWidget extends StatefulWidget {
  const BrowseSlotsWidget({super.key});

  static const String routeName = 'BrowseSlots';
  static const String routePath = '/browse-slots';

  @override
  State<BrowseSlotsWidget> createState() => _BrowseSlotsWidgetState();
}

class _BrowseSlotsWidgetState extends State<BrowseSlotsWidget> {
  DateTime selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FFAppState>().loadTimeSlots(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Available Time Slots',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 22.0,
              ),
        ),
        centerTitle: false,
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Date Selector
            Container(
              width: double.infinity,
              height: 80.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3.0,
                    color: Color(0x33000000),
                    offset: Offset(0.0, 1.0),
                  )
                ],
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Date:',
                      style: FlutterFlowTheme.of(context).bodyLarge,
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 30)),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                          context.read<FFAppState>().loadTimeSlots(selectedDate);
                        }
                      },
                      text: DateFormat('MMM dd, yyyy').format(selectedDate),
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Readex Pro',
                              color: Colors.white,
                            ),
                        elevation: 2.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Time Slots List
            Expanded(
              child: Consumer<FFAppState>(
                builder: (context, appState, _) {
                  if (appState.isLoadingTimeSlots) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    );
                  }

                  if (appState.availableTimeSlots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64.0,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'No available time slots for this date',
                            style: FlutterFlowTheme.of(context).headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Please select a different date or check back later',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.0),
                          FFButtonWidget(
                            onPressed: () {
                              context.read<FFAppState>().refreshTimeSlots();
                            },
                            text: 'Refresh',
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Readex Pro',
                                    color: Colors.white,
                                  ),
                              elevation: 2.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<FFAppState>().loadTimeSlots(selectedDate);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: appState.availableTimeSlots.length,
                      itemBuilder: (context, index) {
                        final timeSlot = appState.availableTimeSlots[index];
                        final availableSpots = timeSlot.maxCapacity - timeSlot.currentReservations;
                        final occupancyRate = timeSlot.maxCapacity > 0 
                            ? (timeSlot.currentReservations / timeSlot.maxCapacity) * 100 
                            : 0.0;
                        
                        // Requirement 4.7: Prevent reservations for time slots in the past
                        final isInPast = TimeSlotService.instance.isTimeSlotInPast(timeSlot);
                        final canReserve = !isInPast && availableSpots > 0 && appState.canMakeMoreReservations();
                        
                        return Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 3.0,
                                  color: Color(0x33000000),
                                  offset: Offset(0.0, 1.0),
                                )
                              ],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isInPast
                                    ? FlutterFlowTheme.of(context).secondaryText
                                    : occupancyRate > 80 
                                        ? FlutterFlowTheme.of(context).error
                                        : FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${DateFormat('HH:mm').format(timeSlot.startTime!)} - ${DateFormat('HH:mm').format(timeSlot.endTime!)}',
                                            style: FlutterFlowTheme.of(context).headlineSmall,
                                          ),
                                          Text(
                                            timeSlot.mealType.toUpperCase(),
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'Readex Pro',
                                              color: FlutterFlowTheme.of(context).primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${timeSlot.price.toStringAsFixed(2)} TND',
                                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                                              fontFamily: 'Outfit',
                                              color: FlutterFlowTheme.of(context).primary,
                                            ),
                                          ),
                                          Text(
                                            '$availableSpots spots left',
                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                              fontFamily: 'Readex Pro',
                                              color: isInPast
                                                  ? FlutterFlowTheme.of(context).secondaryText
                                                  : availableSpots < 5 
                                                      ? FlutterFlowTheme.of(context).error
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                            ),
                                          ),
                                          if (isInPast)
                                            Text(
                                              'Past',
                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'Readex Pro',
                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12.0),
                                  
                                  // Occupancy Bar
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Occupancy: ${occupancyRate.toStringAsFixed(0)}%',
                                        style: FlutterFlowTheme.of(context).bodySmall,
                                      ),
                                      SizedBox(height: 4.0),
                                      LinearProgressIndicator(
                                        value: occupancyRate / 100,
                                        backgroundColor: FlutterFlowTheme.of(context).alternate,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          occupancyRate > 80 
                                              ? FlutterFlowTheme.of(context).error
                                              : occupancyRate > 60
                                                  ? FlutterFlowTheme.of(context).warning
                                                  : FlutterFlowTheme.of(context).success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16.0),
                                  
                                  // Reserve Button
                                  FFButtonWidget(
                                    onPressed: canReserve
                                        ? () async {
                                            // Validate time slot before navigation
                                            final validation = await TimeSlotService.instance
                                                .validateTimeSlotForReservation(timeSlot.reference.id);
                                            
                                            if (validation.isValid) {
                                              context.pushNamed(
                                                'ReservationConfirm',
                                                queryParameters: {
                                                  'timeSlotId': timeSlot.reference.id,
                                                  'selectedDate': selectedDate.millisecondsSinceEpoch.toString(),
                                                },
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(validation.errorMessage ?? 'Cannot reserve this time slot'),
                                                  backgroundColor: FlutterFlowTheme.of(context).error,
                                                ),
                                              );
                                              // Refresh time slots to get latest data
                                              context.read<FFAppState>().refreshTimeSlots();
                                            }
                                          }
                                        : null,
                                    text: isInPast
                                        ? 'Past Time Slot'
                                        : availableSpots <= 0 
                                            ? 'Fully Booked'
                                            : !appState.canMakeMoreReservations()
                                                ? 'Max Reservations Reached'
                                                : 'Reserve Now',
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 44.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                      iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                      color: canReserve
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context).secondaryText,
                                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                            fontFamily: 'Readex Pro',
                                            color: Colors.white,
                                          ),
                                      elevation: canReserve ? 2.0 : 0.0,
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}