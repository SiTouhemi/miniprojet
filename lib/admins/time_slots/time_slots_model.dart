import '/flutter_flow/flutter_flow_util.dart';
import 'time_slots_widget.dart' show TimeSlotsWidget;
import 'package:flutter/material.dart';

class TimeSlotsModel extends FlutterFlowModel<TimeSlotsWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  
  /// Initialization and disposal methods.

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Action blocks are added here.
}
