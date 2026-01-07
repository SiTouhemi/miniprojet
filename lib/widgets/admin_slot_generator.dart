import 'package:flutter/material.dart';
import '/utils/time_slot_generator.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Admin utility widget for generating time slots
class AdminSlotGenerator extends StatefulWidget {
  const AdminSlotGenerator({super.key});

  @override
  State<AdminSlotGenerator> createState() => _AdminSlotGeneratorState();
}

class _AdminSlotGeneratorState extends State<AdminSlotGenerator> {
  bool _isGenerating = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _generateTodaysSlots() async {
    setState(() {
      _isGenerating = true;
      _message = null;
    });

    try {
      final result = await TimeSlotGenerator.generateTodaysSlots();

      setState(() {
        _isSuccess = result['success'];
        _message = result['message'];
        if (result['created'] > 0) {
          _message =
              '${result['message']} (${result['created']} slots created)';
        } else if (result['existing'] != null) {
          _message = '${result['message']} (${result['existing']} slots found)';
        }
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateWeekSlots() async {
    setState(() {
      _isGenerating = true;
      _message = null;
    });

    try {
      final result = await TimeSlotGenerator.generateSlotsForDays(days: 7);

      setState(() {
        _isSuccess = result['success'];
        _message =
            '${result['message']} (${result['created']} days created, ${result['skipped']} skipped)';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time Slot Generator',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    color: Color(0xFF005BAA),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Generate time slots from templates for students to make reservations.',
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateTodaysSlots,
                    icon: _isGenerating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.today),
                    label: Text('Generate Today'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF005BAA),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateWeekSlots,
                    icon: Icon(Icons.date_range),
                    label: Text('Generate Week'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A4E4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Status message
            if (_message != null) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
