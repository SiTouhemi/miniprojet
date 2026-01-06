import 'package:flutter/material.dart';
import '/backend/services/time_slot_template_service.dart';
import '/backend/services/time_slot_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';

/// Admin page for managing recurring time slot templates
class TimeSlotTemplatesWidget extends StatefulWidget {
  const TimeSlotTemplatesWidget({Key? key}) : super(key: key);

  static String routeName = 'TimeSlotTemplates';
  static String routePath = '/admin/timeSlotTemplates';

  @override
  State<TimeSlotTemplatesWidget> createState() =>
      _TimeSlotTemplatesWidgetState();
}

class _TimeSlotTemplatesWidgetState extends State<TimeSlotTemplatesWidget> {
  final _templateService = TimeSlotTemplateService.instance;
  final _timeSlotService = TimeSlotService.instance;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1284),
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 20.0,
          buttonSize: 40.0,
          fillColor: Colors.transparent,
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Time Slot Templates',
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
              fillColor: Color(0xFF00A4E4),
              icon: Icon(Icons.add, color: Colors.white, size: 24.0),
              onPressed: () => _showAddTemplateDialog(context),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 2.0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xFFE3F2FD),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1976D2), width: 2.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1976D2)),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Templates define recurring time slots. They are used to generate daily slots automatically.',
                      style: TextStyle(color: Color(0xFF1976D2)),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _initializeDefaultTemplates,
                      text: 'Initialize Defaults',
                      icon: Icon(Icons.settings_backup_restore, size: 20),
                      options: FFButtonOptions(
                        height: 44,
                        color: Color(0xFF4CAF50),
                        textStyle: TextStyle(color: Colors.white),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: _generateSlotsForWeek,
                      text: 'Generate Week',
                      icon: Icon(Icons.calendar_month, size: 20),
                      options: FFButtonOptions(
                        height: 44,
                        color: Color(0xFF00A4E4),
                        textStyle: TextStyle(color: Colors.white),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Templates list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _templateService.getTemplatesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1C1284)),
                      ),
                    );
                  }

                  final templates = snapshot.data ?? [];

                  if (templates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No templates found',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click "Initialize Defaults" to create standard templates',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by meal type
                  final lunchTemplates = templates
                      .where((t) => t['meal_type'] == 'lunch')
                      .toList();
                  final dinnerTemplates = templates
                      .where((t) => t['meal_type'] == 'dinner')
                      .toList();

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lunchTemplates.isNotEmpty) ...[
                          _buildMealTypeSection(
                              'Lunch Templates', lunchTemplates, Colors.orange),
                          SizedBox(height: 24),
                        ],
                        if (dinnerTemplates.isNotEmpty) ...[
                          _buildMealTypeSection('Dinner Templates',
                              dinnerTemplates, Colors.deepPurple),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSection(
      String title, List<Map<String, dynamic>> templates, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu, color: color),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Spacer(),
              Text(
                '${templates.length} slots',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        ...templates.map((template) => _buildTemplateCard(template, color)),
      ],
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, Color accentColor) {
    final isActive = template['is_active'] as bool? ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? accentColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.access_time,
            color: isActive ? accentColor : Colors.grey,
          ),
        ),
        title: Text(
          '${template['start_time']} - ${template['end_time']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('Capacity: ${template['max_capacity']}'),
                SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                Text('${template['price']} DT'),
              ],
            ),
            if (!isActive) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'INACTIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isActive ? Icons.toggle_on : Icons.toggle_off,
                color: isActive ? Colors.green : Colors.grey,
                size: 32,
              ),
              onPressed: () => _toggleTemplateStatus(template),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF1C1284)),
              onPressed: () => _showEditTemplateDialog(context, template),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTemplate(template),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeDefaultTemplates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final result = await _templateService.initializeDefaultTemplates();

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor:
            result['success'] as bool ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _generateSlotsForWeek() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final result = await _timeSlotService.bulkCreateTimeSlotsFromTemplates(
      startDate: DateTime.now(),
      numberOfDays: 7,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context) {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final capacityController = TextEditingController(text: '50');
    final priceController = TextEditingController(text: '0.2');
    String selectedMealType = 'lunch';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Time Slot Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    labelText: 'Start Time (HH:mm)',
                    hintText: '11:40',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: endTimeController,
                  decoration: InputDecoration(
                    labelText: 'End Time (HH:mm)',
                    hintText: '12:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Max Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (DT)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final templateId = await _templateService.createTemplate(
                  mealType: selectedMealType,
                  startTime: startTimeController.text,
                  endTime: endTimeController.text,
                  maxCapacity: int.parse(capacityController.text),
                  price: double.parse(priceController.text),
                );

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(templateId != null
                        ? 'Template created successfully'
                        : 'Failed to create template'),
                    backgroundColor:
                        templateId != null ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1C1284),
              ),
              child: Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTemplateDialog(
      BuildContext context, Map<String, dynamic> template) {
    final startTimeController =
        TextEditingController(text: template['start_time']);
    final endTimeController = TextEditingController(text: template['end_time']);
    final capacityController =
        TextEditingController(text: template['max_capacity'].toString());
    final priceController =
        TextEditingController(text: template['price'].toString());
    String selectedMealType = template['meal_type'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    labelText: 'Start Time (HH:mm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: endTimeController,
                  decoration: InputDecoration(
                    labelText: 'End Time (HH:mm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Max Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (DT)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _templateService.updateTemplate(
                  template['id'],
                  {
                    'meal_type': selectedMealType,
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'max_capacity': int.parse(capacityController.text),
                    'price': double.parse(priceController.text),
                  },
                );

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Template updated successfully'
                        : 'Failed to update template'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1C1284),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTemplateStatus(Map<String, dynamic> template) async {
    final isActive = template['is_active'] as bool? ?? true;
    final success = await _templateService.updateTemplate(
      template['id'],
      {'is_active': !isActive},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Template ${!isActive ? 'activated' : 'deactivated'}'
            : 'Failed to update template'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Template'),
        content: Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _templateService.deleteTemplate(template['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Template deleted successfully'
              : 'Failed to delete template'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
