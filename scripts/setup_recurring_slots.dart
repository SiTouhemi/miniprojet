#!/usr/bin/env dart

/// Setup script for initializing recurring time slot templates
/// Run this once to set up the system for the first time
/// 
/// Usage: dart scripts/setup_recurring_slots.dart

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  print('🚀 Setting up recurring time slot templates...\n');

  try {
    // Initialize Firestore (you may need to configure this based on your setup)
    final firestore = FirebaseFirestore.instance;
    final templatesCollection = firestore.collection('time_slot_templates');

    // Check if templates already exist
    final existing = await templatesCollection.get();
    if (existing.docs.isNotEmpty) {
      print('⚠️  Templates already exist (${existing.docs.length} found)');
      print('   Delete existing templates first if you want to reinitialize.\n');
      return;
    }

    print('📝 Creating lunch templates (11:40 - 14:00)...');
    
    // Lunch slots: 11:40 - 14:00 (7 slots of 20 minutes)
    final lunchSlots = [
      {'start': '11:40', 'end': '12:00'},
      {'start': '12:00', 'end': '12:20'},
      {'start': '12:20', 'end': '12:40'},
      {'start': '12:40', 'end': '13:00'},
      {'start': '13:00', 'end': '13:20'},
      {'start': '13:20', 'end': '13:40'},
      {'start': '13:40', 'end': '14:00'},
    ];

    int lunchCount = 0;
    for (final slot in lunchSlots) {
      await templatesCollection.add({
        'meal_type': 'lunch',
        'start_time': slot['start'],
        'end_time': slot['end'],
        'max_capacity': 50,
        'price': 0.2,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      lunchCount++;
      print('   ✓ Created lunch slot: ${slot['start']} - ${slot['end']}');
    }

    print('\n📝 Creating dinner templates (17:40 - 18:40)...');
    
    // Dinner slots: 17:40 - 18:40 (3 slots of 20 minutes)
    final dinnerSlots = [
      {'start': '17:40', 'end': '18:00'},
      {'start': '18:00', 'end': '18:20'},
      {'start': '18:20', 'end': '18:40'},
    ];

    int dinnerCount = 0;
    for (final slot in dinnerSlots) {
      await templatesCollection.add({
        'meal_type': 'dinner',
        'start_time': slot['start'],
        'end_time': slot['end'],
        'max_capacity': 50,
        'price': 0.2,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      dinnerCount++;
      print('   ✓ Created dinner slot: ${slot['start']} - ${slot['end']}');
    }

    print('\n✅ Successfully created ${lunchCount + dinnerCount} templates!');
    print('   - Lunch slots: $lunchCount');
    print('   - Dinner slots: $dinnerCount');
    
    print('\n📅 Next steps:');
    print('   1. Generate daily slots for the upcoming week');
    print('   2. Set up weekly menus in the Daily Menu Management page');
    print('   3. Configure automatic daily slot generation (optional)');
    
    print('\n💡 Tip: Use the Admin UI to manage templates and generate slots');
    print('   Navigate to: Admin Dashboard → Time Slot Templates\n');

  } catch (e) {
    print('❌ Error: $e\n');
    print('Make sure Firebase is properly configured and you have the necessary permissions.');
  }
}
