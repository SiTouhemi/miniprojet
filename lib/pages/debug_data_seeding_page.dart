import 'package:flutter/material.dart';
import '/backend/services/data_seeding_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/app_logger.dart';

/// Debug page for seeding database with sample data
/// This page should only be used during development/testing
class DebugDataSeedingPage extends StatefulWidget {
  const DebugDataSeedingPage({super.key});

  static const String routeName = 'DebugDataSeeding';
  static const String routePath = '/debug-data-seeding';

  @override
  State<DebugDataSeedingPage> createState() => _DebugDataSeedingPageState();
}

class _DebugDataSeedingPageState extends State<DebugDataSeedingPage> {
  bool _isSeeding = false;
  bool _isClearing = false;
  bool _isChecking = false;
  bool? _hasSampleData;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkSampleData();
  }

  Future<void> _checkSampleData() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking existing data...';
    });

    try {
      final hasData = await DataSeedingService.instance.hasSampleData();
      setState(() {
        _hasSampleData = hasData;
        _statusMessage = hasData 
          ? 'Sample data exists in database' 
          : 'No sample data found';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking data: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Seeding database with sample data...';
    });

    try {
      final success = await DataSeedingService.instance.seedAllData();
      setState(() {
        _statusMessage = success 
          ? '✅ Database seeded successfully!\n\n• 12 weekly menu items added\n• Time slots created for next 7 days\n• Students can now see menus and make reservations'
          : '❌ Failed to seed database';
      });
      
      if (success) {
        await _checkSampleData();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error seeding database: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearSampleData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sample Data'),
        content: const Text('Are you sure you want to clear all sample data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _statusMessage = 'Clearing sample data...';
    });

    try {
      final success = await DataSeedingService.instance.clearSampleData();
      setState(() {
        _statusMessage = success 
          ? '✅ Sample data cleared successfully'
          : '❌ Failed to clear sample data';
      });
      
      if (success) {
        await _checkSampleData();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing data: $e';
      });
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: const Text(
          'Debug: Data Seeding',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Sample Data Manager',
                        style: FlutterFlowTheme.of(context).headlineSmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'This page helps you populate the database with sample data for testing the restaurant reservation system.',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasSampleData == true ? Icons.check_circle : Icons.info,
                            color: _hasSampleData == true ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Current Status',
                            style: FlutterFlowTheme.of(context).titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (_isChecking)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            ),
                            SizedBox(width: 8.0),
                            Text('Checking...'),
                          ],
                        )
                      else
                        Text(
                          _statusMessage,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Action Buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Actions',
                        style: FlutterFlowTheme.of(context).titleMedium,
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Seed Database Button
                      FFButtonWidget(
                        onPressed: _isSeeding || _isClearing ? null : _seedDatabase,
                        text: _isSeeding ? 'Seeding...' : 'Seed Database',
                        icon: _isSeeding 
                          ? const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_circle, color: Colors.white),
                        options: FFButtonOptions(
                          height: 50.0,
                          color: Colors.green,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      
                      const SizedBox(height: 12.0),
                      
                      // Refresh Status Button
                      FFButtonWidget(
                        onPressed: _isSeeding || _isClearing || _isChecking ? null : _checkSampleData,
                        text: 'Refresh Status',
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        options: FFButtonOptions(
                          height: 50.0,
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      
                      const SizedBox(height: 12.0),
                      
                      // Clear Data Button
                      FFButtonWidget(
                        onPressed: _isSeeding || _isClearing || _hasSampleData != true ? null : _clearSampleData,
                        text: _isClearing ? 'Clearing...' : 'Clear Sample Data',
                        icon: _isClearing 
                          ? const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete, color: Colors.white),
                        options: FFButtonOptions(
                          height: 50.0,
                          color: Colors.red,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What gets seeded:',
                        style: FlutterFlowTheme.of(context).titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      const Text('• 12 weekly menu items (2 meals × 6 days)'),
                      const Text('• Monday-Saturday: lunch + dinner'),
                      const Text('• Sunday: restaurant closed'),
                      const Text('• Time slots for next 7 days'),
                      const Text('• 4 lunch slots + 4 dinner slots per day'),
                      const Text('• Realistic pricing and capacity'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}