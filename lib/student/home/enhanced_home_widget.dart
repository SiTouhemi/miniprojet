import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/error_handler.dart';
import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_model.dart';
export 'home_model.dart';

/// Enhanced home widget with improved error handling and user feedback
/// Implements requirements 2.6, 6.1, 6.2, 6.3, 6.4, 6.5 for error handling and user feedback
class EnhancedHomeWidget extends StatefulWidget {
  const EnhancedHomeWidget({super.key});

  static String routeName = 'enhanced_home';
  static String routePath = '/enhanced_home';

  @override
  State<EnhancedHomeWidget> createState() => _EnhancedHomeWidgetState();
}

class _EnhancedHomeWidgetState extends State<EnhancedHomeWidget> {
  late HomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ErrorHandler _errorHandler = ErrorHandler.instance;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());
    
    // Load user data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  Future<void> _initializeUserData() async {
    final appState = Provider.of<FFAppState>(context, listen: false);
    
    try {
      // Check if user is authenticated
      if (!authService.isLoggedIn) {
        // Redirect to login if not authenticated
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      
      // If user is already loaded in app state, no need to reload
      if (appState.currentUser != null) {
        setState(() {
          _isInitializing = false;
        });
        return;
      }
      
      // Load user data and initialize real-time sync
      final userDoc = await authService.getCurrentUserDocument();
      if (userDoc != null) {
        appState.setCurrentUser(userDoc);
        AppLogger.i('User data loaded: ${userDoc.nom} (${userDoc.pocket} DT)', tag: 'EnhancedHomeWidget');
      } else if (authService.isLoggedIn) {
        // User is logged in but document doesn't exist - this shouldn't happen
        AppLogger.w('User is authenticated but no user document found', tag: 'EnhancedHomeWidget');
        appState.setLastError('Données utilisateur introuvables. Veuillez vous reconnecter.');
      }
    } catch (e) {
      AppLogger.e('Error loading current user', error: e, tag: 'EnhancedHomeWidget');
      final errorMessage = _errorHandler.handleError(e, context: 'user_data');
      appState.setLastError(errorMessage);
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final appState = Provider.of<FFAppState>(context, listen: false);
    
    try {
      await appState.refreshAll();
      _errorHandler.showError(
        context,
        'Données actualisées avec succès',
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'refresh',
        onRetry: _handleRefresh,
      );
    }
  }

  void _handleQRCodeAccess(FFAppState appState) {
    try {
      final upcomingReservations = appState.getUpcomingReservations();
      if (upcomingReservations.isNotEmpty) {
        context.pushNamed('lastQR');
      } else {
        _errorHandler.showError(
          context,
          'Aucune réservation confirmée trouvée',
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'qr_access',
      );
    }
  }

  void _handleReservationAccess() {
    try {
      context.pushNamed('Reservationcreneau');
    } catch (e) {
      _errorHandler.showError(
        context,
        e,
        contextInfo: 'reservation_access',
      );
    }
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
                'ISET Restaurant',
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
                      // Show confirmation dialog
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
              child: Column(
                children: [
                  // Enhanced error message display
                  if (appState.lastError != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      color: Colors.red.shade600,
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 16.0,
                          ),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              appState.lastError!,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: _handleRefresh,
                            child: Text(
                              'Réessayer',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Enhanced offline indicator
                  _errorHandler.buildOfflineIndicator(isOffline: !appState.isOnline),

                  // Main content with enhanced loading and error handling
                  Expanded(
                    child: _errorHandler.buildLoadingWithError(
                      isLoading: _isInitializing,
                      error: _isInitializing ? null : (user == null ? 'Impossible de charger les données utilisateur' : null),
                      onRetry: _initializeUserData,
                      loadingMessage: 'Chargement des données utilisateur...',
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.0),
                                
                                // User greeting with enhanced data validation
                                _buildUserGreeting(user),
                                
                                SizedBox(height: 24.0),
                                
                                // Balance card with real-time data and validation
                                _buildBalanceCard(user),
                                
                                SizedBox(height: 24.0),
                                
                                Text(
                                  'Actions Rapides',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'Inter Tight',
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                
                                SizedBox(height: 16.0),
                                
                                // Enhanced action cards with error handling
                                _buildActionCards(appState),
                                
                                SizedBox(height: 24.0),
                                
                                // Today's menu section with error handling
                                _buildTodaysMenu(appState),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserGreeting(UserRecord? user) {
    return Row(
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
                    : 'Bonjour, Utilisateur',
                style: FlutterFlowTheme.of(context)
                    .headlineMedium
                    .override(
                      fontFamily: 'Inter Tight',
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Restaurant Universitaire ISET',
                style: FlutterFlowTheme.of(context)
                    .bodyMedium
                    .override(
                      fontFamily: 'Inter',
                      color: FlutterFlowTheme.of(context)
                          .secondaryText,
                      letterSpacing: 0.0,
                    ),
              ),
              if (user?.classe != null && user!.classe.isNotEmpty)
                Text(
                  'Classe: ${user.classe}',
                  style: FlutterFlowTheme.of(context)
                      .bodySmall
                      .override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.w600,
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
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  size: 40,
                  color: FlutterFlowTheme.of(context).primary,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(UserRecord? user) {
    return Container(
      width: double.infinity,
      height: 140.0,
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
                    'Solde Actuel',
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
                      user != null 
                        ? '${user.pocket.toStringAsFixed(2)} DT'
                        : '0.00 DT',
                      style: FlutterFlowTheme.of(context)
                          .headlineMedium
                          .override(
                            fontFamily: 'Inter Tight',
                            color: Colors.white,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (user != null)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          0.0, 4.0, 0.0, 0.0),
                      child: Text(
                        '${user.tickets} ticket${user.tickets != 1 ? 's' : ''} disponible${user.tickets != 1 ? 's' : ''}',
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
            FlutterFlowIconButton(
              borderRadius: 24.0,
              buttonSize: 48.0,
              fillColor: Color(0x33FFFFFF),
              icon: Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24.0,
              ),
              onPressed: () {
                // Navigate to balance management
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gestion du solde bientôt disponible'),
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(FFAppState appState) {
    return GridView(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.5,
      ),
      primary: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: [
        // Reservation card with error handling
        InkWell(
          onTap: _handleReservationAccess,
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
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 32.0,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Réserver Repas',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context)
                        .titleSmall
                        .override(
                          fontFamily: 'Inter Tight',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Réservez votre repas',
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
        
        // QR Code card with enhanced error handling
        InkWell(
          onTap: () => _handleQRCodeAccess(appState),
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
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    color: FlutterFlowTheme.of(context).tertiary,
                    size: 32.0,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Code QR',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context)
                        .titleSmall
                        .override(
                          fontFamily: 'Inter Tight',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Accès restaurant',
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
        
        // History card
        InkWell(
          onTap: () {
            try {
              context.pushNamed('history');
            } catch (e) {
              _errorHandler.showError(
                context,
                e,
                contextInfo: 'history_access',
              );
            }
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
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    color: FlutterFlowTheme.of(context).tertiary,
                    size: 32.0,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Historique',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context)
                        .titleSmall
                        .override(
                          fontFamily: 'Inter Tight',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Vos réservations',
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
        
        // Profile card
        InkWell(
          onTap: () {
            try {
              context.pushNamed('profile');
            } catch (e) {
              _errorHandler.showError(
                context,
                e,
                contextInfo: 'profile_access',
              );
            }
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
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 32.0,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Profil',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context)
                        .titleSmall
                        .override(
                          fontFamily: 'Inter Tight',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Mes informations',
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
    );
  }

  Widget _buildTodaysMenu(FFAppState appState) {
    final menu = appState.todaysMenu;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu du Jour',
          style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'Inter Tight',
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 16.0),
        if (menu.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'Aucun menu disponible aujourd\'hui',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          )
        else
          ...menu.map((plat) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 8.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 2.0,
                  color: Color(0x1A000000),
                  offset: Offset(0.0, 1.0),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plat.nom,
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Inter Tight',
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (plat.description.isNotEmpty)
                        Text(
                          plat.description,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Inter',
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${plat.prix.toStringAsFixed(2)} DT',
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Inter Tight',
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }
}