import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/services/user_import_service.dart';
import '/utils/app_logger.dart';
import '/auth/role_middleware.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'user_import_model.dart';
export 'user_import_model.dart';

/// Widget for importing and exporting users via Excel
class UserImportWidget extends StatefulWidget {
  const UserImportWidget({super.key});

  static String routeName = 'user_import';
  static String routePath = '/admin/user-import';

  @override
  State<UserImportWidget> createState() => _UserImportWidgetState();
}

class _UserImportWidgetState extends State<UserImportWidget> {
  late UserImportModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final UserImportService _importService = UserImportService.instance;

  bool _isProcessing = false;
  ImportResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserImportModel());
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      await RoleMiddleware.requireRole(
          UserRole.admin, 'import/export des utilisateurs');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accès non autorisé: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isProcessing = true);

      final bytes = await _importService.generateTemplate();
      final fileName =
          'user_import_template_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // Web download
        await downloadFile(bytes, fileName);
      } else {
        // Mobile/Desktop download
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Template',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Template saved to: $path'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      AppLogger.i('Template downloaded successfully', tag: 'UserImportWidget');
    } catch (e) {
      AppLogger.e('Error downloading template',
          error: e, tag: 'UserImportWidget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading template: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importUsers() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Unable to read file');
      }

      setState(() => _isProcessing = true);

      final importResult = await _importService.importUsers(file.bytes!);

      setState(() {
        _lastResult = importResult;
        _isProcessing = false;
      });

      if (mounted) {
        _showResultDialog(importResult);
      }
    } catch (e) {
      AppLogger.e('Error importing users', error: e, tag: 'UserImportWidget');
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportUsers() async {
    try {
      setState(() => _isProcessing = true);

      final bytes = await _importService.exportUsers();
      final fileName =
          'users_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // Web download
        await downloadFile(bytes, fileName);
      } else {
        // Mobile/Desktop download
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Users',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Users exported to: $path'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      AppLogger.i('Users exported successfully', tag: 'UserImportWidget');
    } catch (e) {
      AppLogger.e('Error exporting users', error: e, tag: 'UserImportWidget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasErrors ? Icons.warning : Icons.check_circle,
              color: result.hasErrors ? Colors.orange : Colors.green,
            ),
            SizedBox(width: 8),
            Text('Import Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Processed: ${result.totalProcessed}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Successful: ${result.successCount}',
                style: TextStyle(color: Colors.green),
              ),
              Text(
                'Failed: ${result.failureCount}',
                style: TextStyle(color: Colors.red),
              ),
              if (result.hasErrors) ...[
                SizedBox(height: 16),
                Text(
                  'Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...result.errors.map((error) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        error.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
          backgroundColor: Color(0xFF4B986C),
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Import/Export Users',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF4B986C)),
                              SizedBox(width: 8),
                              Text(
                                'Instructions',
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      font: GoogleFonts.urbanist(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      color: Color(0xFF0B191E),
                                      fontSize: 20.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            '1. Download the Excel template\n'
                            '2. Fill in user information (one user per row)\n'
                            '3. Upload the completed file to import users\n'
                            '4. Review the import results',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(),
                                  color: Color(0xFF384E58),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFFFC107),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Color(0xFFF57C00)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Do not modify column headers in the template',
                                    style: TextStyle(
                                      color: Color(0xFFF57C00),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Download Template Button
                  FFButtonWidget(
                    onPressed: _isProcessing ? null : _downloadTemplate,
                    text: 'Download Excel Template',
                    icon: Icon(
                      Icons.download,
                      size: 20,
                    ),
                    options: FFButtonOptions(
                      height: 50,
                      padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                      iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                      color: Color(0xFF4B986C),
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                      elevation: 2,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Import Users Button
                  FFButtonWidget(
                    onPressed: _isProcessing ? null : _importUsers,
                    text: 'Import Users from Excel',
                    icon: Icon(
                      Icons.upload_file,
                      size: 20,
                    ),
                    options: FFButtonOptions(
                      height: 50,
                      padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                      iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                      color: Color(0xFF928163),
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                      elevation: 2,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Export Users Button
                  FFButtonWidget(
                    onPressed: _isProcessing ? null : _exportUsers,
                    text: 'Export Existing Users',
                    icon: Icon(
                      Icons.file_download,
                      size: 20,
                    ),
                    options: FFButtonOptions(
                      height: 50,
                      padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                      iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                      color: Color(0xFF6D604A),
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                      elevation: 2,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  if (_isProcessing) ...[
                    SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4B986C),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Processing...',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(),
                                  color: Color(0xFF384E58),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_lastResult != null) ...[
                    SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lastResult!.hasErrors
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: _lastResult!.hasErrors
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Last Import Results',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.urbanist(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        color: Color(0xFF0B191E),
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildResultRow('Total Processed',
                                '${_lastResult!.totalProcessed}', Colors.blue),
                            _buildResultRow('Successful',
                                '${_lastResult!.successCount}', Colors.green),
                            _buildResultRow('Failed',
                                '${_lastResult!.failureCount}', Colors.red),
                            if (_lastResult!.hasErrors) ...[
                              SizedBox(height: 12),
                              Text(
                                'Errors:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              ..._lastResult!.errors
                                  .take(5)
                                  .map((error) => Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• ${error.toString()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      )),
                              if (_lastResult!.errors.length > 5)
                                Text(
                                  '... and ${_lastResult!.errors.length - 5} more errors',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red[600],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Color(0xFF384E58)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
