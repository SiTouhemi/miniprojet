import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
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
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: Text(
                'ISET Restaurant - Personnel',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter Tight',
                      color: Color(0xFF1C1284),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                  child: FlutterFlowIconButton(
                    borderRadius: 20.0,
                    buttonSize: 40.0,
                    fillColor: Colors.transparent,
                    icon: Icon(
                      Icons.notifications,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notifications bientôt disponibles!'),
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                  child: FlutterFlowIconButton(
                    borderRadius: 20.0,
                    buttonSize: 40.0,
                    fillColor: Colors.red.shade50,
                    icon: Icon(
                      Icons.logout,
                      color: Colors.red.shade600,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Déconnexion'),
                            content: Text('Êtes-vous sûr de vouloir vous déconnecter?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(
                                  'Déconnexion',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (shouldLogout == true) {
                        try {
                          await signOut();
                          if (context.mounted) {
                            context.goNamed('Login');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de la déconnexion: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),
                      
                      // Welcome message
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
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
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Tableau de bord du personnel',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
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
                          Container(
                            width: 100.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: Image.asset(
                                'assets/images/logo_iset_com.jpg',
                                width: 200.0,
                                height: 211.6,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 32.0),
                      
                      // Main action buttons
                      Text(
                        'Actions Principales',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Inter Tight',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      
                      SizedBox(height: 16.0),
                      
                      GridView(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2,
                        ),
                        primary: false,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: [
                          // Manage Menus card
                          InkWell(
                            onTap: () {
                              // TODO: Navigate to menu management page
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gestion des menus bientôt disponible'),
                                  backgroundColor: Color(0xFF1C1284),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x1A000000),
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0xFF1C1284),
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      color: Color(0xFF1C1284),
                                      size: 40.0,
                                    ),
                                    SizedBox(height: 12.0),
                                    Text(
                                      'Gérer Menus',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Color(0xFF1C1284),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      'Ajouter/Modifier menus',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
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
                            ),
                          ),
                          
                          // Scan QR codes card
                          InkWell(
                            onTap: () {
                              context.pushNamed('monjeya_scan');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x1A000000),
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0xFF00A4E4),
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      color: Color(0xFF00A4E4),
                                      size: 40.0,
                                    ),
                                    SizedBox(height: 12.0),
                                    Text(
                                      'Scanner QR',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Color(0xFF00A4E4),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      'Valider les réservations',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
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
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 32.0),
                      
                      // Daily statistics
                      Text(
                        'Statistiques du Jour',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Inter Tight',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      
                      SizedBox(height: 16.0),
                      
                      // Tickets scanned today card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF052753), Color(0xFF1E46E)],
                            stops: [0.0, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tickets Scannés Aujourd\'hui',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white70,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 8.0, 0.0, 0.0),
                                      child: Text(
                                        '0', // TODO: Get real count from database
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              fontFamily: 'Inter Tight',
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        'Réservations validées',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Inter',
                                              color: Colors.white70,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 60.0,
                                height: 60.0,
                                decoration: BoxDecoration(
                                  color: Color(0x33FFFFFF),
                                  shape: BoxShape.circle,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.qr_code_2,
                                    color: Colors.white,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24.0),
                      
                      // Additional stats row
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x1A000000),
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Color(0xFF00A4E4),
                                    size: 24.0,
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Créneaux Actifs',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Inter',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                  Text(
                                    '3', // TODO: Get real count
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color: Color(0xFF00A4E4),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x1A000000),
                                    offset: Offset(0.0, 2.0),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    color: Color(0xFF1C1284),
                                    size: 24.0,
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Menus Disponibles',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Inter',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                  Text(
                                    '7', // TODO: Get real count
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color: Color(0xFF1C1284),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 32.0),
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