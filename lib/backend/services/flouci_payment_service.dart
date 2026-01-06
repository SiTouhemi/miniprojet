import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/backend/services/user_service.dart';
import '/utils/app_logger.dart';

class FlouciPaymentService {
  static FlouciPaymentService? _instance;
  static FlouciPaymentService get instance =>
      _instance ??= FlouciPaymentService._();
  FlouciPaymentService._();

  // Flouci API Configuration
  static const String _baseUrl = 'https://developers.flouci.com/api';
  static const String _appToken =
      'YOUR_FLOUCI_APP_TOKEN'; // Replace with actual token
  static const String _appSecret =
      'YOUR_FLOUCI_APP_SECRET'; // Replace with actual secret

  // DEMO MODE - Set to true for presentation without real API
  static const bool _demoMode = true;

  /// Generate Flouci payment for wallet top-up
  Future<Map<String, dynamic>> generateWalletTopUp({
    required String userId,
    required double amount,
    required String studentName,
  }) async {
    try {
      // DEMO MODE: Skip real API call
      if (_demoMode) {
        return await _generateDemoPayment(
          userId: userId,
          amount: amount,
          studentName: studentName,
        );
      }

      // Create payment request in Firestore first
      final paymentRequest = {
        'userId': userId,
        'amount': amount,
        'currency': 'TND',
        'type': 'wallet_topup',
        'status': 'pending',
        'studentName': studentName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(minutes: 30)),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .add(paymentRequest);

      // Generate Flouci payment
      final flouciResponse = await _createFlouciPayment(
        amount: amount,
        description: 'Wallet Top-up - $studentName',
        orderId: docRef.id,
      );

      if (flouciResponse['success']) {
        // Update payment request with Flouci payment ID
        await docRef.update({
          'flouciPaymentId': flouciResponse['payment_id'],
          'paymentUrl': flouciResponse['link'],
        });

        return {
          'success': true,
          'paymentRequestId': docRef.id,
          'paymentUrl': flouciResponse['link'],
          'paymentId': flouciResponse['payment_id'],
          'qrCode': flouciResponse['link'], // Can be used to generate QR
          'expiresAt':
              DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
        };
      } else {
        // Clean up failed request
        await docRef.delete();
        throw Exception(flouciResponse['error']);
      }
    } catch (e) {
      AppLogger.e('Error generating Flouci wallet top-up',
          error: e, tag: 'FlouciPaymentService');
      return {
        'success': false,
        'error': 'Failed to generate payment: ${e.toString()}'
      };
    }
  }

  /// DEMO MODE: Generate fake payment for presentation
  Future<Map<String, dynamic>> _generateDemoPayment({
    required String userId,
    required double amount,
    required String studentName,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(seconds: 1));

      // Create payment request in Firestore
      final paymentRequest = {
        'userId': userId,
        'amount': amount,
        'currency': 'TND',
        'type': 'wallet_topup',
        'status': 'pending',
        'studentName': studentName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(minutes: 30)),
        'demoMode': true,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .add(paymentRequest);

      // Generate demo payment URL
      final demoPaymentId = 'DEMO_${DateTime.now().millisecondsSinceEpoch}';
      final demoUrl = 'https://demo-flouci.com/pay/$demoPaymentId';

      // Update with demo data
      await docRef.update({
        'flouciPaymentId': demoPaymentId,
        'paymentUrl': demoUrl,
      });

      // DEMO: Auto-complete payment after 10 seconds
      _simulatePaymentCompletion(docRef.id, demoPaymentId, amount);

      AppLogger.i('Demo payment generated: $amount DT for $studentName',
          tag: 'FlouciPaymentService');

      return {
        'success': true,
        'paymentRequestId': docRef.id,
        'paymentUrl': demoUrl,
        'paymentId': demoPaymentId,
        'qrCode':
            'FLOUCI_DEMO|${amount.toStringAsFixed(3)}|TND|$studentName|${docRef.id}',
        'expiresAt':
            DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('Error generating demo payment',
          error: e, tag: 'FlouciPaymentService');
      return {
        'success': false,
        'error': 'Failed to generate demo payment: ${e.toString()}'
      };
    }
  }

  /// DEMO: Simulate automatic payment completion
  Future<void> _simulatePaymentCompletion(
      String requestId, String paymentId, double amount) async {
    // Wait 10 seconds to simulate payment processing
    await Future.delayed(Duration(seconds: 10));

    try {
      // Simulate webhook call - directly update the payment status
      await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .doc(requestId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'transactionId': 'DEMO_TXN_${DateTime.now().millisecondsSinceEpoch}',
        'flouciStatus': 'SUCCESS',
      });

      // Update user balance directly
      final doc = await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final userId = data['userId'] as String;

        // Add money to user account
        await UserService.instance.addMoneyToUser(
          userId: userId,
          amount: amount,
          description: 'Wallet top-up via Flouci Demo - $paymentId',
        );

        AppLogger.i('Demo payment auto-completed: $amount DT',
            tag: 'FlouciPaymentService');
      }
    } catch (e) {
      AppLogger.e('Error auto-completing demo payment',
          error: e, tag: 'FlouciPaymentService');
    }
  }

  /// Create payment with Flouci API
  Future<Map<String, dynamic>> _createFlouciPayment({
    required double amount,
    required String description,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate_payment'),
        headers: {
          'Content-Type': 'application/json',
          'apppublic': _appToken,
          'appsecret': _appSecret,
        },
        body: jsonEncode({
          'app_token': _appToken,
          'app_secret': _appSecret,
          'amount': (amount * 1000).toInt(), // Flouci uses millimes
          'accept_card': 'true',
          'session_timeout_secs': 1800, // 30 minutes
          'success_link': 'https://your-app.com/payment-success',
          'fail_link': 'https://your-app.com/payment-failed',
          'developer_tracking_id': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result']['success'] == true) {
          return {
            'success': true,
            'payment_id': data['result']['payment_id'],
            'link': data['result']['link'],
          };
        } else {
          return {
            'success': false,
            'error': data['result']['message'] ?? 'Payment creation failed',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.e('Error calling Flouci API',
          error: e, tag: 'FlouciPaymentService');
      return {
        'success': false,
        'error': 'API call failed: ${e.toString()}',
      };
    }
  }

  /// Check payment status with Flouci
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/verify_payment/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'apppublic': _appToken,
          'appsecret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'status': data['result']['status'], // SUCCESS, PENDING, FAILED
          'amount': data['result']['amount'],
          'transaction_id': data['result']['transaction_id'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.e('Error checking Flouci payment status',
          error: e, tag: 'FlouciPaymentService');
      return {
        'success': false,
        'error': 'Status check failed: ${e.toString()}',
      };
    }
  }

  /// Get pending wallet top-up requests for a user
  Future<List<Map<String, dynamic>>> getPendingTopUps(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final topUps = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

        // Check if expired
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          await doc.reference.update({'status': 'expired'});
          continue;
        }

        topUps.add({
          'id': doc.id,
          'amount': data['amount'],
          'status': data['status'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'expiresAt': expiresAt,
          'paymentUrl': data['paymentUrl'],
          'flouciPaymentId': data['flouciPaymentId'],
        });
      }

      return topUps;
    } catch (e) {
      AppLogger.e('Error fetching pending top-ups',
          error: e, tag: 'FlouciPaymentService');
      return [];
    }
  }

  /// Cancel a pending top-up request
  Future<Map<String, dynamic>> cancelTopUpRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Top-up request cancelled successfully'
      };
    } catch (e) {
      AppLogger.e('Error cancelling top-up request',
          error: e, tag: 'FlouciPaymentService');
      return {
        'success': false,
        'error': 'Failed to cancel request: ${e.toString()}'
      };
    }
  }
}
