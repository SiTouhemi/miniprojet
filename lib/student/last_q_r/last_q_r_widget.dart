import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '/flutter_flow/app_state.dart';
import '/backend/backend.dart';

import 'last_q_r_model.dart';
export 'last_q_r_model.dart';

class LastQRWidget extends StatefulWidget {
  const LastQRWidget({super.key});

  static String routeName = 'LastQR';
  static String routePath = '/lastQR';

  @override
  State<LastQRWidget> createState() => _LastQRWidgetState();
}

class _LastQRWidgetState extends State<LastQRWidget> {
  late LastQRModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LastQRModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Color(0xFF005BAA),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  'https://images.unsplash.com/photo-1753579427708-a4ef31aeb8b6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjMyMTEzMTF8&ixlib=rb-4.1.0&q=80&w=1080',
                  width: 32.0,
                  height: 32.0,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ISETCOM Restaurant',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Système de Réservation',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: Color(0xCCFFFFFF),
                          fontSize: 12.0,
                        ),
                  ),
                ],
              ),
            ].divide(SizedBox(width: 12.0)),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Consumer<FFAppState>(
            builder: (context, appState, child) {
              final now = DateTime.now();
              final reservations = appState.userReservations.toList();
              ReservationRecord? activeReservation;
              
              try {
                // Find upcoming confirmed reservations (or active for today)
                // Filter: Status confirmed, Date >= Today (00:00)
                // Actually, let's just show the latest confirmed one that hasn't passed more than a day.
                final upcoming = reservations.where((r) {
                  final rDate = r.creneaux ?? DateTime.fromMillisecondsSinceEpoch(0);
                  // Allow showing tickets for today even if time passed slightly, or future.
                  // Cutoff: Yesterday.
                  final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
                  return r.status == 'confirmed' && rDate.isAfter(cutoff);
                }).toList();
                
                // Sort by date ascending (nearest first) to show the immediate next meal
                upcoming.sort((a, b) => (a.creneaux ?? DateTime(0)).compareTo(b.creneaux ?? DateTime(0)));
                
                if (upcoming.isNotEmpty) {
                  // Pick the first one (earliest upcoming)
                  activeReservation = upcoming.first;
                }
              } catch (e) {
                AppLogger.e('Error finding active reservation: $e');
              }

              if (activeReservation == null) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                       SizedBox(height: 16),
                       Text(
                         'Aucune réservation active',
                         textAlign: TextAlign.center,
                         style: FlutterFlowTheme.of(context).headlineMedium.override(
                           font: GoogleFonts.interTight(),
                           color: Color(0xFF2C3E50),
                           fontSize: 22,
                         ),
                       ),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                         child: Text(
                           'Réservez un repas pour voir votre QR code ici.\nLes anciens tickets sont dans l\'historique.',
                           textAlign: TextAlign.center,
                           style: FlutterFlowTheme.of(context).bodyMedium.override(
                             font: GoogleFonts.inter(),
                             color: Color(0xFF7F8C8D),
                           ),
                         ),
                       ),
                       SizedBox(height: 24),
                       FFButtonWidget(
                          onPressed: () async {
                              // Refresh logic
                              await FFAppState().loadUserReservations();
                          },
                          text: 'Actualiser',
                          options: FFButtonOptions(
                            width: 140,
                            height: 40,
                            color: Color(0xFF005BAA),
                            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.inter(),
                                  color: Colors.white,
                                ),
                            elevation: 2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                     ],
                   ),
                 );
              }

              final date = activeReservation.creneaux ?? DateTime.now();
              // Infer meal type from hour if not present. 
              // Usually lunch is 11-14, Dinner 18-21.
              final isLunch = date.hour < 15;
              final mealType = isLunch ? 'Déjeuner' : 'Dîner';
              final price = activeReservation.prix; // double
              final qrData = activeReservation.qrCode ?? 'INVALID_QR';
              // Check if it's "today"
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final dateString = isToday ? 'Aujourd\'hui' : DateFormat('d MMMM y', 'fr_FR').format(date);

              return Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Réservation Active',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        color: Color(0xFF005BAA),
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 4.0, 0.0, 0.0),
                                  child: Text(
                                    'Restaurant Universitaire ISETCOM',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 14.0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            FlutterFlowIconButton(
                              borderRadius: 22.0,
                              buttonSize: 44.0,
                              fillColor: Color(0xFF005BAA),
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              onPressed: () async {
                                final now = DateTime.now();
                                await FFAppState().loadUserReservations();
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(24.0),
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
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Menu Étudiant',
                                                style: FlutterFlowTheme.of(context)
                                                    .titleLarge
                                                    .override(
                                                      font: GoogleFonts.interTight(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                      fontSize: 18.0,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional.fromSTEB(
                                                        0.0, 4.0, 0.0, 0.0),
                                                child: Text(
                                                  '$mealType + Dessert',
                                                  style:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts.inter(),
                                                            color:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                            fontSize: 14.0,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 80.0,
                                          height: 32.0,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                'Valide',
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      color: Colors.white,
                                                      fontSize: 12.0,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today_rounded,
                                                    color: Color(0xFF005BAA),
                                                    size: 16.0,
                                                  ),
                                                  Text(
                                                    dateString,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primaryText,
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
                                              ),
                                              if (isToday) // Show full date below if "Aujourd'hui"
                                                Padding(
                                                  padding:
                                                      EdgeInsetsDirectional.fromSTEB(
                                                          24.0, 2.0, 24.0, 0.0),
                                                  child: Text(
                                                    DateFormat('d MMMM y', 'fr_FR').format(date),
                                                    style:
                                                        FlutterFlowTheme.of(context)
                                                            .bodySmall
                                                            .override(
                                                              font: GoogleFonts.inter(),
                                                              color:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                              fontSize: 12.0,
                                                            ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    color: Color(0xFF005BAA),
                                                    size: 16.0,
                                                  ),
                                                  Text(
                                                    DateFormat('HH:mm').format(date),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primaryText,
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional.fromSTEB(
                                                        24.0, 2.0, 24.0, 0.0),
                                                child: Text(
                                                  'Heure du repas',
                                                  style:
                                                      FlutterFlowTheme.of(context)
                                                          .bodySmall
                                                          .override(
                                                            font: GoogleFonts.inter(),
                                                            color:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                            fontSize: 12.0,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${price.toStringAsFixed(2)} DT',
                                              style: FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .override(
                                                    font: GoogleFonts.interTight(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    color: Color(0xFF005BAA),
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsetsDirectional.fromSTEB(
                                                      0.0, 2.0, 0.0, 0.0),
                                              child: Text(
                                                'Prix étudiant',
                                                style: FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(),
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryText,
                                                      fontSize: 12.0,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ].divide(SizedBox(width: 16.0)),
                                    ),
                                  ].divide(SizedBox(height: 16.0)),
                                ),
                                Divider(
                                  thickness: 1.0,
                                  color: Color(0xFFE0E0E0),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Code QR de Réservation',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Container(
                                      width: 200.0,
                                      height: 200.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: Color(0xFFE0E0E0),
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: AlignmentDirectional(0.0, 0.0),
                                        child: QrImageView(
                                          data: qrData,
                                          version: QrVersions.auto,
                                          size: 180.0,
                                          gapless: false,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF3F8FF),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                color: Color(0xFF005BAA),
                                                size: 16.0,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Présentez ce QR à l\'entrée du restaurant',
                                                  textAlign: TextAlign.center,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        color: Color(0xFF005BAA),
                                                        fontSize: 12.0,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 8.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 16.0)),
                                ),
                                Divider(
                                  thickness: 1.0,
                                  color: Color(0xFFE0E0E0),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Détails de la Réservation',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Numéro de réservation',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(),
                                                color: FlutterFlowTheme.of(context)
                                                    .secondaryText,
                                                fontSize: 13.0,
                                              ),
                                        ),
                                        Text(
                                          activeReservation.reference.id.substring(0, 8).toUpperCase(),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                color: FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                fontSize: 13.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ].divide(SizedBox(height: 12.0)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
