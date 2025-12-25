import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/services/app_service.dart';
import '/utils/app_logger.dart';

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
      AppLogger.e('Error processing D17 payment', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'error': 'Payment processing failed: ${e.toString()}',
      };
    }
  }

  // Check user's pocket balance
  Future<double> getUserBalance(String userId) async {
    try {
      // This would typically come from the user record
      // For now, we'll simulate checking D17 balance
      return await _simulateD17BalanceCheck(userId);
    } catch (e) {
      AppLogger.e('Error checking user balance', error: e, tag: 'PaymentService');
      return 0.0;
    }
  }

  // Simulate D17 balance check (replace with actual D17 API)
  Future<double> _simulateD17BalanceCheck(String userId) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // Return a random balance for simulation
    // In production, this would call the actual D17 API
    return 25.0 + (userId.hashCode % 100); // Simulate balance between 25-125
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
          'message': 'Insufficient balance. Required: ${amount.toStringAsFixed(2)} TND, Available: ${balance.toStringAsFixed(2)} TND',
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
      AppLogger.e('Error fetching payment history', error: e, tag: 'PaymentService');
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
      AppLogger.e('Error calculating reservation amount', error: e, tag: 'PaymentService');
      return 5.0; // Default fallback price
    }
  }

  // Get payment methods available for user
  Future<List<Map<String, String>>> getAvailablePaymentMethods(String userId) async {
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
      AppLogger.e('Error checking D17 service', error: e, tag: 'PaymentService');
      return false;
    }
  }
}