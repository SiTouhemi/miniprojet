import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/flutter_flow/app_state.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static const String routeName = 'Profile';
  static const String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _classController;
  
  String? _selectedLanguage;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<FFAppState>().currentUser;
    
    _nameController = TextEditingController(text: user?.displayName ?? user?.nom ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _classController = TextEditingController(text: user?.classe ?? '');
    _selectedLanguage = user?.language ?? 'en';
    _notificationsEnabled = user?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<FFAppState>().currentUser;
      if (user != null) {
        await user.reference.update({
          'display_name': _nameController.text.trim(),
          'nom': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'classe': _classController.text.trim(),
          'language': _selectedLanguage,
          'notifications_enabled': _notificationsEnabled,
          'last_login': FieldValue.serverTimestamp(),
        });

        // Update app state language
        context.read<FFAppState>().setLanguage(_selectedLanguage!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Profile Settings',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 22.0,
              ),
        ),
        centerTitle: false,
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: Consumer<FFAppState>(
          builder: (context, appState, _) {
            final user = appState.currentUser;
            
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 64.0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Please log in to view your profile',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    SizedBox(height: 16.0),
                    FFButtonWidget(
                      onPressed: () {
                        context.pushNamed('Login');
                      },
                      text: 'Go to Login',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Readex Pro',
                              color: Colors.white,
                            ),
                        elevation: 3.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3.0,
                            color: Color(0x33000000),
                            offset: Offset(0.0, 1.0),
                          )
                        ],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 60.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName.isNotEmpty ? user.displayName : user.nom,
                                    style: FlutterFlowTheme.of(context).headlineSmall,
                                  ),
                                  Text(
                                    user.email,
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                  if (user.classe.isNotEmpty)
                                    Text(
                                      'Class: ${user.classe}',
                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'Readex Pro',
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24.0),

                    // Account Information Section
                    Text(
                      'Account Information',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    SizedBox(height: 16.0),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        hintText: 'Enter your full name',
                        hintStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.0),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        hintText: 'Enter your email',
                        hintStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.0),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        hintText: 'Enter your phone number',
                        hintStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                      keyboardType: TextInputType.phone,
                    ),

                    SizedBox(height: 16.0),

                    // Class Field
                    TextFormField(
                      controller: _classController,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        hintText: 'Enter your class (e.g., L3 INFO)',
                        hintStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.school),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),

                    SizedBox(height: 24.0),

                    // Preferences Section
                    Text(
                      'Preferences',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    SizedBox(height: 16.0),

                    // Language Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: 'Language',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                    ),

                    SizedBox(height: 16.0),

                    // Notifications Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 2.0,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Push Notifications',
                          style: FlutterFlowTheme.of(context).titleLarge,
                        ),
                        subtitle: Text(
                          'Receive reminders about your reservations',
                          style: FlutterFlowTheme.of(context).labelMedium,
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: FlutterFlowTheme.of(context).primary,
                      ),
                    ),

                    SizedBox(height: 32.0),

                    // Update Button
                    FFButtonWidget(
                      onPressed: _isLoading ? null : _updateProfile,
                      text: _isLoading ? 'Updating...' : 'Update Profile',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50.0,
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Readex Pro',
                              color: Colors.white,
                            ),
                        elevation: 3.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),

                    SizedBox(height: 16.0),

                    // Logout Button
                    FFButtonWidget(
                      onPressed: () {
                        context.read<FFAppState>().logout();
                        context.goNamed('Login');
                      },
                      text: 'Logout',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50.0,
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Readex Pro',
                              color: FlutterFlowTheme.of(context).error,
                            ),
                        elevation: 0.0,
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).error,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}