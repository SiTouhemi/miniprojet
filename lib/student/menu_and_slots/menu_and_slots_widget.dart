import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/services/time_slot_service.dart';
import '/components/menu_display_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';

class MenuAndSlotsWidget extends StatefulWidget {
  const MenuAndSlotsWidget({Key? key}) : super(key: key);

  static const String routeName = 'MenuAndSlots';
  static const String routePath = '/menu-and-slots';

  @override
  State<MenuAndSlotsWidget> createState() => _MenuAndSlotsWidgetState();
}

class _MenuAndSlotsWidgetState extends State<MenuAndSlotsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  String selectedMealType = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FFAppState>().loadTimeSlots(selectedDate);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Menu & Available Slots',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 22.0,
              ),
        ),
        centerTitle: false,
        elevation: 2.0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.restaurant_menu),
              text: 'Menu',
            ),
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Time Slots',
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // Date and filter selector
            _buildDateAndFilterSelector(),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Menu tab
                  MenuDisplayWidget(
                    selectedDate: selectedDate,
                    mealTypeFilter: selectedMealType,
                    showPrices: true,
                    onRefresh: () {
                      context.read<FFAppState>().refreshMenu();
                    },
                  ),
                  
                  // Time slots tab
                  _buildTimeSlotsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndFilterSelector() {
    return Container(
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
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          children: [
            // Date selector
            Row(
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
            
            SizedBox(height: 12.0),
            
            // Meal type filter (only show on menu tab)
            if (_tabController.index == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meal Type:',
                    style: FlutterFlowTheme.of(context).bodyLarge,
                  ),
                  DropdownButton<String>(
                    value: selectedMealType,
                    items: ['Tous', 'Breakfast', 'Lunch', 'Dinner']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedMealType = newValue;
                        });
                      }
                    },
                    style: FlutterFlowTheme.of(context).bodyMedium,
                    dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsTab() {
    return Consumer<FFAppState>(
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

        // Show error state if there's an error
        if (appState.lastError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.0,
                  color: Colors.red,
                ),
                SizedBox(height: 16.0),
                Text(
                  'Error Loading Time Slots',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                Text(
                  appState.lastError!,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                FFButtonWidget(
                  onPressed: () {
                    context.read<FFAppState>().loadTimeSlots(selectedDate);
                  },
                  text: 'Retry',
                  options: FFButtonOptions(
                    height: 40.0,
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: Colors.red,
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
                  'No Available Time Slots',
                  style: FlutterFlowTheme.of(context).headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                Text(
                  'No time slots available for ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
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
              return _buildTimeSlotCard(context, timeSlot, appState);
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotCard(BuildContext context, TimeSlotRecord timeSlot, FFAppState appState) {
    final availableSpots = timeSlot.maxCapacity - timeSlot.currentReservations;
    final occupancyRate = timeSlot.maxCapacity > 0 
        ? (timeSlot.currentReservations / timeSlot.maxCapacity) * 100 
        : 0.0;
    
    final isInPast = timeSlot.startTime?.isBefore(DateTime.now()) ?? false;
    final canReserve = !isInPast && availableSpots > 0;
    
    Color occupancyColor;
    if (occupancyRate < 60) {
      occupancyColor = Colors.green;
    } else if (occupancyRate < 80) {
      occupancyColor = Colors.orange;
    } else {
      occupancyColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time and meal type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('HH:mm').format(timeSlot.startTime!)} - ${DateFormat('HH:mm').format(timeSlot.endTime!)}',
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeSlot.mealType.toUpperCase(),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: isInPast ? Colors.grey : (canReserve ? Colors.green : Colors.red),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    isInPast ? 'PAST' : (canReserve ? 'AVAILABLE' : 'FULL'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.0),
            
            // Occupancy information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Occupancy',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      LinearProgressIndicator(
                        value: occupancyRate / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        '${timeSlot.currentReservations}/${timeSlot.maxCapacity} (${occupancyRate.toStringAsFixed(0)}%)',
                        style: FlutterFlowTheme.of(context).bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Price',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${timeSlot.price.toStringAsFixed(3)} TND',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (canReserve) ...[
              SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: FFButtonWidget(
                  onPressed: () {
                    // Navigate to reservation page
                    context.pushNamed(
                      'ReservationCreneau',
                      queryParameters: {
                        'timeSlotId': timeSlot.reference.id,
                      },
                    );
                  },
                  text: 'Reserve Now',
                  options: FFButtonOptions(
                    height: 44.0,
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    elevation: 2.0,
                    borderSide: BorderSide(
                      color: Colors.transparent,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}