import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

class PaymentHistoryService {
  static PaymentHistoryService? _instance;
  static PaymentHistoryService get instance => _instance ??= PaymentHistoryService._();
  PaymentHistoryService._();

  /// Get user's payment history
  Future<List<Map<String, dynamic>>> getUserPaymentHistory(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payment_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final payments = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        payments.add({
          'id': doc.id,
          'amount': data['amount'],
          'currency': data['currency'] ?? 'TND',
          'description': data['description'],
          'paymentMethod': data['paymentMethod'],
          'status': data['status'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
          'transactionId': data['transactionId'],
          'orderId': data['orderId'],
        });
      }

      return payments;
    } catch (e) {
      AppLogger.e('Error fetching payment history', error: e, tag: 'PaymentHistoryService');
      return [];
    }
  }

  /// Get payment statistics for a user
  Future<Map<String, dynamic>> getUserPaymentStats(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payment_requests')
          .where('userId', isEqualTo: userId)
          .get();

      double totalSpent = 0;
      int totalTransactions = 0;
      int successfulPayments = 0;
      int d17Payments = 0;
      int walletPayments = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalTransactions++;
        
        if (data['status'] == 'completed') {
          successfulPayments++;
          totalSpent += (data['amount'] as num).toDouble();
          
          if (data['paymentMethod'] == 'd17') {
            d17Payments++;
          } else if (data['paymentMethod'] == 'wallet') {
            walletPayments++;
          }
        }
      }

      return {
        'totalSpent': totalSpent,
        'totalTransactions': totalTransactions,
        'successfulPayments': successfulPayments,
        'successRate': totalTransactions > 0 ? (successfulPayments / totalTransactions) * 100 : 0,
        'd17Payments': d17Payments,
        'walletPayments': walletPayments,
      };
    } catch (e) {
      AppLogger.e('Error calculating payment stats', error: e, tag: 'PaymentHistoryService');
      return {
        'totalSpent': 0.0,
        'totalTransactions': 0,
        'successfulPayments': 0,
        'successRate': 0.0,
        'd17Payments': 0,
        'walletPayments': 0,
      };
    }
  }

  /// Get pending payments for a user
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payment_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final payments = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        
        // Check if expired
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          // Update status to expired
          await doc.reference.update({'status': 'expired'});
          continue;
        }
        
        payments.add({
          'id': doc.id,
          'amount': data['amount'],
          'currency': data['currency'] ?? 'TND',
          'description': data['description'],
          'paymentMethod': data['paymentMethod'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'expiresAt': expiresAt,
          'orderId': data['orderId'],
        });
      }

      return payments;
    } catch (e) {
      AppLogger.e('Error fetching pending payments', error: e, tag: 'PaymentHistoryService');
      return [];
    }
  }

  /// Create a payment record for wallet transactions
  Future<String?> createWalletPaymentRecord({
    required String userId,
    required double amount,
    required String description,
    required String orderId,
  }) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('payment_requests')
          .add({
        'userId': userId,
        'amount': amount,
        'currency': 'TND',
        'description': description,
        'orderId': orderId,
        'paymentMethod': 'wallet',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'transactionId': 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      });

      return docRef.id;
    } catch (e) {
      AppLogger.e('Error creating wallet payment record', error: e, tag: 'PaymentHistoryService');
      return null;
    }
  }
}