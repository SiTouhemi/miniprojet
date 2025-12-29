import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/app_logger.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'history_model.dart';
export 'history_model.dart';
import '/backend/backend.dart';
import '/backend/schema/reservation_record.dart';
import '/backend/services/reservation_service.dart';
import '/backend/services/time_slot_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:intl/intl.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  static String routeName = 'history';
  static String routePath = '/history';

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late HistoryModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ReservationService _reservationService = ReservationService.instance;
  
  // 0: All, 1: Upcoming, 2: Past
  int _selectedFilterIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Handle Reservation Modification
  Future<void> _handleModifyReservation(ReservationRecord reservation) async {
    // Show dialog to pick new time slot
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: reservation.creneaux ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF1C1284),
            colorScheme: ColorScheme.light(primary: Color(0xFF1C1284)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (newDate == null) return;

    if (!mounted) return;

    // Show available slots for selected date
    await showDialog(
      context: context,
      builder: (context) => _buildTimeSlotPickerDialog(reservation, newDate),
    );
  }

  Widget _buildTimeSlotPickerDialog(ReservationRecord reservation, DateTime date) {
    return AlertDialog(
      title: Text('Choisir un nouveau créneau'),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<List<TimeSlotRecord>>(
          stream: queryTimeSlotRecord(
            queryBuilder: (query) => query
                .where('date', isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day))
                .where('date', isLessThan: DateTime(date.year, date.month, date.day + 1))
                .where('is_active', isEqualTo: true)
                .orderBy('start_time'),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final slots = snapshot.data!;
            if (slots.isEmpty) {
              return Center(child: Text('Aucun créneau disponible pour cette date.'));
            }

            return ListView.builder(
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final bool isFull = slot.currentReservations >= slot.maxCapacity;
                
                return ListTile(
                  title: Text(
                    '${DateFormat('HH:mm').format(slot.startTime!)} - ${DateFormat('HH:mm').format(slot.endTime!)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${slot.mealType} | Prix: ${slot.price} DT'),
                  trailing: isFull 
                      ? Text('Complet', style: TextStyle(color: Colors.red))
                      : Icon(Icons.arrow_forward_ios, size: 16),
                  enabled: !isFull,
                  onTap: () async {
                    Navigator.pop(context);
                    await _processModification(reservation, slot);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
      ],
    );
  }

  Future<void> _processModification(ReservationRecord reservation, TimeSlotRecord newSlot) async {
    setState(() => _isProcessing = true);
    
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la modification'),
        content: Text(
          'Voulez-vous modifier votre réservation pour le ${DateFormat('dd/MM HH:mm').format(newSlot.startTime!)} ?\n\n'
          'Tout changement de prix sera ajusté sur votre solde.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Oui')),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final result = await _reservationService.modifyReservation(
        reservationId: reservation.reference.id,
        newTimeSlotId: newSlot.reference.id,
        userId: currentUserUid,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réservation modifiée avec succès'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Échec de la modification'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Handle Cancellation
  Future<void> _handleCancelReservation(ReservationRecord reservation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la réservation'),
        content: Text('Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Oui, Annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _reservationService.cancelReservation(
        reservationId: reservation.reference.id,
        userId: currentUserUid,
        reason: 'User cancelled via History',
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réservation annulée avec succès'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Échec de l\'annulation'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
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
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Color(0xFFF8F9FA),
          iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
          automaticallyImplyLeading: true,
          title: Text(
            'Historique',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'Inter Tight',
              color: Color(0xFF2C3E50),
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
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
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(blurRadius: 4, color: Color(0x1A000000), offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab('Tous', 0),
                      _buildFilterTab('À venir', 1),
                      _buildFilterTab('Passés', 2),
                    ],
                  ),
                ),
              ),

              // Reservations List
              Expanded(
                child: _isProcessing 
                    ? Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<ReservationRecord>>(
                        stream: queryReservationRecord(
                          queryBuilder: (query) => query
                              .where('user_id', isEqualTo: currentUserUid)
                              .orderBy('creneaux', descending: true),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final allReservations = snapshot.data!;
                          
                          if (allReservations.isEmpty) {
                            return Center(
                              child: Text(
                                'Aucune réservation trouvée.',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            );
                          }

                          // Filter in memory
                          final now = DateTime.now();
                          List<ReservationRecord> filteredReservations = [];
                          
                          if (_selectedFilterIndex == 0) {
                            filteredReservations = allReservations;
                          } else if (_selectedFilterIndex == 1) {
                            // Upcoming
                            filteredReservations = allReservations.where((r) {
                              // Include pending/confirmed and future dates
                              return (r.status == 'confirmed' || r.status == 'pending') && 
                                     (r.creneaux?.isAfter(now) ?? false);
                            }).toList();
                             // Show oldest first for upcoming? No, usually soonest is best.
                             // Creating new list to sort
                             filteredReservations.sort((a, b) => a.creneaux!.compareTo(b.creneaux!));
                          } else {
                            // Past
                            filteredReservations = allReservations.where((r) {
                              return r.creneaux?.isBefore(now) ?? true; // or status is used/cancelled
                            }).toList();
                          }

                          if (filteredReservations.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  _selectedFilterIndex == 1 
                                      ? 'Aucune réservation à venir.' 
                                      : 'Aucune réservation passée.',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.all(16.0),
                            itemCount: filteredReservations.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.0),
                            itemBuilder: (context, index) {
                              return _buildReservationCard(filteredReservations[index]);
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

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          height: 40.0,
          margin: EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF27AE60) : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Color(0xFF7F8C8D),
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(ReservationRecord reservation) {
    final bool isUpcoming = reservation.creneaux != null && reservation.creneaux!.isAfter(DateTime.now());
    final bool isConfirmed = reservation.status == 'confirmed';
    final bool canModify = isUpcoming && isConfirmed && (reservation.creneaux!.difference(DateTime.now()).inHours >= 2);

    Color statusColor;
    String statusText;
    
    switch(reservation.status) {
      case 'confirmed':
        statusColor = Color(0xFF27AE60);
        statusText = 'Confirmé';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Annulé';
        break;
      case 'used':
        statusColor = Colors.grey;
        statusText = 'Utilisé';
        break;
      default:
        statusColor = Colors.grey;
        statusText = reservation.status;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 8.0,
            color: Color(0x1A000000),
            offset: Offset(0, 2),
          )
        ],
        border: Border.all(
          color: isUpcoming ? Color(0xFF1C1284).withOpacity(0.1) : Colors.transparent,
        )
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.0, 
                            height: 8.0, 
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            statusText,
                            style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12.0),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        reservation.mealType, // 'Déjeuner' or 'Dîner'
                        style: GoogleFonts.interTight(
                          fontSize: 18.0, 
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4.0),
                      _buildInfoRow(Icons.calendar_today, DateFormat('EEEE d MMMM y', 'fr_FR').format(reservation.creneaux ?? DateTime.now())),
                      _buildInfoRow(Icons.access_time, DateFormat('HH:mm').format(reservation.creneaux ?? DateTime.now())),
                      if (reservation.total > 0)
                        _buildInfoRow(Icons.euro, '${reservation.total} DT'),
                    ],
                  ),
                ),
                if (reservation.qrCode.isNotEmpty && isConfirmed)
                  Icon(Icons.qr_code_2, size: 40, color: Color(0xFF1C1284)),
              ],
            ),
            
            // Action Buttons for Upcoming Reservations
            if (canModify)
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _handleCancelReservation(reservation),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('Annuler'),
                    ),
                    SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () => _handleModifyReservation(reservation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1C1284),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Modifier'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Color(0xFF7F8C8D)),
          SizedBox(width: 8.0),
          Text(text, style: GoogleFonts.inter(color: Color(0xFF7F8C8D), fontSize: 14.0)),
        ],
      ),
    );
  }
}
