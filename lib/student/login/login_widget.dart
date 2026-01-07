import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/l10n/app_localizations.dart';
import '/design_system/app_theme.dart';
import '/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_model.dart';
export 'login_model.dart';

/// Design a clean, modern, mobile-first Sign Up / Login page for the “ISETCOM
/// Restaurant Reservation System.” Use a minimalist academic style with the
/// color palette: primary #005BAA, accent #00A4E4, white background, soft
/// rounded corners, and subtle shadows.
///
/// The layout should show a centered authentication card with tabs or toggle
/// between “Login” and “Create Account.” For Login: email field, password
/// field, “Forgot Password,” and a blue Submit button. For Sign Up: full
/// name, email, password, confirm password, department or class dropdown, and
/// a Create Account button. Include the ISETCOM logo at the top, a bilingual
/// toggle (FR/EN), and a small footer note. Input fields must be clean,
/// spaced, and accessible. Buttons must be large, high contrast, and
/// consistent with the primary color. Overall style: modern academic UI,
/// Google Material-like, professional and friendly for students.
///
/// a login page , with a bottom of , no account ? sign up , in frensh
class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80.0,
                            height: 80.0,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppBorders.borderLG,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Padding(
                                    padding: AppSpacing.paddingSM,
                                    child: Text(
                                      'ISET',
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.textOnPrimary,
                                        fontWeight: AppTypography.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(0.0),
                                  child: Image.network(
                                    AppConfig.getNetworkImage('logo_fallback'),
                                    width: 480.84,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.school,
                                        size: AppIconSizes.xl,
                                        color: AppColors.textOnPrimary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: AppTypography.h4.copyWith(
                              color: AppColors.primary,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          Text(
                            l10n.systemName,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ].divide(AppSpacing.verticalMD),
                      ),
                      Padding(
                        padding: AppSpacing.paddingLG,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            boxShadow: AppShadows.large,
                            borderRadius: AppBorders.borderLG,
                          ),
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.translate('login'),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.h3.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                                Form(
                                  key: _model.formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      TextFormField(
                                        controller: _model.textController1,
                                        focusNode: _model.textFieldFocusNode1,
                                        autofocus: false,
                                        autofillHints: [AutofillHints.email],
                                        textInputAction: TextInputAction.next,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelText: l10n.translate('email'),
                                          labelStyle:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.primary,
                                          ),
                                          hintText: l10n
                                              .translate('email_placeholder'),
                                          hintStyle:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.border,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.surfaceVariant,
                                          contentPadding: AppInputSizes.padding,
                                        ),
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        cursorColor: AppColors.primary,
                                        validator: _model
                                            .textController1Validator
                                            .asValidator(context),
                                      ),
                                      TextFormField(
                                        controller: _model.textController2,
                                        focusNode: _model.textFieldFocusNode2,
                                        autofocus: false,
                                        autofillHints: [AutofillHints.password],
                                        textInputAction: TextInputAction.done,
                                        obscureText: !_model.passwordVisibility,
                                        decoration: InputDecoration(
                                          labelText: l10n.translate('password'),
                                          labelStyle:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.primary,
                                          ),
                                          hintText: l10n.translate(
                                              'password_placeholder'),
                                          hintStyle:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.border,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                              width: 1.0,
                                            ),
                                            borderRadius: AppBorders.borderMD,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.surfaceVariant,
                                          contentPadding: AppInputSizes.padding,
                                          suffixIcon: InkWell(
                                            onTap: () => safeSetState(
                                              () => _model.passwordVisibility =
                                                  !_model.passwordVisibility,
                                            ),
                                            focusNode:
                                                FocusNode(skipTraversal: true),
                                            child: Icon(
                                              _model.passwordVisibility
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: AppColors.textTertiary,
                                              size: AppIconSizes.md,
                                            ),
                                          ),
                                        ),
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        cursorColor: AppColors.primary,
                                        validator: _model
                                            .textController2Validator
                                            .asValidator(context),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              // Show forgot password dialog
                                              final emailController =
                                                  TextEditingController();
                                              final result =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text(l10n.translate(
                                                      'forgot_password_title')),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(l10n.translate(
                                                          'forgot_password_message')),
                                                      AppSpacing.verticalMD,
                                                      TextFormField(
                                                        controller:
                                                            emailController,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              l10n.translate(
                                                                  'email'),
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .emailAddress,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(false),
                                                      child: Text(l10n.cancel),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        try {
                                                          await authService
                                                              .resetPassword(
                                                                  emailController
                                                                      .text
                                                                      .trim());
                                                          Navigator.of(context)
                                                              .pop(true);
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(e
                                                                  .toString()
                                                                  .replaceFirst(
                                                                      'Exception: ',
                                                                      '')),
                                                              backgroundColor:
                                                                  AppColors
                                                                      .error,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Text(l10n
                                                          .translate('send')),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (result == true && mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(l10n.translate(
                                                        'reset_email_sent')),
                                                    backgroundColor:
                                                        AppColors.success,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              l10n.translate('forgot_password'),
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.secondary,
                                                fontWeight:
                                                    AppTypography.medium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ].divide(AppSpacing.verticalMD),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    // Validate form first
                                    if (_model.formKey.currentState == null ||
                                        !_model.formKey.currentState!
                                            .validate()) {
                                      return;
                                    }

                                    // Set loading state
                                    setState(() {
                                      _model.isLoading = true;
                                    });

                                    try {
                                      // Use AuthService for enhanced authentication
                                      final userCredential =
                                          await authService.signInWithEmail(
                                        _model.textController1.text.trim(),
                                        _model.textController2.text,
                                      );

                                      if (userCredential.user != null &&
                                          mounted) {
                                        // Get user role for proper navigation
                                        final userRole =
                                            await authService.getUserRole();

                                        // Navigate to role-appropriate home screen with enhanced error handling
                                        String targetRoute;
                                        String welcomeMessage;

                                        switch (userRole) {
                                          case UserRole.admin:
                                            targetRoute = 'admin_dashboard';
                                            welcomeMessage = l10n
                                                .translate('greeting', params: {
                                              'name': 'Administrateur'
                                            });
                                            break;
                                          case UserRole.staff:
                                            targetRoute = 'StaffHome';
                                            welcomeMessage = l10n.translate(
                                                'greeting',
                                                params: {'name': 'Personnel'});
                                            break;
                                          case UserRole.student:
                                            targetRoute = 'home';
                                            welcomeMessage = l10n.translate(
                                                'greeting',
                                                params: {'name': 'Étudiant'});
                                            break;
                                          case null:
                                            // Handle unknown role - this should not happen but we need to be safe
                                            throw Exception(
                                                'Rôle utilisateur non défini. Veuillez contacter l\'administrateur.');
                                          default:
                                            // Handle any unexpected role values
                                            throw Exception(
                                                'Rôle utilisateur non reconnu: ${userRole?.name ?? "inconnu"}. Veuillez contacter l\'administrateur.');
                                        }

                                        // Navigate to appropriate home screen
                                        context.goNamed(targetRoute);

                                        // Show success message with role-specific greeting
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              welcomeMessage,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textOnPrimary,
                                              ),
                                            ),
                                            backgroundColor: AppColors.success,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Show enhanced error message using AuthService's French messages
                                      if (mounted) {
                                        final errorMessage = e
                                            .toString()
                                            .replaceFirst('Exception: ', '');

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              errorMessage,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textOnPrimary,
                                              ),
                                            ),
                                            backgroundColor: AppColors.error,
                                            duration:
                                                const Duration(seconds: 4),
                                            action: SnackBarAction(
                                              label: l10n.retry,
                                              textColor:
                                                  AppColors.textOnPrimary,
                                              onPressed: () {
                                                // Clear password field and allow retry
                                                _model.textController2?.clear();
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      // Clear loading state
                                      if (mounted) {
                                        setState(() {
                                          _model.isLoading = false;
                                        });
                                      }
                                    }
                                  },
                                  text: _model.isLoading
                                      ? l10n.translate('signing_in')
                                      : l10n.translate('sign_in'),
                                  icon: _model.isLoading
                                      ? SizedBox(
                                          width: AppIconSizes.md,
                                          height: AppIconSizes.md,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.textOnPrimary),
                                          ),
                                        )
                                      : null,
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: AppButtonSizes.heightLarge,
                                    padding: AppButtonSizes.paddingLarge,
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: AppColors.primary,
                                    textStyle: AppTypography.button.copyWith(
                                      color: AppColors.textOnPrimary,
                                    ),
                                    elevation: 2.0,
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: AppBorders.borderMD,
                                  ),
                                ),
                              ].divide(AppSpacing.verticalLG),
                            ),
                          ),
                        ),
                      ),
                    ].divide(AppSpacing.verticalXL),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        l10n.translate('copyright'),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ].divide(AppSpacing.verticalMD),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
