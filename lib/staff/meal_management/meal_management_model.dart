import '/flutter_flow/flutter_flow_util.dart';
import 'meal_management_widget.dart' show MealManagementWidget;
import 'package:flutter/material.dart';

class MealManagementModel extends FlutterFlowModel<MealManagementWidget> {
  // State field(s) for search TextField
  FocusNode? searchFocusNode;
  TextEditingController? searchController;
  String? Function(BuildContext, String?)? searchControllerValidator;

  // State for selected category filter
  String selectedCategory = 'Tous';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchFocusNode?.dispose();
    searchController?.dispose();
  }
}
