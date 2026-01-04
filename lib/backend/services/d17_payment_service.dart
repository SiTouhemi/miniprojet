import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';

class D17PaymentService {
  static D17PaymentService? _instance;
  static D17PaymentService get instance => _instance ??= D17PaymentService._();
  D17PaymentService._();

  /// Generate QR code for D17 payment
  /// This creates a payment request that can be scanned by D17 app
  Future<Map<String, dynamic>> generatePaymentQR({
    required String userId,
    required double amount,
    required String description,
    required String orderId,
  }) async {
    try {
      // Create payment request in Firestore
      final paymentRequest = {
        'userId': userId,
        'amount': amount,
        'currency': 'TND',
        'description': description,
        'orderId': orderId,
        'paymentMethod': 'D17',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(minutes: 15)), // 15 min expiry
      };

      final docRef = await FirebaseFirestore.instance
          .collection('payment_requests')
          .add(paymentRequest);

      // Generate QR code data
      // Format: merchant_id|amount|currency|order_id|payment_request_id
      final qrData = 'ISET_RESTAURANT|${amount.toStringAsFixed(3)}|TND|$orderId|${docRef.id}';

      return {
        'success': true,
        'paymentRequestId': docRef.id,
        'qrData': qrData,
        'amount': amount,
        'expiresAt': DateTime.now().add(Duration(minutes: 15)).toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('Error generating D17 payment QR', error: e, tag: 'D17PaymentService');
      return {
        'success': false,
        'error': 'Failed to generate payment QR: ${e.toString()}'
      };
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentRequestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('payment_requests')
          .doc(paymentRequestId)
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'error': 'Payment request not found'
        };
      }

      final data = doc.data()!;
      final status = data['status'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Check if expired
      if (DateTime.now().isAfter(expiresAt) && status == 'pending') {
        // Update status to expired
        await doc.reference.update({'status': 'expired'});
        return {
          'success': true,
          'status': 'expired',
          'message': 'Payment request has expired'
        };
      }

      return {
        'success': true,
        'status': status,
        'amount': data['amount'],
        'orderId': data['orderId'],
      };
    } catch (e) {
      AppLogger.e('Error checking payment status', error: e, tag: 'D17PaymentService');
      return {
        'success': false,
        'error': 'Failed to check payment status: ${e.toString()}'
      };
    }
  }

  /// Simulate payment confirmation (for testing)
  /// In production, this would be called by a webhook or manual verification
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentRequestId,
    required String transactionId,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('payment_requests')
          .doc(paymentRequestId)
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'error': 'Payment request not found'
        };
      }

      final data = doc.data()!;
      if (data['status'] != 'pending') {
        return {
          'success': false,
          'error': 'Payment request is not pending'
        };
      }

      // Update payment status
      await doc.reference.update({
        'status': 'completed',
        'transactionId': transactionId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Payment confirmed successfully',
        'transactionId': transactionId,
      };
    } catch (e) {
      AppLogger.e('Error confirming payment', error: e, tag: 'D17PaymentService');
      return {
        'success': false,
        'error': 'Failed to confirm payment: ${e.toString()}'
      };
    }
  }

  /// Cancel payment request
  Future<Map<String, dynamic>> cancelPayment(String paymentRequestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('payment_requests')
          .doc(paymentRequestId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Payment cancelled successfully'
      };
    } catch (e) {
      AppLogger.e('Error cancelling payment', error: e, tag: 'D17PaymentService');
      return {
        'success': false,
        'error': 'Failed to cancel payment: ${e.toString()}'
      };
    }
  }
}