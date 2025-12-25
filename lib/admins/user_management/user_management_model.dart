import '/flutter_flow/flutter_flow_util.dart';
import 'user_management_widget.dart' show UserManagementWidget;
import 'package:flutter/material.dart';

class UserManagementModel extends FlutterFlowModel<UserManagementWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for search widget.
  FocusNode? searchFocusNode;
  TextEditingController? searchController;
  String? Function(BuildContext, String?)? searchControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchFocusNode?.dispose();
    searchController?.dispose();
  }
}