import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal_management_model.dart';
export 'meal_management_model.dart';

class MealManagementWidget extends StatefulWidget {
  const MealManagementWidget({super.key});

  static String routeName = 'MealManagement';
  static String routePath = '/mealManagement';

  @override
  State<MealManagementWidget> createState() => _MealManagementWidgetState();
}

class _MealManagementWidgetState extends State<MealManagementWidget> {
  late MealManagementModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MealManagementModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
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
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.0,
            ),
            onPressed: () {
              context.pop();
            },
          ),
          title: Text(
            'Gestion des Repas',
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
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () {
                  _showAddMealDialog(context);
                },
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
              // Search and filter section
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
                      // Search bar
                      TextFormField(
                        controller: _model.searchController,
                        focusNode: _model.searchFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Rechercher un repas...',
                          hintText: 'Nom, ingrédients...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF1C1284),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 12.0, 16.0, 12.0),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 12.0),
                      // Category filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('Tous'),
                            SizedBox(width: 8.0),
                            _buildCategoryChip('Entrée'),
                            SizedBox(width: 8.0),
                            _buildCategoryChip('Plat Principal'),
                            SizedBox(width: 8.0),
                            _buildCategoryChip('Dessert'),
                            SizedBox(width: 8.0),
                            _buildCategoryChip('Boisson'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Meals list
              Expanded(
                child: StreamBuilder<List<PlatRecord>>(
                  stream: queryPlatRecord(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1C1284),
                          ),
                        ),
                      );
                    }

                    final meals = snapshot.data ?? [];
                    
                    // Filter meals based on search and category
                    final filteredMeals = meals.where((meal) {
                      final searchQuery = _model.searchController?.text.toLowerCase() ?? '';
                      final matchesSearch = searchQuery.isEmpty ||
                          meal.nom.toLowerCase().contains(searchQuery) ||
                          meal.ingredients.toLowerCase().contains(searchQuery);
                      
                      final matchesCategory = _model.selectedCategory == 'Tous' ||
                          meal.categorie == _model.selectedCategory;
                      
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filteredMeals.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64.0,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Aucun repas trouvé',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Colors.grey,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Ajoutez votre premier repas',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    color: Colors.grey,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: filteredMeals.length,
                      itemBuilder: (context, index) {
                        final meal = filteredMeals[index];
                        return _buildMealCard(context, meal);
                      },
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

  Widget _buildCategoryChip(String category) {
    final isSelected = _model.selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _model.selectedCategory = category;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF1C1284),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF1C1284),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: Color(0xFF1C1284),
        width: 1.0,
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, PlatRecord meal) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          _showMealDetailsDialog(context, meal);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal image or icon
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: meal.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          meal.image,
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant,
                              size: 40.0,
                              color: Color(0xFF1C1284),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        size: 40.0,
                        color: Color(0xFF1C1284),
                      ),
              ),
              SizedBox(width: 16.0),
              // Meal details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            meal.nom,
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Inter Tight',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF00A4E4),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            '${meal.prix.toStringAsFixed(2)} DT',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        meal.categorie,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Color(0xFF2E7D32),
                              letterSpacing: 0.0,
                              fontSize: 11.0,
                            ),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      meal.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.0),
              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF1C1284)),
                    onPressed: () {
                      _showEditMealDialog(context, meal);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, meal);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final ingredientsController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    String selectedCategory = 'Plat Principal';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ajouter un Repas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du repas *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Entrée', 'Plat Principal', 'Dessert', 'Boisson']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: ingredientsController,
                      decoration: InputDecoration(
                        labelText: 'Ingrédients',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
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
                    TextField(
                      controller: imageController,
                      decoration: InputDecoration(
                        labelText: 'URL de l\'image',
                        border: OutlineInputBorder(),
                      ),
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
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez remplir les champs obligatoires'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final price = double.tryParse(priceController.text) ?? 0.0;
                      
                      await PlatRecord.collection.add(
                        createPlatRecordData(
                          nom: nameController.text,
                          categorie: selectedCategory,
                          description: descriptionController.text,
                          ingredients: ingredientsController.text,
                          prix: price,
                          image: imageController.text,
                        ),
                      );

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Repas ajouté avec succès'),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C1284),
                  ),
                  child: Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMealDialog(BuildContext context, PlatRecord meal) {
    final nameController = TextEditingController(text: meal.nom);
    final descriptionController = TextEditingController(text: meal.description);
    final ingredientsController = TextEditingController(text: meal.ingredients);
    final priceController = TextEditingController(text: meal.prix.toString());
    final imageController = TextEditingController(text: meal.image);
    String selectedCategory = meal.categorie;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Modifier le Repas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du repas *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Entrée', 'Plat Principal', 'Dessert', 'Boisson']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      controller: ingredientsController,
                      decoration: InputDecoration(
                        labelText: 'Ingrédients',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
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
                    TextField(
                      controller: imageController,
                      decoration: InputDecoration(
                        labelText: 'URL de l\'image',
                        border: OutlineInputBorder(),
                      ),
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
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez remplir les champs obligatoires'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final price = double.tryParse(priceController.text) ?? 0.0;
                      
                      await meal.reference.update(
                        createPlatRecordData(
                          nom: nameController.text,
                          categorie: selectedCategory,
                          description: descriptionController.text,
                          ingredients: ingredientsController.text,
                          prix: price,
                          image: imageController.text,
                        ),
                      );

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Repas modifié avec succès'),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C1284),
                  ),
                  child: Text('Modifier', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMealDetailsDialog(BuildContext context, PlatRecord meal) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(meal.nom),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meal.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      meal.image,
                      width: double.infinity,
                      height: 200.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200.0,
                          color: Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.restaurant,
                            size: 80.0,
                            color: Color(0xFF1C1284),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16.0),
                Text(
                  'Catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(meal.categorie),
                SizedBox(height: 12.0),
                Text(
                  'Prix',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${meal.prix.toStringAsFixed(2)} DT'),
                SizedBox(height: 12.0),
                Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(meal.description.isNotEmpty ? meal.description : 'Aucune description'),
                SizedBox(height: 12.0),
                Text(
                  'Ingrédients',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(meal.ingredients.isNotEmpty ? meal.ingredients : 'Non spécifié'),
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

  void _showDeleteConfirmation(BuildContext context, PlatRecord meal) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${meal.nom}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await meal.reference.delete();
                  
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Repas supprimé avec succès'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
