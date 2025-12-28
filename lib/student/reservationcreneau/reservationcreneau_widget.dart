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

/// Design a clean, modern Reservation page for the “ISETCOM Restaurant
/// Reservation System.” Use a minimalist university-style UI with the
/// palette: primary #005BAA, accent #00A4E4, white background, rounded
/// corners, and soft shadows.
///
/// The screen should show the student’s current balance, followed by a
/// section titled “Choisir un Créneau.” Display available time slots as
/// rounded cards with time range, remaining seats, and a small icon. Selected
/// slot highlights in blue. Below, show the meal of the day with name,
/// ingredients, price, and availability badge. Add a full-width “Réserver”
/// button at the bottom. Include a confirmation popup summarizing: date,
/// slot, meal, and price. Layout must be mobile-first, intuitive, and
/// accessible. Avoid clutter and keep spacing generous. The design should
/// feel academic, calm, and trustworthy.
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

  /// Show reservation confirmation dialog
  Future<bool> _showReservationConfirmationDialog(BuildContext context) async {
    if (_model.selectedTimeSlot == null) return false;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: Color(0xFF005BAA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 20.0,
              ),
            ),
            SizedBox(width: 12.0),
            Text(
              'Confirmer la réservation',
              style: FlutterFlowTheme.of(context).titleLarge.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                ),
                color: Color(0xFF005BAA),
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de la réservation:',
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
            _buildConfirmationRow('Date:', DateFormat('dd MMMM yyyy').format(_model.selectedTimeSlot!.date!)),
            _buildConfirmationRow('Heure:', '${DateFormat('HH:mm').format(_model.selectedTimeSlot!.startTime!)} - ${DateFormat('HH:mm').format(_model.selectedTimeSlot!.endTime!)}'),
            _buildConfirmationRow('Type:', _model.selectedTimeSlot!.mealType.toUpperCase()),
            _buildConfirmationRow('Prix:', '${_model.selectedTimeSlot!.price.toStringAsFixed(2)} TND'),
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
              'Annuler',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FFButtonWidget(
            onPressed: () => Navigator.of(context).pop(true),
            text: 'Confirmer',
            options: FFButtonOptions(
              height: 40.0,
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
              color: Color(0xFF005BAA),
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                ),
                color: Colors.white,
                letterSpacing: 0.0,
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
        ],
      ),
    ) ?? false;
  }

  /// Build confirmation dialog row
  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(),
              color: Colors.grey.shade600,
              letterSpacing: 0.0,
            ),
          ),
          Text(
            value,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
              color: Color(0xFF005BAA),
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
                    context.pop();
                  },
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Réservation',
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                            fontStyle:
                                FlutterFlowTheme.of(context).titleLarge.fontStyle,
                          ),
                          color: Color(0xFF005BAA),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleLarge.fontStyle,
                        ),
                  ),
                  Text(
                    'ISETCOM Restaurant',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontStyle:
                                FlutterFlowTheme.of(context).bodySmall.fontStyle,
                          ),
                          color: Color(0xFF666666),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
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
                      padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
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
                                'Solde Actuel',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF005BAA),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _model.isLoadingBalance
                                        ? 'Chargement...'
                                        : '${_model.userBalance.toStringAsFixed(2)} DT',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          font: GoogleFonts.interTight(
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FlutterFlowTheme.of(context)
                                                .headlineMedium
                                                .fontStyle,
                                          ),
                                          color: Color(0xFF005BAA),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .headlineMedium
                                              .fontStyle,
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
                    
                    // Time slots section
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 4.0, 0.0),
                          child: Text(
                            'Choisir un Créneau',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF005BAA),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                          ),
                        ),
                        
                        // Time slot cards - Dynamic from database
                        StreamBuilder<List<TimeSlotRecord>>(
                          stream: queryTimeSlotRecord(
                            queryBuilder: (timeSlotRecord) => timeSlotRecord
                                .where('date', isGreaterThanOrEqualTo: DateTime.now().subtract(Duration(days: 1)))
                                .where('is_active', isEqualTo: true)
                                .orderBy('date')
                                .orderBy('start_time')
                                .limit(10),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Erreur lors du chargement des créneaux',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              );
                            }
                            
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF005BAA),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            final timeSlots = snapshot.data ?? [];
                            
                            if (timeSlots.isEmpty) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Aucun créneau disponible pour le moment',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                              );
                            }
                            
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: timeSlots.map((timeSlot) {
                                final startTime = timeSlot.startTime!;
                                final endTime = timeSlot.endTime!;
                                final availableSpots = timeSlot.maxCapacity - timeSlot.currentReservations;
                                final isSelected = _model.selectedTimeSlot?.reference == timeSlot.reference;
                                
                                return Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _model.selectedTimeSlot = timeSlot;
                                        _model.clearMessages();
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 4.0,
                                            color: isSelected ? Color(0x1A00A4E4) : Color(0x1A000000),
                                            offset: Offset(0.0, 1.0),
                                          )
                                        ],
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: isSelected ? Color(0xFF00A4E4) : Color(0xFFE0E0E0),
                                          width: isSelected ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  width: 36.0,
                                                  height: 36.0,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? Color(0xFF00A4E4) : Color(0xFF005BAA),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0.0, 0.0),
                                                    child: Icon(
                                                      Icons.schedule,
                                                      color: Colors.white,
                                                      size: 18.0,
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisSize: MainAxisSize.max,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                            font: GoogleFonts.inter(
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            color: Color(0xFF005BAA),
                                                            fontSize: 16.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                    ),
                                                    Text(
                                                      '${availableSpots} places disponibles',
                                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                                            font: GoogleFonts.inter(),
                                                            color: availableSpots > 5 ? Color(0xFF00A855) : Color(0xFFFF6B35),
                                                            fontSize: 12.0,
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ].divide(SizedBox(width: 12.0)),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${timeSlot.price.toStringAsFixed(2)} TND',
                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        color: Color(0xFF005BAA),
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                if (isSelected)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF00A4E4),
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                    child: Text(
                                                      'Sélectionné',
                                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                                            font: GoogleFonts.inter(),
                                                            color: Colors.white,
                                                            fontSize: 10.0,
                                                            letterSpacing: 0.0,
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
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                    
                    // Daily menu section with real data
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                          child: Text(
                            'Plat du Jour',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: Color(0xFF005BAA),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        
                        // Stream builder for daily menu
                        StreamBuilder<List<DailyMenuRecord>>(
                          stream: queryDailyMenuRecord(
                            queryBuilder: (dailyMenuRecord) => dailyMenuRecord
                                .where('date', isGreaterThanOrEqualTo: DateTime.now().subtract(Duration(days: 1)))
                                .where('available', isEqualTo: true)
                                .orderBy('date')
                                .limit(1),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Erreur lors du chargement du menu',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              );
                            }
                            
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                                child: Container(
                                  height: 150.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF005BAA),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            final menus = snapshot.data ?? [];
                            
                            if (menus.isEmpty) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Aucun menu disponible pour aujourd\'hui',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                              );
                            }
                            
                            final menu = menus.first;
                            
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6.0,
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
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  menu.mainDish,
                                                  style: FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .override(
                                                        font: GoogleFonts.interTight(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        color: Color(0xFF005BAA),
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                  child: Text(
                                                    menu.accompaniments.isNotEmpty 
                                                        ? menu.accompaniments.join(', ')
                                                        : menu.description,
                                                    style: FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          color: Color(0xFF666666),
                                                          letterSpacing: 0.0,
                                                          lineHeight: 1.4,
                                                        ),
                                                  ),
                                                ),
                                                if (menu.description.isNotEmpty && menu.accompaniments.isNotEmpty)
                                                  Padding(
                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                                                    child: Text(
                                                      menu.description,
                                                      style: FlutterFlowTheme.of(context)
                                                          .bodySmall
                                                          .override(
                                                            color: Color(0xFF888888),
                                                            letterSpacing: 0.0,
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 12.0, 6.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: menu.available ? Colors.green : Colors.red,
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  menu.available ? 'Disponible' : 'Indisponible',
                                                  style: FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Icon(
                                                Icons.restaurant,
                                                color: Color(0xFF00A4E4),
                                                size: 20.0,
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                '${menu.price.toStringAsFixed(2)} DT',
                                                style: FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .override(
                                                      color: Color(0xFF005BAA),
                                                      letterSpacing: 0.0,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: 32.0,
                                            height: 32.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF0F8FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Align(
                                              alignment: AlignmentDirectional(0.0, 0.0),
                                              child: Icon(
                                                Icons.info_outline,
                                                color: Color(0xFF00A4E4),
                                                size: 16.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(height: 12.0)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                    
                    // Reserve button
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
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
                                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20.0),
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
                                        icon: Icon(Icons.close, color: Colors.red.shade700, size: 18.0),
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
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20.0),
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
                              
                              // Balance and validation info
                              if (_model.selectedTimeSlot != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12.0),
                                  margin: EdgeInsets.only(bottom: 16.0),
                                  decoration: BoxDecoration(
                                    color: _model.canAffordSelectedSlot() 
                                        ? Colors.green.shade50 
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: _model.canAffordSelectedSlot() 
                                          ? Colors.green.shade200 
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Prix du créneau:',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                          Text(
                                            '${_model.selectedTimeSlot!.price.toStringAsFixed(2)} TND',
                                            style: TextStyle(
                                              color: Color(0xFF005BAA),
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.0),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Votre solde:',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                          Text(
                                            _model.isLoadingBalance 
                                                ? 'Chargement...'
                                                : '${_model.userBalance.toStringAsFixed(2)} TND',
                                            style: TextStyle(
                                              color: _model.canAffordSelectedSlot() 
                                                  ? Colors.green.shade700 
                                                  : Colors.orange.shade700,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!_model.canAffordSelectedSlot() && !_model.isLoadingBalance) ...[
                                        SizedBox(height: 8.0),
                                        Text(
                                          'Solde insuffisant pour cette réservation',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
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
                                        final confirmed = await _showReservationConfirmationDialog(context);
                                        if (!confirmed) return;
                                        
                                        // Create reservation
                                        final result = await _model.createReservation();
                                        
                                        if (result['success']) {
                                          // Navigate to confirmation page
                                          context.pushNamed(
                                            'Reservationconfirme',
                                            queryParameters: {
                                              'reservationId': result['reservationId'],
                                              'paymentId': result['paymentId'],
                                            },
                                          );
                                        }
                                      },
                                text: _model.isProcessingReservation
                                    ? 'Réservation en cours...'
                                    : _model.selectedTimeSlot == null
                                        ? 'Sélectionnez un créneau'
                                        : !_model.canAffordSelectedSlot()
                                            ? 'Solde insuffisant'
                                            : 'Réserver',
                                icon: _model.isProcessingReservation
                                    ? SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                  color: _model.selectedTimeSlot == null || 
                                         _model.isProcessingReservation ||
                                         _model.isLoadingBalance ||
                                         !_model.canAffordSelectedSlot()
                                      ? Colors.grey.shade400
                                      : Color(0xFF005BAA),
                                  textStyle: FlutterFlowTheme.of(context).titleMedium.override(
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
                                            _model.canAffordSelectedSlot() ? 2.0 : 0.0,
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
