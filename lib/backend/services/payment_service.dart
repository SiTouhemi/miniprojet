import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/services/app_service.dart';
import '/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  // Process D17 payment
  Future<Map<String, dynamic>> processD17Payment({
    required String userId,
    required double amount,
    required String description,
  }) async {
    try {
      // Generate a unique payment ID
      final paymentId = 'D17_${DateTime.now().millisecondsSinceEpoch}_$userId';

      // Call cloud function to verify payment with D17
      final result = await makeCloudCall('verifyD17Payment', {
        'paymentId': paymentId,
        'amount': amount,
        'userId': userId,
        'description': description,
      });

      if (result['success'] == true) {
        return {
          'success': true,
          'paymentId': paymentId,
          'transactionId': result['transactionId'],
          'amount': amount,
          'message': 'Payment processed successfully',
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      AppLogger.e('Error processing D17 payment',
          error: e, tag: 'PaymentService');
      return {
        'success': false,
        'error': 'Payment processing failed: ${e.toString()}',
      };
    }
  }

  // Check user's pocket balance from Firestore
  Future<double> getUserBalance(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final pocket = userData['pocket'] as double? ?? 0.0;
        AppLogger.d('Retrieved user balance: $pocket DT for user: $userId',
            tag: 'PaymentService');
        return pocket;
      } else {
        AppLogger.w('User document not found for userId: $userId',
            tag: 'PaymentService');
        return 0.0;
      }
    } catch (e) {
      AppLogger.e('Error checking user balance',
          error: e, tag: 'PaymentService');
      return 0.0;
    }
  }

  // Update user balance in Firestore
  Future<bool> updateUserBalance(String userId, double newBalance) async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .update({'pocket': newBalance});

      AppLogger.i('Updated user balance to $newBalance DT for user: $userId',
          tag: 'PaymentService');
      return true;
    } catch (e) {
      AppLogger.e('Error updating user balance',
          error: e, tag: 'PaymentService');
      return false;
    }
  }

  // Deduct amount from user balance using atomic transaction
  Future<Map<String, dynamic>> deductFromBalance(String userId, double amount,
      {String? description}) async {
    try {
      return await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('user').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          return {
            'success': false,
            'error': 'User not found',
          };
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentBalance = (userData['pocket'] as num?)?.toDouble() ?? 0.0;

        if (currentBalance < amount) {
          return {
            'success': false,
            'error':
                'Insufficient balance. Current: ${currentBalance.toStringAsFixed(2)} TND, Required: ${amount.toStringAsFixed(2)} TND',
            'currentBalance': currentBalance,
            'requiredAmount': amount,
          };
        }

        final newBalance = currentBalance - amount;

        // Update user balance
        transaction.update(userRef, {
          'pocket': newBalance,
        });

        // Log the transaction if description provided
        if (description != null) {
          final transactionLogRef = FirebaseFirestore.instance
              .collection('payment_transactions')
              .doc();
          transaction.set(transactionLogRef, {
            'user_id': userId,
            'amount': -amount, // Negative for deduction
            'type': 'balance_deduction',
            'description': description,
            'timestamp': FieldValue.serverTimestamp(),
            'balance_before': currentBalance,
            'balance_after': newBalance,
          });
        }

        AppLogger.i(
            'Deducted ${amount.toStringAsFixed(2)} TND from user $userId. New balance: ${newBalance.toStringAsFixed(2)} TND',
            tag: 'PaymentService');

        return {
          'success': true,
          'previousBalance': currentBalance,
          'newBalance': newBalance,
          'deductedAmount': amount,
        };
      });
    } catch (e) {
      AppLogger.e('Error deducting from balance',
          error: e, tag: 'PaymentService');
      return {
        'success': false,
        'error': 'Failed to deduct from balance: ${e.toString()}',
      };
    }
  }

  // Validate payment before reservation
  Future<Map<String, dynamic>> validatePayment({
    required String userId,
    required double amount,
  }) async {
    try {
      final balance = await getUserBalance(userId);

      if (balance >= amount) {
        return {
          'success': true,
          'balance': balance,
          'canPay': true,
          'message': 'Sufficient balance available',
        };
      } else {
        return {
          'success': false,
          'balance': balance,
          'canPay': false,
          'message':
              'Insufficient balance. Required: ${amount.toStringAsFixed(2)} TND, Available: ${balance.toStringAsFixed(2)} TND',
        };
      }
    } catch (e) {
      AppLogger.e('Error validating payment', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'error': 'Failed to validate payment: ${e.toString()}',
      };
    }
  }

  // Get payment history for user
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      // This would typically fetch from a payments collection
      // For now, we'll return mock data
      return [
        {
          'id': 'pay_001',
          'amount': 5.0,
          'description': 'Dinner Reservation',
          'date': DateTime.now().subtract(Duration(days: 1)),
          'status': 'completed',
          'transactionId': 'D17_TXN_001',
        },
        {
          'id': 'pay_002',
          'amount': 5.0,
          'description': 'Lunch Reservation',
          'date': DateTime.now().subtract(Duration(days: 3)),
          'status': 'completed',
          'transactionId': 'D17_TXN_002',
        },
      ];
    } catch (e) {
      AppLogger.e('Error fetching payment history',
          error: e, tag: 'PaymentService');
      return [];
    }
  }

  // Refund payment (for cancelled reservations)
  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required String userId,
    required double amount,
  }) async {
    try {
      // Call cloud function to process refund
      final result = await makeCloudCall('processRefund', {
        'paymentId': paymentId,
        'userId': userId,
        'amount': amount,
      });

      return result;
    } catch (e) {
      AppLogger.e('Error processing refund', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'error': 'Refund processing failed: ${e.toString()}',
      };
    }
  }

  // Calculate total amount for reservation
  Future<double> calculateReservationAmount({
    required String timeSlotId,
    int quantity = 1,
  }) async {
    try {
      final settings = await AppService.instance.getAppSettings();

      // For now, use default price from settings
      // In a more complex system, you might have different prices per time slot
      return settings.defaultMealPrice * quantity;
    } catch (e) {
      AppLogger.e('Error calculating reservation amount',
          error: e, tag: 'PaymentService');
      return 5.0; // Default fallback price
    }
  }

  // Get payment methods available for user
  Future<List<Map<String, String>>> getAvailablePaymentMethods(
      String userId) async {
    return [
      {
        'id': 'd17',
        'name': 'D17 Payment',
        'description': 'Pay using your D17 student card',
        'icon': 'credit_card',
      },
      // Future payment methods can be added here
      // {
      //   'id': 'mobile_money',
      //   'name': 'Mobile Money',
      //   'description': 'Pay using mobile money services',
      //   'icon': 'phone',
      // },
    ];
  }

  // Check if D17 service is available
  Future<bool> isD17ServiceAvailable() async {
    try {
      // Simulate checking D17 service status
      await Future.delayed(Duration(milliseconds: 300));

      // In production, this would ping the D17 API health endpoint
      return true; // Assume service is available for simulation
    } catch (e) {
      AppLogger.e('Error checking D17 service',
          error: e, tag: 'PaymentService');
      return false;
    }
  }
}
