import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController2Validator;

  // Loading state for better UX
  bool isLoading = false;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    
    // Enhanced email validation with better French messages
    textController1Validator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'L\'adresse e-mail est requise';
      }
      
      final trimmedVal = val.trim();
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedVal)) {
        return 'Veuillez entrer une adresse e-mail valide (ex: nom@isetcom.tn)';
      }
      
      return null;
    };
    
    // Enhanced password validation using AuthService standards
    textController2Validator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'Le mot de passe est requis';
      }
      
      // Use AuthService validation for consistency
      if (!authService.isPasswordStrong(val)) {
        return authService.getPasswordStrengthMessage(val);
      }
      
      return null;
    };
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();
  }
}
