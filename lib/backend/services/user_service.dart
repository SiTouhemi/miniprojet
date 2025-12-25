import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_logger.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get all users with optional filtering
  Stream<List<UserRecord>> getAllUsers({
    String? searchQuery,
    String? roleFilter,
    int? limit,
  }) {
    Query query = _firestore.collection('user');
    
    // Apply role filter if specified
    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = query.where('role', isEqualTo: roleFilter);
    }
    
    // Order by creation time (newest first)
    query = query.orderBy('created_time', descending: true);
    
    // Apply limit if specified
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      List<UserRecord> users = snapshot.docs
          .map((doc) => UserRecord.fromSnapshot(doc))
          .toList();
      
      // Apply search filter on client side for better UX
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.nom.toLowerCase().contains(searchLower) ||
                 user.email.toLowerCase().contains(searchLower) ||
                 user.classe.toLowerCase().contains(searchLower) ||
                 user.role.toLowerCase().contains(searchLower);
        }).toList();
      }
      
      return users;
    });
  }

  /// Update user information
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? nom,
    String? classe,
    String? role,
    double? addMoney,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Verify admin permissions
      final currentRole = await authService.getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent modifier les utilisateurs.');
      }

      Map<String, dynamic> updateData = {};
      
      if (nom != null) {
        updateData['nom'] = nom;
        updateData['display_name'] = nom;
      }
      
      if (classe != null) {
        updateData['classe'] = classe;
      }
      
      if (role != null) {
        updateData['role'] = role;
      }
      
      // Handle adding money to user account
      if (addMoney != null && addMoney > 0) {
        // Get current user data to add to existing pocket
        final userDoc = await _firestore.collection('user').doc(userId).get();
        if (userDoc.exists) {
          final currentPocket = (userDoc.data()?['pocket'] as num?)?.toDouble() ?? 0.0;
          updateData['pocket'] = currentPocket + addMoney;
        } else {
          updateData['pocket'] = addMoney;
        }
      }
      
      // Add any additional data
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      // Update user document
      if (updateData.isNotEmpty) {
        await _firestore.collection('user').doc(userId).update(updateData);
      }
      
      // Update role in custom claims if role changed
      if (role != null) {
        await _updateUserRole(userId, role);
      }
      
      return {
        'success': true,
        'message': 'Utilisateur mis à jour avec succès',
        'updatedFields': updateData.keys.toList(),
      };
    } catch (e) {
      AppLogger.e('Error updating user', error: e, tag: 'UserService');
      return {
        'success': false,
        'error': 'Erreur lors de la mise à jour: ${e.toString()}',
      };
    }
  }

  /// Update user role in Firebase Auth custom claims
  Future<void> _updateUserRole(String userId, String role) async {
    try {
      final callable = _functions.httpsCallable('setUserRole');
      await callable.call({
        'uid': userId,
        'role': role,
      });
    } catch (e) {
      AppLogger.w('Error updating user role in custom claims', error: e, tag: 'UserService');
      // Don't throw here as the Firestore update was successful
    }
  }

  /// Add money to user account
  Future<Map<String, dynamic>> addMoneyToUser({
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      // Verify admin permissions
      final currentRole = await authService.getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent ajouter de l\'argent.');
      }

      if (amount <= 0) {
        throw Exception('Le montant doit être positif.');
      }

      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('user').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('Utilisateur non trouvé.');
        }
        
        final currentPocket = (userDoc.data()?['pocket'] as num?)?.toDouble() ?? 0.0;
        final newPocket = currentPocket + amount;
        
        transaction.update(userRef, {
          'pocket': newPocket,
          'last_money_added': FieldValue.serverTimestamp(),
        });
        
        // Log the transaction for audit purposes
        final logRef = _firestore.collection('money_transactions').doc();
        transaction.set(logRef, {
          'user_id': userId,
          'amount': amount,
          'previous_balance': currentPocket,
          'new_balance': newPocket,
          'description': description ?? 'Ajout d\'argent par administrateur',
          'admin_id': authService.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'admin_add',
        });
      });
      
      return {
        'success': true,
        'message': 'Argent ajouté avec succès',
        'amount': amount,
      };
    } catch (e) {
      AppLogger.e('Error adding money to user', error: e, tag: 'UserService');
      return {
        'success': false,
        'error': 'Erreur lors de l\'ajout d\'argent: ${e.toString()}',
      };
    }
  }

  /// Reset user password
  Future<Map<String, dynamic>> resetUserPassword(String email) async {
    try {
      // Verify admin permissions
      final currentRole = await authService.getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent réinitialiser les mots de passe.');
      }

      await authService.resetPassword(email);
      
      return {
        'success': true,
        'message': 'Email de réinitialisation envoyé à $email',
      };
    } catch (e) {
      AppLogger.e('Error resetting password', error: e, tag: 'UserService');
      return {
        'success': false,
        'error': 'Erreur lors de la réinitialisation: ${e.toString()}',
      };
    }
  }

  /// Get user statistics for admin dashboard
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('user').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int students = 0;
      int staff = 0;
      int admins = 0;
      double totalMoney = 0.0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? 'student';
        final pocket = (data['pocket'] as num?)?.toDouble() ?? 0.0;
        
        totalMoney += pocket;
        
        switch (role.toLowerCase()) {
          case 'admin':
            admins++;
            break;
          case 'staff':
            staff++;
            break;
          case 'student':
          default:
            students++;
            break;
        }
      }
      
      return {
        'success': true,
        'statistics': {
          'total_users': totalUsers,
          'students': students,
          'staff': staff,
          'admins': admins,
          'total_money_in_system': totalMoney,
        },
      };
    } catch (e) {
      AppLogger.e('Error getting user statistics', error: e, tag: 'UserService');
      return {
        'success': false,
        'error': 'Erreur lors de la récupération des statistiques: ${e.toString()}',
      };
    }
  }

  /// Deactivate/reactivate user account
  Future<Map<String, dynamic>> toggleUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      // Verify admin permissions
      final currentRole = await authService.getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent modifier le statut des utilisateurs.');
      }

      await _firestore.collection('user').doc(userId).update({
        'is_active': isActive,
        'status_changed_at': FieldValue.serverTimestamp(),
        'status_changed_by': authService.currentUser?.uid,
      });
      
      // If deactivating, also disable in Firebase Auth
      if (!isActive) {
        try {
          final callable = _functions.httpsCallable('disableUser');
          await callable.call({'uid': userId});
        } catch (e) {
          AppLogger.w('Error disabling user in Firebase Auth', error: e, tag: 'UserService');
        }
      }
      
      return {
        'success': true,
        'message': isActive ? 'Utilisateur activé' : 'Utilisateur désactivé',
      };
    } catch (e) {
      AppLogger.e('Error toggling user status', error: e, tag: 'UserService');
      return {
        'success': false,
        'error': 'Erreur lors du changement de statut: ${e.toString()}',
      };
    }
  }

  /// Get user's transaction history
  Future<List<Map<String, dynamic>>> getUserTransactionHistory(String userId) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection('money_transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return transactionsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      AppLogger.e('Error getting user transaction history', error: e, tag: 'UserService');
      return [];
    }
  }
}