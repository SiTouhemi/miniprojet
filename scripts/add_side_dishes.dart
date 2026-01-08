import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to add side dishes to the plat collection
/// These will be available as accompaniments when creating daily menus
Future<void> main() async {
  print('🍞 Adding side dishes to the database...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    final platCollection = firestore.collection('plat');
    
    // List of common side dishes for a university restaurant
    final sideDishes = [
      {
        'nom': 'Pita Bread & Hummus',
        'categorie': 'Side Dish',
        'prix': 1.5,
        'ingredients': 'Fresh pita bread, chickpea hummus, olive oil',
        'image': 'https://images.unsplash.com/photo-1621955964441-c173e01c135b?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'French Fries',
        'categorie': 'Side Dish',
        'prix': 1.0,
        'ingredients': 'Crispy golden french fries, sea salt',
        'image': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Rice Pilaf',
        'categorie': 'Side Dish',
        'prix': 1.2,
        'ingredients': 'Basmati rice, butter, herbs, vegetables',
        'image': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Couscous',
        'categorie': 'Side Dish',
        'prix': 1.5,
        'ingredients': 'Traditional Tunisian couscous, vegetables',
        'image': 'https://images.unsplash.com/photo-1645177628172-a94c1f96e6db?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Grilled Vegetables',
        'categorie': 'Side Dish',
        'prix': 1.8,
        'ingredients': 'Zucchini, bell peppers, eggplant, olive oil',
        'image': 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Garlic Bread',
        'categorie': 'Side Dish',
        'prix': 1.0,
        'ingredients': 'Baguette, garlic butter, parsley',
        'image': 'https://images.unsplash.com/photo-1573140401552-388e3c0b1f6e?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Pasta Salad',
        'categorie': 'Side Dish',
        'prix': 1.5,
        'ingredients': 'Pasta, vegetables, vinaigrette dressing',
        'image': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Mashed Potatoes',
        'categorie': 'Side Dish',
        'prix': 1.2,
        'ingredients': 'Creamy mashed potatoes, butter, milk',
        'image': 'https://images.unsplash.com/photo-1585307269-f2d6e2a4d6c7?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Steamed Vegetables',
        'categorie': 'Side Dish',
        'prix': 1.3,
        'ingredients': 'Broccoli, carrots, green beans',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Bread Rolls',
        'categorie': 'Side Dish',
        'prix': 0.8,
        'ingredients': 'Fresh baked bread rolls, butter',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      },
    ];
    
    int addedCount = 0;
    
    for (final dish in sideDishes) {
      // Check if dish already exists
      final existingQuery = await platCollection
          .where('nom', isEqualTo: dish['nom'])
          .limit(1)
          .get();
      
      if (existingQuery.docs.isEmpty) {
        await platCollection.add(dish);
        print('   ✓ Added: ${dish['nom']} - ${dish['prix']} DT');
        addedCount++;
      } else {
        print('   ⊘ Skipped (already exists): ${dish['nom']}');
      }
    }
    
    print('\n✅ Side dishes setup completed!');
    print('   - Total side dishes processed: ${sideDishes.length}');
    print('   - New dishes added: $addedCount');
    print('   - Already existing: ${sideDishes.length - addedCount}');
    
    if (addedCount > 0) {
      print('\n📱 You can now:');
      print('   1. Go to the Daily Menu Management page');
      print('   2. Edit or create a menu');
      print('   3. Select accompaniments from the new side dishes');
      print('   4. Students will see these items in their menu view');
    }
    
  } catch (e) {
    print('❌ Error adding side dishes: $e');
    print('Please check your Firebase configuration and try again.');
  }
}
