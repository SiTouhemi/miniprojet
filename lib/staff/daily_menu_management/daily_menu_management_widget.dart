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
  State<DailyMenuManagementWidget> createState() => _DailyMenuManagementWidgetState();
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF1C1284),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 20.0,
            buttonSize: 40.0,
            fillColor: Colors.transparent,
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Menus de la Semaine',
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
                            icon: Icon(Icons.chevron_left, color: Color(0xFF1C1284)),
                            onPressed: () {
                              setState(() {
                                _model.selectedDate = _model.selectedDate.subtract(Duration(days: 7));
                              });
                            },
                          ),
                          Text(
                            'Semaine du ${DateFormat('dd/MM').format(_getWeekStart(_model.selectedDate))}',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: Color(0xFF1C1284)),
                            onPressed: () {
                              setState(() {
                                _model.selectedDate = _model.selectedDate.add(Duration(days: 7));
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
                            _buildMealTypeChip('Tous'),
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
              // Daily menus list
              Expanded(
                child: StreamBuilder<List<DailyMenuRecord>>(
                  stream: queryDailyMenuRecord(
                    queryBuilder: (query) {
                      final weekStart = _getWeekStart(_model.selectedDate);
                      final weekEnd = weekStart.add(Duration(days: 7));
                      return query
                          .where('date', isGreaterThanOrEqualTo: weekStart)
                          .where('date', isLessThan: weekEnd)
                          .orderBy('date');
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C1284)),
                        ),
                      );
                    }
                    final menus = snapshot.data ?? [];
                    final filteredMenus = menus.where((menu) {
                      return _model.selectedMealType == 'Tous' ||
                          menu.mealType == _model.selectedMealType;
                    }).toList();

                    if (filteredMenus.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 64.0, color: Colors.grey),
                            SizedBox(height: 16.0),
                            Text('Aucun menu pour cette semaine',
                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                      fontFamily: 'Inter Tight',
                                      color: Colors.grey,
                                      letterSpacing: 0.0,
                                    )),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: filteredMenus.length,
                      itemBuilder: (context, index) => _buildMenuCard(context, filteredMenus[index]),
                    );
                  },
                ),
              ),
            ],
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
    final displayName = mealType == 'Tous' ? 'Tous' : 
                       mealType == 'lunch' ? 'Déjeuner' : 'Dîner';
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

  Widget _buildMenuCard(BuildContext context, DailyMenuRecord menu) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
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
                          DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(menu.date!),
                          style: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Inter Tight',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 4.0),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: menu.mealType == 'lunch' ? Color(0xFFE3F2FD) : Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            menu.mealType == 'lunch' ? 'Déjeuner' : 'Dîner',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Inter',
                                  color: menu.mealType == 'lunch' ? Color(0xFF1976D2) : Color(0xFFF57C00),
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
              Text(
                menu.mainDish,
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Inter Tight',
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (menu.accompaniments.isNotEmpty) ...[
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: menu.accompaniments
                      .map((acc) => Chip(
                            label: Text(acc, style: TextStyle(fontSize: 12.0)),
                            backgroundColor: Color(0xFFF5F5F5),
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
                  Text(
                    '${menu.price.toStringAsFixed(2)} DT',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Inter Tight',
                          color: Color(0xFF00A4E4),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: menu.available ? Color(0xFFE8F5E9) : Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      menu.available ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        color: menu.available ? Color(0xFF2E7D32) : Color(0xFFC62828),
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

  void _showAddDailyMenuDialog(BuildContext context) {
    final mainDishController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController(text: '0.2');
    final accompanimentController = TextEditingController();
    final List<String> accompaniments = [];
    DateTime selectedDate = DateTime.now();
    String selectedMealType = 'lunch';
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ajouter un Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
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
                        labelText: 'Type de repas *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'lunch', child: Text('Déjeuner')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dîner')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMealType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: mainDishController,
                      decoration: InputDecoration(
                        labelText: 'Plat principal *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: accompanimentController,
                            decoration: InputDecoration(
                              labelText: 'Accompagnement',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Color(0xFF1C1284)),
                          onPressed: () {
                            if (accompanimentController.text.isNotEmpty) {
                              setDialogState(() {
                                accompaniments.add(accompanimentController.text);
                                accompanimentController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (accompaniments.isNotEmpty) ...[
                      SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        children: accompaniments
                            .map((acc) => Chip(
                                  label: Text(acc),
                                  onDeleted: () {
                                    setDialogState(() {
                                      accompaniments.remove(acc);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 12.0),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix (DT) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 12.0),
                    SwitchListTile(
                      title: Text('Disponible'),
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
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (mainDishController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Le plat principal est obligatoire'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      final price = double.tryParse(priceController.text) ?? 0.2;
                      await DailyMenuRecord.collection.add({
                        'date': selectedDate,
                        'meal_type': selectedMealType,
                        'main_dish': mainDishController.text,
                        'accompaniments': accompaniments,
                        'description': descriptionController.text,
                        'price': price,
                        'available': isAvailable,
                        'created_by': currentUser?.uid ?? '',
                        'created_at': DateTime.now(),
                      });
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menu ajouté avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1C1284)),
                  child: Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMenuDialog(BuildContext context, DailyMenuRecord menu) {
    final mainDishController = TextEditingController(text: menu.mainDish);
    final descriptionController = TextEditingController(text: menu.description);
    final priceController = TextEditingController(text: menu.price.toString());
    final List<String> accompaniments = List.from(menu.accompaniments);
    final accompanimentController = TextEditingController();
    DateTime selectedDate = menu.date!;
    String selectedMealType = menu.mealType;
    bool isAvailable = menu.available;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Modifier le Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(Duration(days: 365)),
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
                        labelText: 'Type de repas *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'lunch', child: Text('Déjeuner')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dîner')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMealType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: mainDishController,
                      decoration: InputDecoration(
                        labelText: 'Plat principal *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: accompanimentController,
                            decoration: InputDecoration(
                              labelText: 'Accompagnement',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Color(0xFF1C1284)),
                          onPressed: () {
                            if (accompanimentController.text.isNotEmpty) {
                              setDialogState(() {
                                accompaniments.add(accompanimentController.text);
                                accompanimentController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (accompaniments.isNotEmpty) ...[
                      SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        children: accompaniments
                            .map((acc) => Chip(
                                  label: Text(acc),
                                  onDeleted: () {
                                    setDialogState(() {
                                      accompaniments.remove(acc);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 12.0),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix (DT) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 12.0),
                    SwitchListTile(
                      title: Text('Disponible'),
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
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (mainDishController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Le plat principal est obligatoire'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      final price = double.tryParse(priceController.text) ?? 0.2;
                      await menu.reference.update({
                        'date': selectedDate,
                        'meal_type': selectedMealType,
                        'main_dish': mainDishController.text,
                        'accompaniments': accompaniments,
                        'description': descriptionController.text,
                        'price': price,
                        'available': isAvailable,
                      });
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menu modifié avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1C1284)),
                  child: Text('Modifier', style: TextStyle(color: Colors.white)),
                ),
              ],
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
          title: Text(DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(menu.date!)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(menu.mealType == 'lunch' ? 'Déjeuner' : 'Dîner'),
                SizedBox(height: 12.0),
                Text('Plat Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(menu.mainDish),
                if (menu.accompaniments.isNotEmpty) ...[
                  SizedBox(height: 12.0),
                  Text('Accompagnements', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...menu.accompaniments.map((acc) => Text('• $acc')),
                ],
                if (menu.description.isNotEmpty) ...[
                  SizedBox(height: 12.0),
                  Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(menu.description),
                ],
                SizedBox(height: 12.0),
                Text('Prix', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${menu.price.toStringAsFixed(2)} DT'),
                SizedBox(height: 12.0),
                Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(menu.available ? 'Disponible' : 'Indisponible'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Fermer'),
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
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce menu ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await menu.reference.delete();
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu supprimé avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
