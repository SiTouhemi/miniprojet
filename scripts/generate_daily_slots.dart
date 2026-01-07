#!/usr/bin/env dart

/// Daily Time Slot Generation Script
/// This script generates time slots for today from templates
/// Should be run daily (can be automated via cron job or similar)
/// 
/// Usage: dart scripts/generate_daily_slots.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main(List<String> args) async {
  print('🕐 Generating daily time slots for ${DateTime.now().toString().split(' ')[0]}...\n');

  try {
    // Initialize Firestore
    final firestore = FirebaseFirestore.instance;
    
    // Get today's date
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Check if restaurant is open (not Sunday)
    if (today.weekday == DateTime.sunday) {
      print('🚫 Restaurant is closed on Sundays. No slots to generate.\n');
      return;
    }
    
    print('📅 Date: ${todayStart.toString().split(' ')[0]}');
    print('📍 Day: ${_getDayName(today.weekday)}\n');
    
    // Check if slots already exist for today
    final existingSlots = await firestore
        .collection('time_slots')
        .where('date', isEqualTo: todayStart)
        .get();
    
    if (existingSlots.docs.isNotEmpty) {
      print('✅ Time slots already exist for today (${existingSlots.docs.length} slots found)');
      print('   No action needed.\n');
      return;
    }
    
    // Get active templates
    final templatesSnapshot = await firestore
        .collection('time_slot_templates')
        .where('is_active', isEqualTo: true)
        .orderBy('meal_type')
        .orderBy('start_time')
        .get();
    
    if (templatesSnapshot.docs.isEmpty) {
      print('❌ No active templates found!');
      print('   Please create templates first using:');
      print('   dart scripts/setup_recurring_slots.dart\n');
      return;
    }
    
    print('📝 Found ${templatesSnapshot.docs.length} active templates');
    
    // Generate slots from templates
    final batch = firestore.batch();
    int createdCount = 0;
    
    for (final templateDoc in templatesSnapshot.docs) {
      final template = templateDoc.data();
      
      // Parse template times for today
      final startTime = _parseTimeForDate(template['start_time'] as String, todayStart);
      final endTime = _parseTimeForDate(template['end_time'] as String, todayStart);
      
      // Create slot data
      final slotData = {
        'date': todayStart,
        'start_time': startTime,
        'end_time': endTime,
        'max_capacity': template['max_capacity'] as int,
        'current_reservations': 0,
        'price': (template['price'] as num).toDouble(),
        'is_active': true,
        'meal_type': template['meal_type'] as String,
        'template_id': templateDoc.id,
        'created_at': FieldValue.serverTimestamp(),
      };
      
      // Add to batch
      final docRef = firestore.collection('time_slots').doc();
      batch.set(docRef, slotData);
      createdCount++;
      
      print('   ✓ ${template['meal_type']}: ${template['start_time']} - ${template['end_time']} (${template['max_capacity']} seats)');
    }
    
    // Commit batch
    await batch.commit();
    
    print('\n🎉 Successfully created $createdCount time slots for today!');
    print('   Students can now make reservations.\n');
    
    // Show next steps
    print('💡 Next steps:');
    print('   1. Set up daily menu in the Daily Menu Management page');
    print('   2. Monitor reservations throughout the day');
    print('   3. Run this script again tomorrow (or set up automation)\n');
    
  } catch (e) {
    print('❌ Error generating daily slots: $e\n');
    print('Make sure Firebase is properly configured and you have the necessary permissions.');
    exit(1);
  }
}

/// Parse time string (HH:mm) to DateTime for a specific date
DateTime _parseTimeForDate(String timeStr, DateTime date) {
  final parts = timeStr.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Get day name from weekday number
String _getDayName(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[weekday - 1];
}