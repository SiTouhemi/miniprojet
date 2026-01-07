import '/flutter_flow/flutter_flow_util.dart';
import 'reservation_list_widget.dart' show ReservationListWidget;
import 'package:flutter/material.dart';

class ReservationListModel extends FlutterFlowModel<ReservationListWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // Search state
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  // Filter state
  bool showActiveOnly = false;
  DateTime? selectedDate;

  /// Initialization and disposal methods.

  @override
  void initState(BuildContext context) {
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    searchController?.dispose();
    searchFocusNode?.dispose();
  }

  /// Action blocks are added here.
}
