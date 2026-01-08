import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to clean up old accompaniments data from daily_menu collection
/// This removes inconsistent data where accompaniments array contains old data
/// that's not managed by the current staff interface
Future<void> main() async {
  print('🧹 Starting accompaniments cleanup...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    final dailyMenuCollection = firestore.collection('daily_menu');
    
    // Get all daily menu documents
    final querySnapshot = await dailyMenuCollection.get();
    
    int updatedCount = 0;
    int totalCount = querySnapshot.docs.length;
    
    print('📊 Found $totalCount daily menu documents to check');
    
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final accompaniments = data['accompaniments'] as List<dynamic>? ?? [];
      final accompaniment = data['accompaniment'] as String? ?? '';
      
      // Check if there's old data in accompaniments array
      if (accompaniments.isNotEmpty) {
        print('🔧 Cleaning document ${doc.id}:');
        print('   - Removing accompaniments: $accompaniments');
        if (accompaniment.isNotEmpty) {
          print('   - Keeping accompaniment: $accompaniment');
        }
        
        // Clear the accompaniments array but keep the singular accompaniment
        await doc.reference.update({
          'accompaniments': [],
        });
        
        updatedCount++;
      }
    }
    
    print('\n✅ Cleanup completed!');
    print('   - Total documents checked: $totalCount');
    print('   - Documents updated: $updatedCount');
    print('   - Documents unchanged: ${totalCount - updatedCount}');
    
    if (updatedCount > 0) {
      print('\n📱 The student app should now show consistent menu data.');
      print('🔧 Staff can now manage all menu items through the interface.');
    } else {
      print('\n✨ No cleanup needed - all data is already consistent!');
    }
    
  } catch (e) {
    print('❌ Error during cleanup: $e');
    print('Please check your Firebase configuration and try again.');
  }
}