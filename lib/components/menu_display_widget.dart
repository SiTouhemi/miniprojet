import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/app_state.dart';

class MenuDisplayWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final String? mealTypeFilter;
  final bool showPrices;
  final VoidCallback? onRefresh;

  const MenuDisplayWidget({
    Key? key,
    this.selectedDate,
    this.mealTypeFilter,
    this.showPrices = true,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        final menus = _getFilteredMenus(appState.todaysMenu);

        if (appState.lastError != null) {
          return _buildErrorState(context, appState.lastError!);
        }

        if (menus.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildMenuList(context, menus);
      },
    );
  }

  List<DailyMenuRecord> _getFilteredMenus(List<DailyMenuRecord> allMenus) {
    var filteredMenus = allMenus;

    // Filter by meal type if specified
    if (mealTypeFilter != null && mealTypeFilter!.isNotEmpty && mealTypeFilter != 'Tous') {
      filteredMenus = filteredMenus
          .where((menu) => menu.mealType.toLowerCase() == mealTypeFilter!.toLowerCase())
          .toList();
    }

    return filteredMenus;
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64.0,
            color: Colors.red,
          ),
          SizedBox(height: 16.0),
          Text(
            'Error Loading Menu',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            error,
            style: FlutterFlowTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_meals,
            size: 64.0,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          SizedBox(height: 16.0),
          Text(
            'No Menu Available',
            style: FlutterFlowTheme.of(context).headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            mealTypeFilter != null && mealTypeFilter != 'Tous'
                ? 'No ${mealTypeFilter!.toLowerCase()} menu available for this date'
                : 'No menu available for this date',
            style: FlutterFlowTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, List<DailyMenuRecord> menus) {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(context, menu);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, DailyMenuRecord menu) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with meal type and availability
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _getMealTypeColor(menu.mealType).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getMealTypeIcon(menu.mealType),
                      color: _getMealTypeColor(menu.mealType),
                      size: 20.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      _getMealTypeDisplayName(menu.mealType),
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                        color: _getMealTypeColor(menu.mealType),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: menu.available ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    menu.available ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Menu content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main dish
                Text(
                  menu.mainDish,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                if (menu.description.isNotEmpty) ...[
                  SizedBox(height: 8.0),
                  Text(
                    menu.description,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ],
                
                // Accompaniments
                if (menu.accompaniments.isNotEmpty) ...[
                  SizedBox(height: 12.0),
                  Text(
                    'Accompaniments:',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: menu.accompaniments.map((accompaniment) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                        child: Text(
                          accompaniment,
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // Price
                if (showPrices) ...[
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price:',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${menu.price.toStringAsFixed(3)} TND',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'dinner':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealTypeDisplayName(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return mealType;
    }
  }
}