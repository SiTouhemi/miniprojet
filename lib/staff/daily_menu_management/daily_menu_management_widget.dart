import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'daily_menu_management_model.dart';
export 'daily_menu_management_model.dart';

class DailyMenuManagementWidget extends StatefulWidget {
  const DailyMenuManagementWidget({super.key});

  static String routeName = 'DailyMenuManagement';
  static String routePath = '/dailyMenuManagement';

  @override
  State<DailyMenuManagementWidget> createState() =>
      _DailyMenuManagementWidgetState();
}

class _DailyMenuManagementWidgetState extends State<DailyMenuManagementWidget> {
  late DailyMenuManagementModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DailyMenuManagementModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle back gesture/button for web
          try {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/staffHome');
            }
          } catch (e) {
            print('Navigation error in PopScope: $e');
            context.go('/staffHome');
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Color(0xFFF8F9FA), // Light grey-white background
          appBar: AppBar(
            backgroundColor: Color(0xFF1C1284),
            automaticallyImplyLeading: false,
            leading: FlutterFlowIconButton(
              borderRadius: 20.0,
              buttonSize: 40.0,
              fillColor: Colors.transparent,
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
              onPressed: () {
                // Enhanced navigation handling for web compatibility
                try {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Fallback navigation to staff home
                    context.go('/staffHome');
                  }
                } catch (e) {
                  // Emergency fallback if navigation fails
                  print('Navigation error: $e');
                  context.go('/staffHome');
                }
              },
            ),
            title: Text(
              'Weekly Menus',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Inter Tight',
                    color: Colors.white,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            actions: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                child: FlutterFlowIconButton(
                  borderRadius: 20.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFF00A4E4),
                  icon: Icon(Icons.add, color: Colors.white, size: 24.0),
                  onPressed: () => _showAddDailyMenuDialog(context),
                ),
              ),
            ],
            centerTitle: false,
            elevation: 2.0,
          ),
          body: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Date selector and filters
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(0.0, 2.0),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Week navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left,
                                  color: Color(0xFF1C1284)),
                              onPressed: () {
                                setState(() {
                                  _model.selectedDate = _model.selectedDate
                                      .subtract(Duration(days: 7));
                                });
                              },
                            ),
                            Text(
                              'Week of ${DateFormat('dd/MM').format(_getWeekStart(_model.selectedDate))}',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right,
                                  color: Color(0xFF1C1284)),
                              onPressed: () {
                                setState(() {
                                  _model.selectedDate = _model.selectedDate
                                      .add(Duration(days: 7));
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        // Meal type filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildMealTypeChip('All'),
                              SizedBox(width: 8.0),
                              _buildMealTypeChip('lunch'),
                              SizedBox(width: 8.0),
                              _buildMealTypeChip('dinner'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Daily menus list - Weekly Grid View
                Expanded(
                  child: StreamBuilder<List<DailyMenuRecord>>(
                    stream: queryDailyMenuRecord(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1C1284)),
                          ),
                        );
                      }
                      final allMenus = snapshot.data ?? [];

                      // Sort menus by day and meal type in code
                      allMenus.sort((a, b) {
                        final dayComparison =
                            a.dayOfWeek.compareTo(b.dayOfWeek);
                        if (dayComparison != 0) return dayComparison;
                        return a.mealType.compareTo(b.mealType);
                      });

                      // Group menus by day and meal type
                      final menusByDay = <int, Map<String, DailyMenuRecord>>{};
                      for (final menu in allMenus) {
                        if (!menusByDay.containsKey(menu.dayOfWeek)) {
                          menusByDay[menu.dayOfWeek] = {};
                        }
                        menusByDay[menu.dayOfWeek]![menu.mealType] = menu;
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Weekly Overview Header
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1C1284),
                                    Color(0xFF00A4E4)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                'Weekly Menu Overview',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: 'Inter Tight',
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20.0),
                            // Days of the week (Monday to Saturday)
                            ...List.generate(6, (index) {
                              final dayOfWeek =
                                  index + 1; // 1=Monday, 6=Saturday
                              final dayMenus = menusByDay[dayOfWeek] ?? {};
                              final lunchMenu = dayMenus['lunch'];
                              final dinnerMenu = dayMenus['dinner'];

                              // Apply meal type filter
                              final showLunch =
                                  _model.selectedMealType == 'All' ||
                                      _model.selectedMealType == 'lunch';
                              final showDinner =
                                  _model.selectedMealType == 'All' ||
                                      _model.selectedMealType == 'dinner';

                              if (!showLunch && !showDinner)
                                return SizedBox.shrink();

                              return _buildDayCard(context, dayOfWeek,
                                  lunchMenu, dinnerMenu, showLunch, showDinner);
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildMealTypeChip(String mealType) {
    final isSelected = _model.selectedMealType == mealType;
    final displayName = mealType == 'All'
        ? 'All'
        : mealType == 'lunch'
            ? 'Lunch'
            : 'Dinner';
    return FilterChip(
      label: Text(displayName),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _model.selectedMealType = mealType;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF1C1284),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF1C1284),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: Color(0xFF1C1284), width: 1.0),
    );
  }

  Widget _buildDayCard(
      BuildContext context,
      int dayOfWeek,
      DailyMenuRecord? lunchMenu,
      DailyMenuRecord? dinnerMenu,
      bool showLunch,
      bool showDinner) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 8.0,
            color: Color(0x1A000000),
            offset: Offset(0.0, 4.0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1284), Color(0xFF2E3192)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDayName(dayOfWeek),
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Inter Tight',
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Day ${dayOfWeek}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Meals Content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Lunch Section
                if (showLunch) ...[
                  _buildMealSection(context, 'Lunch', lunchMenu, Icons.wb_sunny,
                      Color(0xFF00A4E4)),
                  if (showDinner && dinnerMenu != null) SizedBox(height: 20.0),
                ],
                // Dinner Section
                if (showDinner) ...[
                  _buildMealSection(context, 'Dinner', dinnerMenu,
                      Icons.nights_stay, Color(0xFFFF9800)),
                ],
                // No meals message
                if ((!showLunch || lunchMenu == null) &&
                    (!showDinner || dinnerMenu == null)) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 48.0, color: Colors.grey),
                        SizedBox(height: 8.0),
                        Text(
                          'No menus available for this day',
                          style:
                              FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Inter',
                                    color: Colors.grey[600],
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.0),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDailyMenuDialog(context,
                              preselectedDay: dayOfWeek,
                              preselectedMealType: 'lunch'),
                          icon: Icon(Icons.add, size: 18.0),
                          label: Text('Add Menu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1C1284),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String mealType,
      DailyMenuRecord? menu, IconData icon, Color accentColor) {
    if (menu == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 24.0),
                SizedBox(width: 12.0),
                Text(
                  mealType,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter Tight',
                        color: accentColor,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            Text(
              'No ${mealType.toLowerCase()} menu available',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    letterSpacing: 0.0,
                  ),
            ),
            SizedBox(height: 8.0),
            ElevatedButton.icon(
              onPressed: () => _showAddDailyMenuDialog(context,
                  preselectedMealType: mealType.toLowerCase()),
              icon: Icon(Icons.add, size: 16.0),
              label: Text('Add ${mealType}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                textStyle: TextStyle(fontSize: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 4.0,
            color: accentColor.withOpacity(0.1),
            offset: Offset(0.0, 2.0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(icon, color: accentColor, size: 20.0),
                  ),
                  SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealType,
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Inter Tight',
                                  color: accentColor,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: menu.available
                              ? Color(0xFFE8F5E9)
                              : Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          menu.available ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: menu.available
                                ? Color(0xFF2E7D32)
                                : Color(0xFFC62828),
                            fontWeight: FontWeight.w600,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility,
                        color: Color(0xFF1C1284), size: 20.0),
                    onPressed: () => _showMenuDetailsDialog(context, menu),
                    padding: EdgeInsets.all(4.0),
                    constraints:
                        BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.edit, color: Color(0xFF1C1284), size: 20.0),
                    onPressed: () => _showEditMenuDialog(context, menu),
                    padding: EdgeInsets.all(4.0),
                    constraints:
                        BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20.0),
                    onPressed: () => _showDeleteConfirmation(context, menu),
                    padding: EdgeInsets.all(4.0),
                    constraints:
                        BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.0),
          Divider(color: accentColor.withOpacity(0.2)),
          SizedBox(height: 8.0),
          // Debug info - remove this later
          if (menu.mainDish.isEmpty &&
              menu.salad.isEmpty &&
              menu.dessert.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Debug Info:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange[800]),
                  ),
                  Text('Main dish: "${menu.mainDish}"'),
                  Text('Salad: "${menu.salad}"'),
                  Text('Dessert: "${menu.dessert}"'),
                  Text('Description: "${menu.description}"'),
                  Text(
                      'This menu was likely created with the old system. Please edit and re-save it.'),
                ],
              ),
            ),
            SizedBox(height: 8.0),
          ],
          // Menu Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Course
              if (menu.mainDish.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.restaurant,
                        size: 16.0, color: Color(0xFF1C1284)),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        menu.mainDish,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
              ],
              // Salad
              if (menu.salad.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.eco, size: 16.0, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        menu.salad,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
              ],
              // Dessert
              if (menu.dessert.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.cake, size: 16.0, color: Color(0xFFFF9800)),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        menu.dessert,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
              ],
              // Price - Hidden for staff view
              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [
              //         accentColor.withOpacity(0.1),
              //         accentColor.withOpacity(0.05)
              //       ],
              //       begin: Alignment.centerLeft,
              //       end: Alignment.centerRight,
              //     ),
              //     borderRadius: BorderRadius.circular(8.0),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(Icons.attach_money, color: accentColor, size: 18.0),
              //       Text(
              //         '${menu.price.toStringAsFixed(2)} DT',
              //         style: FlutterFlowTheme.of(context).titleMedium.override(
              //               fontFamily: 'Inter Tight',
              //               color: accentColor,
              //               letterSpacing: 0.0,
              //               fontWeight: FontWeight.bold,
              //             ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  // Unused method - kept for potential future use
  // ignore: unused_element
  Widget _buildMenuCard(BuildContext context, DailyMenuRecord menu) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      color: Colors.white, // Force white background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _showMenuDetailsDialog(context, menu),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDayName(menu.dayOfWeek),
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Inter Tight',
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: 4.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: menu.mealType == 'lunch'
                                ? Color(0xFFE3F2FD)
                                : Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            menu.mealType == 'lunch' ? 'Lunch' : 'Dinner',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      color: menu.mealType == 'lunch'
                                          ? Color(0xFF1976D2)
                                          : Color(0xFFF57C00),
                                      letterSpacing: 0.0,
                                      fontSize: 11.0,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF1C1284)),
                        onPressed: () => _showEditMenuDialog(context, menu),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, menu),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 24.0),
              // Complete Menu Composition
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Course
                  Row(
                    children: [
                      Icon(Icons.restaurant,
                          size: 16.0, color: Color(0xFF1C1284)),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Main: ${menu.mainDish}',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.0),
                  // Salad
                  if (menu.salad.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.eco, size: 16.0, color: Color(0xFF4CAF50)),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Salad: ${menu.salad}',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.0),
                  ],
                  // Dessert
                  if (menu.dessert.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.cake, size: 16.0, color: Color(0xFFFF9800)),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Dessert: ${menu.dessert}',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.0),
                  ],
                  // Accompaniment
                  if (menu.accompaniment.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.grain, size: 16.0, color: Color(0xFF795548)),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Side: ${menu.accompaniment}',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (menu.accompaniments.isNotEmpty) ...[
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: menu.accompaniments
                      .map((acc) => Chip(
                            label: Text(acc, style: TextStyle(fontSize: 12.0)),
                            backgroundColor: Color(0xFFF8F9FA), // Light grey
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                          ))
                      .toList(),
                ),
              ],
              if (menu.description.isNotEmpty) ...[
                SizedBox(height: 8.0),
                Text(
                  menu.description,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price - Hidden for staff view
                  // Text(
                  //   '${menu.price.toStringAsFixed(2)} DT',
                  //   style: FlutterFlowTheme.of(context).titleSmall.override(
                  //         fontFamily: 'Inter Tight',
                  //         color: Color(0xFF00A4E4),
                  //         letterSpacing: 0.0,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  // ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: menu.available
                          ? Color(0xFFE8F5E9)
                          : Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      menu.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: menu.available
                            ? Color(0xFF2E7D32)
                            : Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDailyMenuDialog(BuildContext context,
      {int? preselectedDay, String? preselectedMealType}) {
    final descriptionController = TextEditingController();
    String? selectedMainDishId;
    String? selectedSaladId;
    String? selectedDessertId;
    final List<String> selectedAccompanimentIds = [];
    double totalPrice = 0.0;
    DateTime selectedDate = preselectedDay != null
        ? _getDateFromDayOfWeek(preselectedDay)
        : DateTime.now();
    String selectedMealType = preselectedMealType ?? 'lunch';
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      value: selectedMealType,
                      decoration: InputDecoration(
                        labelText: 'Meal Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(
                            value: 'dinner', child: Text('Dinner')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMealType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.0),
                    // Main Dish Dropdown
                    StreamBuilder<List<PlatRecord>>(
                      stream: queryPlatRecord(
                        queryBuilder: (query) =>
                            query.where('categorie', isEqualTo: 'Main Course'),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        final mainDishes = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedMainDishId,
                          decoration: InputDecoration(
                            labelText: 'Main Dish *',
                            border: OutlineInputBorder(),
                            helperText: 'Select from available dishes',
                          ),
                          items: mainDishes.map((dish) {
                            return DropdownMenuItem(
                              value: dish.reference.id,
                              child: Text(dish.nom),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMainDishId = value;
                              // Recalculate total price
                              totalPrice = 0.0;
                              if (selectedMainDishId != null) {
                                final dish = mainDishes.firstWhere((d) =>
                                    d.reference.id == selectedMainDishId);
                                totalPrice += dish.prix;
                              }
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12.0),
                    // Salad Dropdown
                    StreamBuilder<List<PlatRecord>>(
                      stream: queryPlatRecord(
                        queryBuilder: (query) =>
                            query.where('categorie', isEqualTo: 'Appetizer'),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        }
                        final salads = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedSaladId,
                          decoration: InputDecoration(
                            labelText: 'Salad (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: null, child: Text('None')),
                            ...salads.map((dish) {
                              return DropdownMenuItem(
                                value: dish.reference.id,
                                child: Text(dish.nom),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedSaladId = value;
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12.0),
                    // Dessert Dropdown
                    StreamBuilder<List<PlatRecord>>(
                      stream: queryPlatRecord(
                        queryBuilder: (query) =>
                            query.where('categorie', isEqualTo: 'Dessert'),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        }
                        final desserts = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedDessertId,
                          decoration: InputDecoration(
                            labelText: 'Dessert (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: null, child: Text('None')),
                            ...desserts.map((dish) {
                              return DropdownMenuItem(
                                value: dish.reference.id,
                                child: Text(dish.nom),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDessertId = value;
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12.0),
                    // Accompaniment Dropdown (Single Select)
                    StreamBuilder<List<PlatRecord>>(
                      stream: queryPlatRecord(
                        queryBuilder: (query) => query.where('categorie',
                            whereIn: [
                              'Side Dish',
                              'Accompaniment',
                              'Side',
                              'Bread'
                            ]),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        }
                        final sideDishes = snapshot.data ?? [];
                        if (sideDishes.isEmpty) {
                          return SizedBox.shrink();
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedAccompanimentIds.isNotEmpty
                              ? selectedAccompanimentIds.first
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Accompaniment (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: null, child: Text('None')),
                            ...sideDishes.map((dish) {
                              return DropdownMenuItem(
                                value: dish.reference.id,
                                child: Text(dish.nom),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAccompanimentIds.clear();
                              if (value != null) {
                                selectedAccompanimentIds.add(value);
                              }
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        helperText: 'Additional notes about today\'s menu',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12.0),
                    // Display calculated price - Hidden for staff view
                    // Container(
                    //   padding: EdgeInsets.all(12.0),
                    //   decoration: BoxDecoration(
                    //     color: Color(0xFFF0F8FF),
                    //     borderRadius: BorderRadius.circular(8.0),
                    //     border: Border.all(color: Color(0xFF1C1284)),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text(
                    //         'Menu Price:',
                    //         style: TextStyle(fontWeight: FontWeight.bold),
                    //       ),
                    //       Text(
                    //         '${totalPrice.toStringAsFixed(2)} DT',
                    //         style: TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           fontSize: 18.0,
                    //           color: Color(0xFF1C1284),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: 24.0),
                    SwitchListTile(
                      title: Text('Available'),
                      value: isAvailable,
                      onChanged: (value) {
                        setDialogState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMainDishId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a main dish'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      // Fetch the selected dishes to get their names
                      final mainDishDoc = await PlatRecord.collection
                          .doc(selectedMainDishId)
                          .get();
                      final mainDish = PlatRecord.fromSnapshot(mainDishDoc);

                      String saladName = '';
                      if (selectedSaladId != null) {
                        final saladDoc = await PlatRecord.collection
                            .doc(selectedSaladId)
                            .get();
                        final salad = PlatRecord.fromSnapshot(saladDoc);
                        saladName = salad.nom;
                      }

                      String dessertName = '';
                      if (selectedDessertId != null) {
                        final dessertDoc = await PlatRecord.collection
                            .doc(selectedDessertId)
                            .get();
                        final dessert = PlatRecord.fromSnapshot(dessertDoc);
                        dessertName = dessert.nom;
                      }

                      // Calculate total price and get accompaniment names
                      double menuPrice = mainDish.prix;
                      List<String> accompanimentNames = [];

                      if (selectedSaladId != null) {
                        final saladDoc = await PlatRecord.collection
                            .doc(selectedSaladId)
                            .get();
                        menuPrice += PlatRecord.fromSnapshot(saladDoc).prix;
                      }
                      if (selectedDessertId != null) {
                        final dessertDoc = await PlatRecord.collection
                            .doc(selectedDessertId)
                            .get();
                        menuPrice += PlatRecord.fromSnapshot(dessertDoc).prix;
                      }

                      // Add accompaniment to price and get name (single selection)
                      if (selectedAccompanimentIds.isNotEmpty) {
                        final accompanimentDoc = await PlatRecord.collection
                            .doc(selectedAccompanimentIds.first)
                            .get();
                        final accompaniment =
                            PlatRecord.fromSnapshot(accompanimentDoc);
                        menuPrice += accompaniment.prix;
                        accompanimentNames.add(accompaniment.nom);
                      }

                      await DailyMenuRecord.collection.add({
                        'day_of_week': selectedDate.weekday,
                        'meal_type': selectedMealType,
                        'main_dish': mainDish.nom,
                        'main_dish_ref': selectedMainDishId,
                        'salad': saladName,
                        'salad_ref': selectedSaladId ?? '',
                        'dessert': dessertName,
                        'dessert_ref': selectedDessertId ?? '',
                        'accompaniment': '',
                        'accompaniments': accompanimentNames,
                        'description': descriptionController.text,
                        'price': menuPrice,
                        'available': isAvailable,
                        'created_by': currentUser?.uid ?? '',
                        'created_at': DateTime.now(),
                      });
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menu added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1C1284)),
                  child: Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMenuDialog(BuildContext context, DailyMenuRecord menu) {
    final descriptionController = TextEditingController(text: menu.description);
    String? selectedMainDishId;
    String? selectedSaladId;
    String? selectedDessertId;
    final List<String> selectedAccompanimentIds = [];
    DateTime selectedDate = _getDateFromDayOfWeek(menu.dayOfWeek);
    String selectedMealType = menu.mealType;
    bool isAvailable = menu.available;

    // Function to find dish ID by name
    Future<String?> findDishIdByName(String dishName, String category) async {
      if (dishName.isEmpty) return null;
      try {
        final querySnapshot = await PlatRecord.collection
            .where('nom', isEqualTo: dishName)
            .where('categorie', isEqualTo: category)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.id;
        }
      } catch (e) {
        print('Error finding dish ID: $e');
      }
      return null;
    }

    // Initialize selected IDs based on current menu
    Future<void> initializeSelectedDishes() async {
      if (menu.mainDish.isNotEmpty) {
        selectedMainDishId =
            await findDishIdByName(menu.mainDish, 'Main Course');
      }
      if (menu.salad.isNotEmpty) {
        selectedSaladId = await findDishIdByName(menu.salad, 'Appetizer');
      }
      if (menu.dessert.isNotEmpty) {
        selectedDessertId = await findDishIdByName(menu.dessert, 'Dessert');
      }

      // Initialize accompaniments (single selection)
      if (menu.accompaniments.isNotEmpty) {
        final accompanimentId =
            await findDishIdByName(menu.accompaniments.first, 'Side Dish');
        if (accompanimentId != null) {
          selectedAccompanimentIds.add(accompanimentId);
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<void>(
          future: initializeSelectedDishes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Loading...'),
                content: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text('Edit Menu'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 365)),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          value: selectedMealType,
                          decoration: InputDecoration(
                            labelText: 'Meal Type *',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'lunch', child: Text('Lunch')),
                            DropdownMenuItem(
                                value: 'dinner', child: Text('Dinner')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMealType = value!;
                            });
                          },
                        ),
                        SizedBox(height: 12.0),
                        // Main Dish Dropdown
                        StreamBuilder<List<PlatRecord>>(
                          stream: queryPlatRecord(
                            queryBuilder: (query) => query.where('categorie',
                                isEqualTo: 'Main Course'),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return CircularProgressIndicator();
                            }
                            final mainDishes = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: selectedMainDishId,
                              decoration: InputDecoration(
                                labelText: 'Main Dish *',
                                border: OutlineInputBorder(),
                                helperText: 'Current: ${menu.mainDish}',
                              ),
                              items: mainDishes.map((dish) {
                                return DropdownMenuItem(
                                  value: dish.reference.id,
                                  child: Text(dish.nom),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedMainDishId = value;
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: 12.0),
                        // Salad Dropdown
                        StreamBuilder<List<PlatRecord>>(
                          stream: queryPlatRecord(
                            queryBuilder: (query) => query.where('categorie',
                                isEqualTo: 'Appetizer'),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox.shrink();
                            }
                            final salads = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: selectedSaladId,
                              decoration: InputDecoration(
                                labelText: 'Salad (Optional)',
                                border: OutlineInputBorder(),
                                helperText: menu.salad.isNotEmpty
                                    ? 'Current: ${menu.salad}'
                                    : null,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: null, child: Text('None')),
                                ...salads.map((dish) {
                                  return DropdownMenuItem(
                                    value: dish.reference.id,
                                    child: Text(dish.nom),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedSaladId = value;
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: 12.0),
                        // Dessert Dropdown
                        StreamBuilder<List<PlatRecord>>(
                          stream: queryPlatRecord(
                            queryBuilder: (query) =>
                                query.where('categorie', isEqualTo: 'Dessert'),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox.shrink();
                            }
                            final desserts = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: selectedDessertId,
                              decoration: InputDecoration(
                                labelText: 'Dessert (Optional)',
                                border: OutlineInputBorder(),
                                helperText: menu.dessert.isNotEmpty
                                    ? 'Current: ${menu.dessert}'
                                    : null,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: null, child: Text('None')),
                                ...desserts.map((dish) {
                                  return DropdownMenuItem(
                                    value: dish.reference.id,
                                    child: Text(dish.nom),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedDessertId = value;
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: 12.0),
                        // Accompaniment Dropdown (Single Select)
                        StreamBuilder<List<PlatRecord>>(
                          stream: queryPlatRecord(
                            queryBuilder: (query) => query.where('categorie',
                                whereIn: [
                                  'Side Dish',
                                  'Accompaniment',
                                  'Side',
                                  'Bread'
                                ]),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox.shrink();
                            }
                            final sideDishes = snapshot.data ?? [];
                            if (sideDishes.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedAccompanimentIds.isNotEmpty
                                  ? selectedAccompanimentIds.first
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Accompaniment (Optional)',
                                border: OutlineInputBorder(),
                                helperText: menu.accompaniments.isNotEmpty
                                    ? 'Current: ${menu.accompaniments.join(", ")}'
                                    : null,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: null, child: Text('None')),
                                ...sideDishes.map((dish) {
                                  return DropdownMenuItem(
                                    value: dish.reference.id,
                                    child: Text(dish.nom),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedAccompanimentIds.clear();
                                  if (value != null) {
                                    selectedAccompanimentIds.add(value);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        SizedBox(height: 24.0),
                        SwitchListTile(
                          title: Text('Available'),
                          value: isAvailable,
                          onChanged: (value) {
                            setDialogState(() {
                              isAvailable = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Prepare update data
                          Map<String, dynamic> updateData = {
                            'day_of_week': selectedDate.weekday,
                            'meal_type': selectedMealType,
                            'description': descriptionController.text,
                            'available': isAvailable,
                            // Clear old accompaniment data - will be replaced with new selection
                            'accompaniment': '',
                          };

                          // Update main dish if changed
                          if (selectedMainDishId != null) {
                            final mainDishDoc = await PlatRecord.collection
                                .doc(selectedMainDishId)
                                .get();
                            final mainDish =
                                PlatRecord.fromSnapshot(mainDishDoc);
                            updateData['main_dish'] = mainDish.nom;
                            updateData['main_dish_ref'] = selectedMainDishId;

                            // Recalculate price
                            double menuPrice = mainDish.prix;

                            if (selectedSaladId != null) {
                              final saladDoc = await PlatRecord.collection
                                  .doc(selectedSaladId)
                                  .get();
                              final salad = PlatRecord.fromSnapshot(saladDoc);
                              updateData['salad'] = salad.nom;
                              updateData['salad_ref'] = selectedSaladId;
                              menuPrice += salad.prix;
                            } else {
                              updateData['salad'] = '';
                              updateData['salad_ref'] = '';
                            }

                            if (selectedDessertId != null) {
                              final dessertDoc = await PlatRecord.collection
                                  .doc(selectedDessertId)
                                  .get();
                              final dessert =
                                  PlatRecord.fromSnapshot(dessertDoc);
                              updateData['dessert'] = dessert.nom;
                              updateData['dessert_ref'] = selectedDessertId;
                              menuPrice += dessert.prix;
                            } else {
                              updateData['dessert'] = '';
                              updateData['dessert_ref'] = '';
                            }

                            // Process accompaniment (single selection)
                            List<String> accompanimentNames = [];
                            if (selectedAccompanimentIds.isNotEmpty) {
                              final accompanimentDoc = await PlatRecord
                                  .collection
                                  .doc(selectedAccompanimentIds.first)
                                  .get();
                              final accompaniment =
                                  PlatRecord.fromSnapshot(accompanimentDoc);
                              menuPrice += accompaniment.prix;
                              accompanimentNames.add(accompaniment.nom);
                            }
                            updateData['accompaniments'] = accompanimentNames;

                            updateData['price'] = menuPrice;
                          }

                          await menu.reference.update(updateData);

                          if (context.mounted) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Menu updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1C1284)),
                      child:
                          Text('Update', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showMenuDetailsDialog(BuildContext context, DailyMenuRecord menu) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_getDayName(menu.dayOfWeek)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Meal Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(menu.mealType == 'lunch' ? 'Lunch' : 'Dinner'),
                SizedBox(height: 12.0),
                Text('Complete Menu Composition',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                SizedBox(height: 8.0),
                // Main Course
                Row(
                  children: [
                    Icon(Icons.restaurant,
                        size: 18.0, color: Color(0xFF1C1284)),
                    SizedBox(width: 8.0),
                    Text('Main Course',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('${menu.mainDish}', style: TextStyle(fontSize: 14.0)),
                SizedBox(height: 8.0),
                // Salad
                if (menu.salad.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.eco, size: 18.0, color: Color(0xFF4CAF50)),
                      SizedBox(width: 8.0),
                      Text('Salad',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('${menu.salad}', style: TextStyle(fontSize: 14.0)),
                  SizedBox(height: 8.0),
                ],
                // Dessert
                if (menu.dessert.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.cake, size: 18.0, color: Color(0xFFFF9800)),
                      SizedBox(width: 8.0),
                      Text('Dessert',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('${menu.dessert}', style: TextStyle(fontSize: 14.0)),
                  SizedBox(height: 8.0),
                ],
                // Accompaniment
                if (menu.accompaniment.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.grain, size: 18.0, color: Color(0xFF795548)),
                      SizedBox(width: 8.0),
                      Text('Side Dish',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('${menu.accompaniment}',
                      style: TextStyle(fontSize: 14.0)),
                  SizedBox(height: 8.0),
                ],
                if (menu.description.isNotEmpty) ...[
                  SizedBox(height: 4.0),
                  Text('Description',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(menu.description,
                      style: TextStyle(
                          fontSize: 14.0, fontStyle: FontStyle.italic)),
                ],
                SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price - Hidden for staff view
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Text('Price',
                    //         style: TextStyle(fontWeight: FontWeight.bold)),
                    //     Text('${menu.price.toStringAsFixed(2)} TND',
                    //         style: TextStyle(
                    //             fontSize: 18.0,
                    //             fontWeight: FontWeight.bold,
                    //             color: Color(0xFF00A4E4))),
                    //   ],
                    // ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Status',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: menu.available
                                ? Color(0xFFE8F5E9)
                                : Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            menu.available ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: menu.available
                                  ? Color(0xFF2E7D32)
                                  : Color(0xFFC62828),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, DailyMenuRecord menu) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this menu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await menu.reference.delete();
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dayOfWeek - 1];
  }

  DateTime _getDateFromDayOfWeek(int dayOfWeek) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final daysToAdd = dayOfWeek - currentWeekday;
    return now.add(Duration(days: daysToAdd));
  }
}
