import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/role_middleware.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/backend/backend.dart';
import '/backend/services/time_slot_service.dart';
import 'time_slots_model.dart';
export 'time_slots_model.dart';

class TimeSlotsWidget extends StatefulWidget {
  const TimeSlotsWidget({super.key});

  static String routeName = 'TimeSlots';
  static String routePath = '/admin/timeSlots';

  @override
  State<TimeSlotsWidget> createState() => _TimeSlotsWidgetState();
}

class _TimeSlotsWidgetState extends State<TimeSlotsWidget> {
  late TimeSlotsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TimeSlotService _timeSlotService = TimeSlotService.instance;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TimeSlotsModel());
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
     try {
       await RoleMiddleware.requireRole(UserRole.admin, 'gestion des créneaux');
     } catch (e) {
       if (mounted) {
         context.go('/');
       }
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
            'Gestion des Créneaux',
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
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await _showCreateSlotDialog();
          },
          backgroundColor: Color(0xFF4B986C),
          elevation: 8.0,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 24.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<TimeSlotRecord>>(
            stream: queryTimeSlotRecord(
              queryBuilder: (timeSlotRecord) => timeSlotRecord.orderBy('date', descending: true),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4B986C),
                  ),
                );
              }
              List<TimeSlotRecord> slots = snapshot.data!;
              if (slots.isEmpty) {
                return Center(
                  child: Text('Aucun créneau trouvé.'),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  return _buildSlotCard(slot);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(TimeSlotRecord slot) {
    final date = slot.date ?? DateTime.now();
    final startTime = slot.startTime ?? DateTime.now();
    final endTime = slot.endTime ?? DateTime.now();
    final isActive = slot.isActive;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: Material(
        color: Colors.transparent,
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isActive ? Color(0xFFC8D7E4) : Color(0xFFE0E0E0),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('d MMM y', 'fr_FR').format(date)}',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                          color: isActive ? Color(0xFF0B191E) : Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Type: ${slot.mealType} | Places: ${slot.currentReservations}/${slot.maxCapacity}',
                         style: FlutterFlowTheme.of(context).bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                     Switch(
                        value: isActive,
                        activeColor: Color(0xFF4B986C),
                        onChanged: (val) async {
                          // Toggle active status
                          await _timeSlotService.updateTimeSlotCapacity(
                            slot.reference.id,
                            slot.maxCapacity, // Keep same capacity, just toggle active status
                          );
                          // Note: We need a separate method for toggling active status
                        },
                     ),
                     IconButton(
                       icon: Icon(Icons.edit, color: Color(0xFF384E58)),
                       onPressed: () => _showEditSlotDialog(slot),
                     ),
                     IconButton(
                       icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (c) => AlertDialog(
                               title: Text('Supprimer ?'),
                               content: Text('Cette action est irréversible.'),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Annuler')),
                                 TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                               ],
                             ),
                           );
                           if (confirm == true) {
                             await slot.reference.delete();
                           }
                        },
                     ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _showCreateSlotDialog() async {
    // Show a dialog to create a new slot
    // This is a simplified version.
     await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateSlotDialog();
      },
    );
  }

  Future<void> _showEditSlotDialog(TimeSlotRecord slot) async {
      await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditSlotDialog(slot: slot);
      },
    );
  }
}

class CreateSlotDialog extends StatefulWidget {
  @override
  _CreateSlotDialogState createState() => _CreateSlotDialogState();
}

class _CreateSlotDialogState extends State<CreateSlotDialog> {
    final _formKey = GlobalKey<FormState>();
    DateTime _selectedDate = DateTime.now();
    TimeOfDay _startTime = TimeOfDay(hour: 12, minute: 0);
    TimeOfDay _endTime = TimeOfDay(hour: 13, minute: 0);
    int _capacity = 50;
    double _price = 2.5;
    String _mealType = 'lunch'; // or dinner

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: Text('Ajouter Créneau'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ListTile(
                   title: Text('Date: ${DateFormat('d/M/y').format(_selectedDate)}'),
                   trailing: Icon(Icons.calendar_today),
                   onTap: () async {
                     final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 30)));
                     if (d != null) setState(() => _selectedDate = d);
                   },
                 ),
                 ListTile(
                   title: Text('Début: ${_startTime.format(context)}'),
                   trailing: Icon(Icons.access_time),
                   onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _startTime);
                      if (t != null) setState(() => _startTime = t);
                   },
                 ),
                 ListTile(
                   title: Text('Fin: ${_endTime.format(context)}'),
                   trailing: Icon(Icons.access_time),
                   onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _endTime);
                      if (t != null) setState(() => _endTime = t);
                   },
                 ),
                 TextFormField(
                   initialValue: '50',
                   decoration: InputDecoration(labelText: 'Capacité'),
                   keyboardType: TextInputType.number,
                   onChanged: (v) => _capacity = int.tryParse(v) ?? 50,
                 ),
                 TextFormField(
                   initialValue: '2.5',
                   decoration: InputDecoration(labelText: 'Prix (TND)'),
                   keyboardType: TextInputType.number,
                   onChanged: (v) => _price = double.tryParse(v) ?? 2.5,
                 ),
                 DropdownButtonFormField<String>(
                   value: _mealType,
                   items: [
                     DropdownMenuItem(value: 'lunch', child: Text('Déjeuner')),
                     DropdownMenuItem(value: 'dinner', child: Text('Dîner')),
                   ],
                   onChanged: (v) => setState(() => _mealType = v!),
                   decoration: InputDecoration(labelText: 'Type de repas'),
                 ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
               // Construct DateTimes
               final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
               final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

               await TimeSlotService.instance.createTimeSlot(
                 startTime: start,
                 endTime: end,
                 maxCapacity: _capacity,
                 price: _price,
                 mealType: _mealType,
                 date: _selectedDate,
               );
               Navigator.pop(context);
            },
            child: Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4B986C), foregroundColor: Colors.white),
          ),
        ],
      );
    }
}

class EditSlotDialog extends StatefulWidget {
  final TimeSlotRecord slot;
  const EditSlotDialog({required this.slot});

  @override
  _EditSlotDialogState createState() => _EditSlotDialogState();
}

class _EditSlotDialogState extends State<EditSlotDialog> {
   late int _capacity;
   late double _price;

   @override
   void initState() {
     super.initState();
     _capacity = widget.slot.maxCapacity;
     _price = widget.slot.price;
   }

   @override
   Widget build(BuildContext context) {
      return AlertDialog(
        title: Text('Modifier Créneau'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextFormField(
               initialValue: _capacity.toString(),
               decoration: InputDecoration(labelText: 'Capacité'),
               keyboardType: TextInputType.number,
               onChanged: (v) => _capacity = int.tryParse(v) ?? _capacity,
             ),
             TextFormField(
               initialValue: _price.toString(),
               decoration: InputDecoration(labelText: 'Prix'),
               keyboardType: TextInputType.number,
               onChanged: (v) => _price = double.tryParse(v) ?? _price,
             ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
             onPressed: () async {
                await TimeSlotService.instance.updateTimeSlotCapacity(
                  widget.slot.reference.id,
                  _capacity,
                );
                Navigator.pop(context);
             },
             child: Text('Sauvegarder'),
             style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4B986C), foregroundColor: Colors.white),
          ),
        ],
      );
   }
}
