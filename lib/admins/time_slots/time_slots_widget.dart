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
            'Time Slot Management',
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
          actions: [
            FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              borderWidth: 1.0,
              buttonSize: 60.0,
              icon: Icon(
                Icons.settings,
                color: Color(0xFF1C1284),
                size: 24.0,
              ),
              onPressed: () async {
                Navigator.pushNamed(context, '/admin/timeSlotTemplates');
              },
            ),
            FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              borderWidth: 1.0,
              buttonSize: 60.0,
              icon: Icon(
                Icons.auto_awesome,
                color: Color(0xFF4B986C),
                size: 24.0,
              ),
              onPressed: () async {
                await _showBulkCreateDialog();
              },
            ),
            FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              borderWidth: 1.0,
              buttonSize: 60.0,
              icon: Icon(
                Icons.cleaning_services,
                color: Color(0xFFE74C3C),
                size: 24.0,
              ),
              onPressed: () async {
                await _showCleanupDialog();
              },
            ),
          ],
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
              queryBuilder: (timeSlotRecord) =>
                  timeSlotRecord.orderBy('date', descending: true),
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
                  child: Text('No time slots found.'),
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
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
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
                        await slot.reference.update({'is_active': val});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF384E58)),
                      onPressed: () => _showEditSlotDialog(slot),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        // Check if slot has reservations
                        if (slot.currentReservations > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Cannot delete: ${slot.currentReservations} existing reservation(s)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('Delete?'),
                            content: Text('This action is irreversible.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text('Delete',
                                      style: TextStyle(color: Colors.red))),
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

  /// Show bulk time slot creation dialog
  Future<void> _showBulkCreateDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BulkCreateSlotsDialog();
      },
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

  /// Show cleanup dialog for expired time slots
  Future<void> _showCleanupDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cleaning_services, color: Color(0xFFE74C3C)),
              SizedBox(width: 8),
              Text('Cleanup Expired Slots'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will remove expired time slots from the database to improve performance.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Clean expired slots (from previous days)'),
              Text('• Clean old slots (older than 7 days)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performCleanup(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: Text('Clean Expired'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performCleanup(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: Text('Clean Old (7+ days)'),
            ),
          ],
        );
      },
    );
  }

  /// Perform the actual cleanup operation
  Future<void> _performCleanup(bool cleanOld) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Cleaning up time slots...'),
            ],
          ),
        ),
      );

      // Perform cleanup
      final result = cleanOld
          ? await TimeSlotService.instance.cleanupOldTimeSlots(daysOld: 7)
          : await TimeSlotService.instance.cleanupExpiredTimeSlots();

      // Close loading dialog
      Navigator.pop(context);

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success'] ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Text('Cleanup ${result['success'] ? 'Complete' : 'Failed'}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message']),
              if (result['success'] && result['deletedCount'] > 0) ...[
                SizedBox(height: 8),
                Text(
                  'Deleted ${result['deletedCount']} time slots',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (result['errorCount'] != null && result['errorCount'] > 0) ...[
                SizedBox(height: 8),
                Text(
                  'Errors: ${result['errorCount']}',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Cleanup Failed'),
            ],
          ),
          content: Text('Error: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
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
      title: Text('Add Time Slot'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title:
                    Text('Date: ${DateFormat('d/M/y').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 30)));
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              ListTile(
                title: Text('Début: ${_startTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: _startTime);
                  if (t != null) setState(() => _startTime = t);
                },
              ),
              ListTile(
                title: Text('Fin: ${_endTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: _endTime);
                  if (t != null) setState(() => _endTime = t);
                },
              ),
              TextFormField(
                initialValue: '50',
                decoration: InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _capacity = int.tryParse(v) ?? 50,
              ),
              TextFormField(
                initialValue: '2.5',
                decoration: InputDecoration(labelText: 'Price (TND)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _price = double.tryParse(v) ?? 2.5,
              ),
              DropdownButtonFormField<String>(
                value: _mealType,
                items: [
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                ],
                onChanged: (v) => setState(() => _mealType = v!),
                decoration: InputDecoration(labelText: 'Type de repas'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            // Construct DateTimes
            final start = DateTime(_selectedDate.year, _selectedDate.month,
                _selectedDate.day, _startTime.hour, _startTime.minute);
            final end = DateTime(_selectedDate.year, _selectedDate.month,
                _selectedDate.day, _endTime.hour, _endTime.minute);

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
          child: Text('Add'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B986C),
              foregroundColor: Colors.white),
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
      title: Text('Edit Time Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _capacity.toString(),
            decoration: InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _capacity = int.tryParse(v) ?? _capacity,
          ),
          TextFormField(
            initialValue: _price.toString(),
            decoration: InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _price = double.tryParse(v) ?? _price,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            await TimeSlotService.instance.updateTimeSlotCapacity(
              widget.slot.reference.id,
              _capacity,
            );
            Navigator.pop(context);
          },
          child: Text('Save'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B986C),
              foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

/// Dialog for bulk creating time slots with 20-minute intervals
class BulkCreateSlotsDialog extends StatefulWidget {
  @override
  _BulkCreateSlotsDialogState createState() => _BulkCreateSlotsDialogState();
}

class _BulkCreateSlotsDialogState extends State<BulkCreateSlotsDialog> {
  DateTime _startDate = DateTime.now();
  int _numberOfDays = 7;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF4B986C)),
          SizedBox(width: 8),
          Text('Generate Time Slots'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create 20-minute time slots for:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• Lunch: 11:40 - 14:00 (7 slots per day)'),
            Text('• Dinner: 17:40 - 18:40 (3 slots per day)'),
            SizedBox(height: 16),

            // Start date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: Color(0xFF4B986C)),
              title: Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),

            // Number of days
            TextFormField(
              initialValue: _numberOfDays.toString(),
              decoration: InputDecoration(
                labelText: 'Number of Days',
                prefixIcon: Icon(Icons.event_repeat, color: Color(0xFF4B986C)),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _numberOfDays = int.tryParse(v) ?? 7,
            ),

            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF4B986C).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFF4B986C)),
                  ),
                  SizedBox(height: 4),
                  Text('• $_numberOfDays days of time slots'),
                  Text(
                      '• ${_numberOfDays * 10} total slots (7 lunch + 3 dinner per day)'),
                  Text('• 25 capacity per slot'),
                  Text('• 0.2 TND per reservation'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createTimeSlots,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4B986C),
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Creating...'),
                  ],
                )
              : Text('Generate Slots'),
        ),
      ],
    );
  }

  Future<void> _createTimeSlots() async {
    setState(() => _isCreating = true);

    try {
      final result = await TimeSlotService.instance.bulkCreateTimeSlots(
        startDate: _startDate,
        numberOfDays: _numberOfDays,
      );

      Navigator.pop(context);

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['created'] > 0 ? Icons.check_circle : Icons.warning,
                color: result['created'] > 0 ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 8),
              Text('Generation Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Created: ${result['created']} days'),
              if (result['skipped'] > 0)
                Text('⏭️ Skipped: ${result['skipped']} days (already exist)'),
              if (result['errors'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text('❌ Errors:', style: TextStyle(color: Colors.red)),
                ...result['errors'].map<Widget>((error) => Text('• $error')),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating time slots: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
