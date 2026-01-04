import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/widgets/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'staff_home_model.dart';
export 'staff_home_model.dart';

/// Staff home page for the ISET Restaurant system
/// Shows staff dashboard with menu management, QR scanning, and daily statistics
class StaffHomeWidget extends StatefulWidget {
  const StaffHomeWidget({super.key});

  static String routeName = 'StaffHome';
  static String routePath = '/staffHome';

  @override
  State<StaffHomeWidget> createState() => _StaffHomeWidgetState();
}

class _StaffHomeWidgetState extends State<StaffHomeWidget> {
  late StaffHomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StaffHomeModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        final user = appState.currentUser;
        
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Color(0xFF1C1284),
              automaticallyImplyLeading: false,
              title: Text(
                'ISET Restaurant - Personnel',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                  child: FlutterFlowIconButton(
                    borderRadius: 20.0,
                    buttonSize: 40.0,
                    fillColor: Colors.transparent,
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    onPressed: () => LogoutDialog.handleLogout(context),
                  ),
                ),
              ],
              centerTitle: false,
              elevation: 2.0,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.0),
                      
                      // Welcome message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Color(0xFFE9ECEF),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null 
                                  ? 'Bonjour, ${user.nom.isNotEmpty ? user.nom : user.displayName}'
                                  : 'Bonjour, Personnel',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Color(0xFF1C1284),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Tableau de bord du personnel ISET Restaurant',
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30.0),
                      
                      // Main action buttons
                      Text(
                        'Actions Principales',
                        style: FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: Color(0xFF1C1284),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      
                      SizedBox(height: 20.0),
                      
                      // Manage Menus Button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            context.pushNamed('DailyMenuManagement');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1C1284),
                            foregroundColor: Colors.white,
                            elevation: 4.0,
                            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                                size: 28.0,
                              ),
                              SizedBox(width: 12.0),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Gérer les Menus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Menus de la semaine',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // QR Scanner Button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            context.pushNamed('QRScanner');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00A4E4),
                            foregroundColor: Colors.white,
                            elevation: 4.0,
                            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 28.0,
                              ),
                              SizedBox(width: 12.0),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Scanner QR Code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Valider les réservations',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30.0),
                      
                      // Statistics Section
                      Text(
                        'Statistiques du Jour',
                        style: FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter Tight',
                              color: Color(0xFF1C1284),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      
                      SizedBox(height: 20.0),
                      
                      // Stats Cards Row
                      StreamBuilder<List<ReservationRecord>>(
                        stream: queryReservationRecord(
                          queryBuilder: (query) {
                            final now = DateTime.now();
                            final startOfDay = DateTime(now.year, now.month, now.day);
                            final endOfDay = startOfDay.add(Duration(days: 1));
                            return query
                                .where('creneaux', isGreaterThanOrEqualTo: startOfDay)
                                .where('creneaux', isLessThan: endOfDay)
                                .where('status', whereIn: ['confirmed', 'used']);
                          },
                        ),
                        builder: (context, reservationSnapshot) {
                          final todayReservations = reservationSnapshot.data?.length ?? 0;
                          final usedTickets = reservationSnapshot.data?.where((r) => r.status == 'used').length ?? 0;
                          
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF052753), Color(0xFF1E46E4)],
                                      stops: [0.0, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.qr_code_2,
                                        color: Colors.white,
                                        size: 32.0,
                                      ),
                                      SizedBox(height: 12.0),
                                      Text(
                                        '$usedTickets',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              fontFamily: 'Inter Tight',
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Tickets Scannés',
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Inter',
                                              color: Colors.white70,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: Color(0xFF00A4E4),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        color: Color(0xFF00A4E4),
                                        size: 32.0,
                                      ),
                                      SizedBox(height: 12.0),
                                      Text(
                                        '$todayReservations',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              fontFamily: 'Inter Tight',
                                              color: Color(0xFF00A4E4),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Réservations Jour',
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Inter',
                                              color: Color(0xFF00A4E4),
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      SizedBox(height: 40.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}