import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import '/config/app_config.dart';
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
            content: Text(l10n.translate('profile_updated')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('profile_update_error')}: ${e.toString()}'),
          backgroundColor: AppColors.error,
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: true,
        title: Text(
          l10n.translate('profile_settings'),
          style: AppTypography.h4.copyWith(
            color: AppColors.textOnPrimary,
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
                      size: AppIconSizes.xxxl,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.verticalMD,
                    Text(
                      l10n.translate('login_to_view_profile'),
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalMD,
                    FFButtonWidget(
                      onPressed: () {
                        context.pushNamed('Login');
                      },
                      text: l10n.translate('go_to_login'),
                      options: FFButtonOptions(
                        height: AppButtonSizes.heightLarge,
                        padding: AppButtonSizes.paddingLarge,
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: AppColors.primary,
                        textStyle: AppTypography.button.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        elevation: 3.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: AppBorders.borderMD,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: AppSpacing.paddingMD,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        boxShadow: AppShadows.medium,
                        borderRadius: AppBorders.borderMD,
                      ),
                      child: Padding(
                        padding: AppSpacing.paddingMD,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 60.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.textOnPrimary,
                                size: AppIconSizes.xl,
                              ),
                            ),
                            AppSpacing.horizontalMD,
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName.isNotEmpty ? user.displayName : user.nom,
                                    style: AppTypography.h5.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (user.classe.isNotEmpty)
                                    Text(
                                      l10n.translate('class_label', params: {'class': user.classe}),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalLG,

                    // Balance Card Section
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: AppColors.balanceGradient,
                        borderRadius: AppBorders.borderLG,
                      ),
                      child: Padding(
                        padding: AppSpacing.paddingLG,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('current_balance'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            AppSpacing.verticalSM,
                            Text(
                              user != null 
                                ? AppConfig.formatPrice(user.pocket)
                                : AppConfig.formatPrice(0.0),
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            if (user != null)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  l10n.translate('tickets_available', params: {
                                    'count': user.tickets.toString()
                                  }),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalLG,

                    // Account Information Section
                    Text(
                      l10n.translate('account_information'),
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalMD,

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('full_name'),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintText: l10n.translate('enter_full_name'),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        prefixIcon: const Icon(Icons.person),
                        contentPadding: AppInputSizes.padding,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.translate('please_enter_name');
                        }
                        return null;
                      },
                    ),

                    AppSpacing.verticalMD,

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('email'),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintText: l10n.translate('enter_email'),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        prefixIcon: const Icon(Icons.email),
                        contentPadding: AppInputSizes.padding,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.translate('please_enter_email');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return l10n.translate('invalid_email');
                        }
                        return null;
                      },
                    ),

                    AppSpacing.verticalMD,

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('phone_number'),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintText: l10n.translate('enter_phone'),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        contentPadding: AppInputSizes.padding,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    AppSpacing.verticalMD,

                    // Class Field
                    TextFormField(
                      controller: _classController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('class'),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintText: l10n.translate('enter_class'),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        prefixIcon: const Icon(Icons.school),
                        contentPadding: AppInputSizes.padding,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    AppSpacing.verticalLG,

                    // Preferences Section
                    Text(
                      l10n.translate('preferences'),
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalMD,

                    // Language Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.translate('language'),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: AppBorders.borderMD,
                        ),
                        prefixIcon: const Icon(Icons.language),
                        contentPadding: AppInputSizes.padding,
                      ),
                      items: [
                        DropdownMenuItem(value: 'en', child: Text(l10n.translate('english'))),
                        DropdownMenuItem(value: 'fr', child: Text(l10n.translate('french'))),
                        DropdownMenuItem(value: 'ar', child: Text(l10n.translate('arabic'))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                    ),

                    AppSpacing.verticalMD,

                    // Notifications Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorders.borderMD,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2.0,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          l10n.translate('push_notifications'),
                          style: AppTypography.h6.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          l10n.translate('notification_subtitle'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),

                    AppSpacing.verticalXL,

                    // Update Button
                    FFButtonWidget(
                      onPressed: _isLoading ? null : _updateProfile,
                      text: _isLoading ? l10n.translate('updating') : l10n.translate('update_profile'),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: AppButtonSizes.heightLarge,
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: AppColors.primary,
                        textStyle: AppTypography.button.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        elevation: 3.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: AppBorders.borderMD,
                      ),
                    ),

                    AppSpacing.verticalMD,

                    // Logout Button
                    FFButtonWidget(
                      onPressed: () {
                        context.read<FFAppState>().logout();
                        context.goNamed('Login');
                      },
                      text: l10n.translate('logout'),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: AppButtonSizes.heightLarge,
                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: AppColors.surface,
                        textStyle: AppTypography.button.copyWith(
                          color: AppColors.error,
                        ),
                        elevation: 0.0,
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2.0,
                        ),
                        borderRadius: AppBorders.borderMD,
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