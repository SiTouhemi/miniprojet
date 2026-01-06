import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/user_record.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';

/// Service for importing and exporting users via Excel files
/// Ensures data consistency with UserRecord schema
class UserImportService {
  static UserImportService? _instance;
  static UserImportService get instance => _instance ??= UserImportService._();
  UserImportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = authService;

  /// Column headers matching UserRecord schema
  static const List<String> templateHeaders = [
    'email',
    'nom',
    'cin',
    'phone_number',
    'classe',
    'pocket',
    'tickets',
    'role',
    'password',
  ];

  /// Generate Excel template for user import
  Future<Uint8List> generateTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Users'];

      // Add headers
      for (int i = 0; i < templateHeaders.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(templateHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add example row with instructions
      final exampleData = [
        'student@example.com',
        'John Doe',
        '12345678',
        '+216 12 345 678',
        'DSI 2.1',
        '10.0',
        '5',
        'student',
        'Password123!',
      ];

      for (int i = 0; i < exampleData.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = TextCellValue(exampleData[i]);
        cell.cellStyle = CellStyle(
          italic: true,
          fontColorHex: ExcelColor.black,
        );
      }

      // Add instructions sheet
      final instructionsSheet = excel['Instructions'];
      final instructions = [
        ['Field', 'Description', 'Required', 'Format'],
        [
          'email',
          'User email address (must be unique)',
          'Yes',
          'email@example.com'
        ],
        ['nom', 'Full name of the user', 'Yes', 'Text'],
        ['cin', 'National ID number', 'Yes', 'Integer (8 digits)'],
        ['phone_number', 'Phone number', 'No', '+216 XX XXX XXX'],
        ['classe', 'Class/Section', 'No', 'Text (e.g., DSI 2.1)'],
        ['pocket', 'Initial balance in TND', 'No', 'Decimal (e.g., 10.0)'],
        ['tickets', 'Initial ticket count', 'No', 'Integer (e.g., 5)'],
        [
          'role',
          'User role',
          'Yes',
          'student, staff, or admin (default: student)'
        ],
        [
          'password',
          'Initial password (min 8 chars, 1 uppercase, 1 lowercase, 1 digit)',
          'Yes',
          'Text'
        ],
      ];

      for (int row = 0; row < instructions.length; row++) {
        for (int col = 0; col < instructions[row].length; col++) {
          final cell = instructionsSheet.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.value = TextCellValue(instructions[row][col]);
          if (row == 0) {
            cell.cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.green,
              fontColorHex: ExcelColor.white,
            );
          }
        }
      }

      // Set column widths (removed - not supported in excel 4.0.6)
      // Column widths will use default sizing

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      AppLogger.i('Excel template generated successfully',
          tag: 'UserImportService');
      return Uint8List.fromList(bytes);
    } catch (e) {
      AppLogger.e('Error generating Excel template',
          error: e, tag: 'UserImportService');
      rethrow;
    }
  }

  /// Import users from Excel file
  Future<ImportResult> importUsers(Uint8List fileBytes) async {
    final result = ImportResult();

    try {
      final excel = Excel.decodeBytes(fileBytes);
      final sheet = excel.tables['Users'];

      if (sheet == null) {
        throw Exception(
            'Sheet "Users" not found. Please use the provided template.');
      }

      // Validate headers
      final headers = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      if (!_validateHeaders(headers)) {
        throw Exception(
            'Invalid headers. Please use the provided template without modifying column names.');
      }

      // Process each row (skip header and example row)
      for (int i = 2; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // Skip empty rows
        if (_isEmptyRow(row)) {
          continue;
        }

        try {
          final userData = _parseUserRow(row, i + 1);
          await _createUser(userData);
          result.successCount++;
          result.successfulUsers.add(userData['email'] as String);
        } catch (e) {
          result.failureCount++;
          result.errors.add(ImportError(
            row: i + 1,
            message: e.toString(),
          ));
          AppLogger.w('Failed to import user at row ${i + 1}: $e',
              tag: 'UserImportService');
        }
      }

      AppLogger.i(
          'Import completed: ${result.successCount} success, ${result.failureCount} failures',
          tag: 'UserImportService');
    } catch (e) {
      AppLogger.e('Error importing users', error: e, tag: 'UserImportService');
      result.errors.add(ImportError(
        row: 0,
        message: 'Fatal error: ${e.toString()}',
      ));
    }

    return result;
  }

  /// Validate Excel headers match template
  bool _validateHeaders(List<String> headers) {
    if (headers.length < templateHeaders.length) {
      return false;
    }

    for (int i = 0; i < templateHeaders.length; i++) {
      if (headers[i].toLowerCase() != templateHeaders[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  /// Check if row is empty
  bool _isEmptyRow(List<Data?> row) {
    return row.every((cell) =>
        cell == null ||
        cell.value == null ||
        cell.value.toString().trim().isEmpty);
  }

  /// Parse user data from Excel row
  Map<String, dynamic> _parseUserRow(List<Data?> row, int rowNumber) {
    try {
      final email = _getCellValue(row, 0)?.trim();
      final nom = _getCellValue(row, 1)?.trim();
      final cinStr = _getCellValue(row, 2)?.trim();
      final phoneNumber = _getCellValue(row, 3)?.trim();
      final classe = _getCellValue(row, 4)?.trim();
      final pocketStr = _getCellValue(row, 5)?.trim();
      final ticketsStr = _getCellValue(row, 6)?.trim();
      final role = _getCellValue(row, 7)?.trim().toLowerCase();
      final password = _getCellValue(row, 8)?.trim();

      // Validate required fields
      if (email == null || email.isEmpty) {
        throw Exception('Email is required');
      }
      if (nom == null || nom.isEmpty) {
        throw Exception('Name (nom) is required');
      }
      if (cinStr == null || cinStr.isEmpty) {
        throw Exception('CIN is required');
      }
      if (password == null || password.isEmpty) {
        throw Exception('Password is required');
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format: $email');
      }

      // Parse and validate CIN
      final cin = int.tryParse(cinStr);
      if (cin == null) {
        throw Exception('CIN must be a valid integer');
      }

      // Parse pocket (default 0.0)
      final pocket = double.tryParse(pocketStr ?? '0') ?? 0.0;

      // Parse tickets (default 0)
      final tickets = int.tryParse(ticketsStr ?? '0') ?? 0;

      // Validate role
      final validRoles = ['student', 'staff', 'admin'];
      final userRole = role ?? 'student';
      if (!validRoles.contains(userRole)) {
        throw Exception(
            'Invalid role: $userRole. Must be one of: ${validRoles.join(", ")}');
      }

      // Validate password strength
      if (!_isPasswordStrong(password)) {
        throw Exception(
            'Password must be at least 8 characters with 1 uppercase, 1 lowercase, and 1 digit');
      }

      return {
        'email': email,
        'nom': nom,
        'cin': cin,
        'phone_number': phoneNumber ?? '',
        'classe': classe ?? '',
        'pocket': pocket,
        'tickets': tickets,
        'role': userRole,
        'password': password,
      };
    } catch (e) {
      throw Exception('Row $rowNumber: ${e.toString()}');
    }
  }

  /// Get cell value as string
  String? _getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null || cell.value == null) return null;
    return cell.value.toString();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Create user in Firebase Auth and Firestore
  Future<void> _createUser(Map<String, dynamic> userData) async {
    final email = userData['email'] as String;
    final password = userData['password'] as String;
    final role = userData['role'] as String;

    // Check if user already exists
    final existingUsers = await _firestore
        .collection('user')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (existingUsers.docs.isNotEmpty) {
      throw Exception('User with email $email already exists');
    }

    // Create user with role using AuthService
    final userRole = role == 'admin'
        ? UserRole.admin
        : role == 'staff'
            ? UserRole.staff
            : UserRole.student;

    await _authService.createUserWithRole(
      email: email,
      password: password,
      displayName: userData['nom'] as String,
      role: userRole,
      cin: userData['cin'].toString(),
      classe: userData['classe'] as String?,
      phoneNumber: userData['phone_number'] as String?,
    );

    // Update additional fields that aren't in createUserWithRole
    final userQuery = await _firestore
        .collection('user')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      await userQuery.docs.first.reference.update({
        'pocket': userData['pocket'],
        'tickets': userData['tickets'],
      });
    }
  }

  /// Export existing users to Excel
  Future<Uint8List> exportUsers() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Users'];

      // Add headers
      for (int i = 0; i < templateHeaders.length - 1; i++) {
        // Exclude password
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(templateHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Fetch all users
      final usersSnapshot = await _firestore.collection('user').get();
      int rowIndex = 1;

      for (final doc in usersSnapshot.docs) {
        final user = UserRecord.fromSnapshot(doc);

        final rowData = [
          user.email,
          user.nom,
          user.cin.toString(),
          user.phoneNumber,
          user.classe,
          user.pocket.toString(),
          user.tickets.toString(),
          user.role,
        ];

        for (int i = 0; i < rowData.length; i++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          cell.value = TextCellValue(rowData[i]);
        }

        rowIndex++;
      }

      // Column widths will use default sizing

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      AppLogger.i('Exported ${usersSnapshot.docs.length} users to Excel',
          tag: 'UserImportService');
      return Uint8List.fromList(bytes);
    } catch (e) {
      AppLogger.e('Error exporting users', error: e, tag: 'UserImportService');
      rethrow;
    }
  }
}

/// Result of import operation
class ImportResult {
  int successCount = 0;
  int failureCount = 0;
  List<String> successfulUsers = [];
  List<ImportError> errors = [];

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => successCount + failureCount;
}

/// Error details for failed import
class ImportError {
  final int row;
  final String message;

  ImportError({required this.row, required this.message});

  @override
  String toString() => 'Row $row: $message';
}
