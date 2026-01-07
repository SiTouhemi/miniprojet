import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/role_middleware.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_management_model.dart';
export 'user_management_model.dart';

/// User Management Screen for ISETCOM Restaurant Reservation System
/// Allows admin to view all users, search, edit, reset passwords, and add money
class UserManagementWidget extends StatefulWidget {
  const UserManagementWidget({super.key});

  static String routeName = 'user_management';
  static String routePath = '/admin/users';

  @override
  State<UserManagementWidget> createState() => _UserManagementWidgetState();
}

class _UserManagementWidgetState extends State<UserManagementWidget> {
  late UserManagementModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserManagementModel());

    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    // Check admin permissions
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      await RoleMiddleware.requireRole(
          UserRole.admin, 'gestion des utilisateurs');
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
            'Gestion des Utilisateurs',
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
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
              child: FlutterFlowIconButton(
                borderRadius: 20.0,
                buttonSize: 40.0,
                fillColor: Color(0xFF6B7280),
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 20.0,
                ),
                onPressed: () async {
                  // Clear search and filters to refresh
                  _model.searchController?.clear();
                  _model.selectedRoleFilter = '';
                  setState(() {});

                  // Show refresh feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Liste des utilisateurs actualisée'),
                      backgroundColor: Color(0xFF4B986C),
                      duration: Duration(seconds: 2),
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
                fillColor: Color(0xFF4B986C),
                icon: Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20.0,
                ),
                onPressed: () async {
                  context.pushNamed('create_user');
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
            mainAxisSize: MainAxisSize.max,
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Color(0xFFC8D7E4),
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.search,
                          color: Color(0xFF384E58),
                          size: 24.0,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                12.0, 0.0, 0.0, 0.0),
                            child: TextFormField(
                              controller: _model.searchController,
                              focusNode: _model.searchFocusNode,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText:
                                    'Rechercher par nom, email, classe, rôle...',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      color: Color(0xFF6B7280),
                                    ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                          ),
                        ),
                        if (_model.searchController.text.isNotEmpty)
                          FlutterFlowIconButton(
                            borderRadius: 20.0,
                            buttonSize: 40.0,
                            icon: Icon(
                              Icons.clear,
                              color: Color(0xFF384E58),
                              size: 20.0,
                            ),
                            onPressed: () async {
                              _model.searchController?.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick stats
                    StreamBuilder<List<UserRecord>>(
                      stream: queryUserRecord(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox.shrink();

                        final allUsers = snapshot.data!;
                        final studentCount = allUsers
                            .where((u) => u.role.toLowerCase() == 'student')
                            .length;
                        final staffCount = allUsers
                            .where((u) => u.role.toLowerCase() == 'staff')
                            .length;
                        final adminCount = allUsers
                            .where((u) => u.role.toLowerCase() == 'admin')
                            .length;

                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                  'Total', allUsers.length, Color(0xFF6B7280)),
                              _buildStatItem(
                                  'Étudiants', studentCount, Color(0xFF4B986C)),
                              _buildStatItem(
                                  'Personnel', staffCount, Color(0xFF928163)),
                              _buildStatItem(
                                  'Admins', adminCount, Color(0xFFC4454D)),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.0),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tous', ''),
                          SizedBox(width: 8.0),
                          _buildFilterChip('Étudiants', 'student'),
                          SizedBox(width: 8.0),
                          _buildFilterChip('Personnel', 'staff'),
                          SizedBox(width: 8.0),
                          _buildFilterChip('Administrateurs', 'admin'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                  child: StreamBuilder<List<UserRecord>>(
                    stream: queryUserRecord(
                      queryBuilder: (userRecord) {
                        // Load all users without Firestore-level filtering
                        // We'll do client-side filtering for better search experience
                        return userRecord.orderBy('created_time',
                            descending: true);
                      },
                    ),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4B986C),
                              ),
                            ),
                          ),
                        );
                      }

                      List<UserRecord> users = snapshot.data!;

                      // Apply comprehensive client-side filtering
                      if (_model.searchController.text.isNotEmpty ||
                          _model.selectedRoleFilter.isNotEmpty) {
                        final searchText =
                            _model.searchController.text.toLowerCase().trim();
                        users = users.where((user) {
                          // Role filter
                          bool matchesRole =
                              _model.selectedRoleFilter.isEmpty ||
                                  user.role.toLowerCase() ==
                                      _model.selectedRoleFilter.toLowerCase();

                          // Text search filter
                          bool matchesSearch = true;
                          if (searchText.isNotEmpty) {
                            final name = (user.nom.isNotEmpty
                                    ? user.nom
                                    : user.displayName)
                                .toLowerCase();
                            final email = user.email.toLowerCase();
                            final classe = user.classe.toLowerCase();
                            final role = user.role.toLowerCase();

                            matchesSearch = name.contains(searchText) ||
                                email.contains(searchText) ||
                                classe.contains(searchText) ||
                                role.contains(searchText) ||
                                _getRoleDisplayName(user.role)
                                    .toLowerCase()
                                    .contains(searchText);
                          }

                          return matchesRole && matchesSearch;
                        }).toList();
                      }

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64.0,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                _model.searchController.text.isNotEmpty ||
                                        _model.selectedRoleFilter.isNotEmpty
                                    ? 'Aucun utilisateur trouvé pour les critères sélectionnés'
                                    : 'Aucun utilisateur trouvé',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      color: Color(0xFF6B7280),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              if (_model.searchController.text.isNotEmpty ||
                                  _model.selectedRoleFilter.isNotEmpty) ...[
                                SizedBox(height: 8.0),
                                Text(
                                  'Essayez de modifier vos critères de recherche',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        color: Color(0xFF6B7280),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results counter
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 16.0),
                            child: Text(
                              _model.searchController.text.isNotEmpty ||
                                      _model.selectedRoleFilter.isNotEmpty
                                  ? '${users.length} utilisateur${users.length > 1 ? 's' : ''} trouvé${users.length > 1 ? 's' : ''}'
                                  : '${users.length} utilisateur${users.length > 1 ? 's' : ''} au total',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          // Users list
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserRecord user) {
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
              color: Color(0xFFC8D7E4),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nom.isNotEmpty ? user.nom : user.displayName,
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: Color(0xFF0B191E),
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            user.email,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  color: Color(0xFF384E58),
                                  fontSize: 14.0,
                                ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    8.0, 4.0, 8.0, 4.0),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        color: Colors.white,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              if (user.classe.isNotEmpty) ...[
                                SizedBox(width: 8.0),
                                Container(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF928163),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    user.classe,
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          color: Colors.white,
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                              SizedBox(width: 8.0),
                              Container(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    8.0, 4.0, 8.0, 4.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6D604A),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  '${user.pocket.toStringAsFixed(2)} TND',
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        color: Colors.white,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FlutterFlowIconButton(
                      borderRadius: 20.0,
                      buttonSize: 40.0,
                      fillColor: Color(0xFF4B986C),
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      onPressed: () async {
                        await _showEditUserDialog(user);
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Color(0xFFC4454D);
      case 'staff':
        return Color(0xFF928163);
      case 'student':
      default:
        return Color(0xFF4B986C);
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'staff':
        return 'Personnel';
      case 'student':
      default:
        return 'Étudiant';
    }
  }

  Widget _buildFilterChip(String label, String roleFilter) {
    final isSelected = _model.selectedRoleFilter == roleFilter;
    return InkWell(
      onTap: () {
        setState(() {
          _model.selectedRoleFilter = isSelected ? '' : roleFilter;
        });
      },
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 12.0, 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4B986C) : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? Color(0xFF4B986C) : Color(0xFFC8D7E4),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: isSelected ? Colors.white : Color(0xFF384E58),
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                color: color,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 4.0),
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: Color(0xFF6B7280),
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Future<void> _showEditUserDialog(UserRecord user) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditUserDialog(user: user);
      },
    );
  }
}

/// Dialog for editing user information
class EditUserDialog extends StatefulWidget {
  final UserRecord user;

  const EditUserDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _classeController;
  late TextEditingController _addMoneyController;
  String _selectedRole = 'student';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.nom);
    _emailController = TextEditingController(text: widget.user.email);
    _classeController = TextEditingController(text: widget.user.classe);
    _addMoneyController = TextEditingController();
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _classeController.dispose();
    _addMoneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier Utilisateur',
        style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontWeight: FontWeight.bold,
            ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Email Field (read-only)
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email (non modifiable)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Class Field
            TextFormField(
              controller: _classeController,
              decoration: InputDecoration(
                labelText: 'Classe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'student', child: Text('Étudiant')),
                DropdownMenuItem(value: 'staff', child: Text('Personnel')),
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            SizedBox(height: 16.0),

            // Current Balance Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Solde actuel: ${widget.user.pocket.toStringAsFixed(2)} TND',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            SizedBox(height: 16.0),

            // Add Money Field
            TextFormField(
              controller: _addMoneyController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Ajouter de l\'argent (TND)',
                hintText: 'Ex: 25.50',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Reset Password Button
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  await _resetPassword();
                },
          child: Text(
            'Réinitialiser MDP',
            style: TextStyle(color: Color(0xFF928163)),
          ),
        ),

        // Cancel Button
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),

        // Save Button
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  await _saveChanges();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4B986C),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Sauvegarder'),
        ),
      ],
    );
  }

  Future<void> _resetPassword() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await authService.resetPassword(widget.user.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Email de réinitialisation envoyé à ${widget.user.email}'),
            backgroundColor: Color(0xFF4B986C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare update data
      Map<String, dynamic> updateData = {};

      if (_nameController.text != widget.user.nom) {
        updateData['nom'] = _nameController.text;
        updateData['display_name'] = _nameController.text;
      }

      if (_classeController.text != widget.user.classe) {
        updateData['classe'] = _classeController.text;
      }

      if (_selectedRole != widget.user.role) {
        updateData['role'] = _selectedRole;
        // Also update custom claims
        await authService.setUserRole(
            widget.user.uid, _parseUserRole(_selectedRole));
      }

      // Add money if specified
      if (_addMoneyController.text.isNotEmpty) {
        final addAmount = double.tryParse(_addMoneyController.text);
        if (addAmount != null && addAmount > 0) {
          updateData['pocket'] = widget.user.pocket + addAmount;
        }
      }

      // Update user document if there are changes
      if (updateData.isNotEmpty) {
        await widget.user.reference.update(updateData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur mis à jour avec succès'),
            backgroundColor: Color(0xFF4B986C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}
