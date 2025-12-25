import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/role_middleware.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      await RoleMiddleware.requireRole(UserRole.admin, 'gestion des utilisateurs');
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
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
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
                            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                            child: TextFormField(
                              controller: _model.searchController,
                              focusNode: _model.searchFocusNode,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Rechercher par nom, email, classe...',
                                hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
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
              
              // Users List
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                  child: StreamBuilder<List<UserRecord>>(
                    stream: queryUserRecord(
                      queryBuilder: (userRecord) {
                        Query query = userRecord;
                        
                        // Apply search filter if search text exists
                        if (_model.searchController.text.isNotEmpty) {
                          final searchText = _model.searchController.text.toLowerCase();
                          // Note: Firestore doesn't support case-insensitive search
                          // In production, you'd use Algolia or similar for better search
                          query = query.where('nom', isGreaterThanOrEqualTo: searchText);
                        }
                        
                        return query.orderBy('created_time', descending: true);
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
                      
                      // Apply client-side filtering for better search experience
                      if (_model.searchController.text.isNotEmpty) {
                        final searchText = _model.searchController.text.toLowerCase();
                        users = users.where((user) {
                          return user.nom.toLowerCase().contains(searchText) ||
                                 user.email.toLowerCase().contains(searchText) ||
                                 user.classe.toLowerCase().contains(searchText) ||
                                 user.role.toLowerCase().contains(searchText);
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
                                'Aucun utilisateur trouvé',
                                style: FlutterFlowTheme.of(context).headlineSmall.override(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserCard(user);
                        },
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
                            style: FlutterFlowTheme.of(context).titleMedium.override(
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
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Color(0xFF384E58),
                              fontSize: 14.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: FlutterFlowTheme.of(context).labelSmall.override(
                                    color: Colors.white,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (user.classe.isNotEmpty) ...[
                                SizedBox(width: 8.0),
                                Container(
                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF928163),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    user.classe,
                                    style: FlutterFlowTheme.of(context).labelSmall.override(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(width: 8.0),
                              Container(
                                padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6D604A),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  '${user.pocket.toStringAsFixed(2)} TND',
                                  style: FlutterFlowTheme.of(context).labelSmall.override(
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
          onPressed: _isLoading ? null : () async {
            await _resetPassword();
          },
          child: Text(
            'Réinitialiser MDP',
            style: TextStyle(color: Color(0xFF928163)),
          ),
        ),
        
        // Cancel Button
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        
        // Save Button
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
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
            content: Text('Email de réinitialisation envoyé à ${widget.user.email}'),
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
        await authService.setUserRole(widget.user.uid, _parseUserRole(_selectedRole));
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