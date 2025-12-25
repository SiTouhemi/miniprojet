import '/flutter_flow/flutter_flow_util.dart';
import 'daily_menu_management_widget.dart' show DailyMenuManagementWidget;
import 'package:flutter/material.dart';

class DailyMenuManagementModel extends FlutterFlowModel<DailyMenuManagementWidget> {
  // State field(s) for selected date
  DateTime selectedDate = DateTime.now();
  
  // State for selected meal type filter
  String selectedMealType = 'Tous';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
