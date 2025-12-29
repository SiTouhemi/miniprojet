import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/role_middleware.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import 'reservation_list_model.dart';
export 'reservation_list_model.dart';

class ReservationListWidget extends StatefulWidget {
  const ReservationListWidget({super.key});

  static String routeName = 'ReservationList';
  static String routePath = '/admin/reservations';

  @override
  State<ReservationListWidget> createState() => _ReservationListWidgetState();
}

class _ReservationListWidgetState extends State<ReservationListWidget> {
  late ReservationListModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ReservationService _reservationService = ReservationService();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReservationListModel());
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      await RoleMiddleware.requireRole(UserRole.admin, 'gestion des réservations');
    } catch (e) {
      if (mounted) context.go('/');
    }
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
        backgroundColor: Color(0xFFF1F4F8),
        appBar: AppBar(
          backgroundColor: Color(0xFFF1F4F8),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0B191E),
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Gestion des Réservations',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                  ),
                  color: Color(0xFF0B191E),
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Filters
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _model.searchController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher (Utilisateur ID)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                    SizedBox(height: 12),
                    Row(
                       children: [
                         FilterChip(
                           label: Text('Date: ${_model.selectedDate == null ? 'Toutes' : DateFormat('d/M').format(_model.selectedDate!)}'),
                           selected: _model.selectedDate != null,
                           onSelected: (val) async {
                              if (val) {
                                final d = await showDatePicker(
                                  context: context, 
                                  initialDate: DateTime.now(), 
                                  firstDate: DateTime(2023), 
                                  lastDate: DateTime(2030)
                                );
                                setState(() => _model.selectedDate = d);
                              } else {
                                setState(() => _model.selectedDate = null);
                              }
                           },
                         ),
                         SizedBox(width: 8),
                         FilterChip(
                           label: Text('Actives seulement'),
                           selected: _model.showActiveOnly,
                           onSelected: (val) => setState(() => _model.showActiveOnly = val),
                         ),
                       ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ReservationRecord>>(
                  stream: queryReservationRecord(
                    queryBuilder: (query) {
                        Query q = query.orderBy('created_at', descending: true);
                        
                        // Note: Complex filtering usually needs composite indexes or client-side filtering.
                        // We will do client-side filtering for simplicity given the complexity of Firestore queries.
                        // We fetch a reasonable amount.
                        return q.limit(100); 
                    },
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                     
                    List<ReservationRecord> reservations = snapshot.data!;
                    
                    // Client side filtering
                    if (_model.searchController!.text.isNotEmpty) {
                       final search = _model.searchController!.text.toLowerCase();
                       reservations = reservations.where((r) => 
                          r.userId.toLowerCase().contains(search) || 
                          r.reference.id.toLowerCase().contains(search)
                       ).toList();
                    }
                    
                    if (_model.selectedDate != null) {
                       final target = _model.selectedDate!;
                       reservations = reservations.where((r) {
                          if (r.creneaux == null) return false;
                          final rd = r.creneaux!;
                          return rd.year == target.year && rd.month == target.month && rd.day == target.day;
                       }).toList();
                    }
                    
                    if (_model.showActiveOnly) {
                       reservations = reservations.where((r) => r.status == 'confirmed' || r.status == 'pending').toList();
                    }

                    if (reservations.isEmpty) return Center(child: Text('Aucune réservation trouvée'));

                    return ListView.builder(
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                         final res = reservations[index];
                         return _buildReservationCard(res);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(ReservationRecord res) {
    Color statusColor;
    switch (res.status) {
      case 'confirmed': statusColor = Colors.green; break;
      case 'cancelled': statusColor = Colors.red; break;
      case 'used': statusColor = Colors.grey; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('Ref: ${res.reference.id.substring(0,8).toUpperCase()}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${res.creneaux != null ? DateFormat('d MMM y HH:mm').format(res.creneaux!) : 'N/A'}'),
            Text('User: ${res.userId.substring(0,6)}...'), // Should fetch user name ideally
            Text('Prix: ${res.prix} TND'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
               child: Text(res.status, style: TextStyle(color: Colors.white, fontSize: 10)),
             ),
             if (res.status == 'confirmed')
               IconButton(
                 icon: Icon(Icons.cancel, color: Colors.red),
                 onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Annuler réservation ?'),
                        content: Text('Ceci remboursera l\'utilisateur.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Retour')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Confirmer', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                       await _reservationService.cancelReservation(res.reference.id);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réservation annulée')));
                    }
                 },
               ),
          ],
        ),
      ),
    );
  }
}
