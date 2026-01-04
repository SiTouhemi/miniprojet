import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

class PaymentNotificationService {
  static PaymentNotificationService? _instance;
  static PaymentNotificationService get instance => _instance ??= PaymentNotificationService._();
  PaymentNotificationService._();

  /// Listen to payment status changes for a specific user
  Stream<List<Map<String, dynamic>>> listenToUserPayments(String userId) {
    return FirebaseFirestore.instance
        .collection('payment_requests')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'completed', 'expired'])
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'status': data['status'],
          'amount': data['amount'],
          'description': data['description'],
          'paymentMethod': data['paymentMethod'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
          'expiresAt': (data['expiresAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  /// Listen to all pending D17 payments (for admin)
  Stream<List<Map<String, dynamic>>> listenToPendingD17Payments() {
    return FirebaseFirestore.instance
        .collection('payment_requests')
        .where('status', isEqualTo: 'pending')
        .where('paymentMethod', isEqualTo: 'd17')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'],
          'amount': data['amount'],
          'description': data['description'],
          'orderId': data['orderId'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'expiresAt': (data['expiresAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  /// Create a notification for payment status change
  Future<void> createPaymentNotification({
    required String userId,
    required String paymentId,
    required String status,
    required double amount,
    String? description,
  }) async {
    try {
      String title;
      String message;
      String type;

      switch (status) {
        case 'completed':
          title = 'Payment Successful';
          message = 'Your payment of ${amount.toStringAsFixed(3)} TND has been processed successfully.';
          type = 'payment_success';
          break;
        case 'expired':
          title = 'Payment Expired';
          message = 'Your payment request for ${amount.toStringAsFixed(3)} TND has expired.';
          type = 'payment_expired';
          break;
        case 'cancelled':
          title = 'Payment Cancelled';
          message = 'Your payment of ${amount.toStringAsFixed(3)} TND has been cancelled.';
          type = 'payment_cancelled';
          break;
        default:
          return; // Don't create notification for other statuses
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'paymentId': paymentId,
        'amount': amount,
        'description': description,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.i('Payment notification created', tag: 'PaymentNotificationService');
    } catch (e) {
      AppLogger.e('Error creating payment notification', error: e, tag: 'PaymentNotificationService');
    }
  }

  /// Get unread notifications for a user
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'],
          'message': data['message'],
          'type': data['type'],
          'paymentId': data['paymentId'],
          'amount': data['amount'],
          'description': data['description'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching notifications', error: e, tag: 'PaymentNotificationService');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      AppLogger.e('Error marking notification as read', error: e, tag: 'PaymentNotificationService');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      AppLogger.e('Error marking all notifications as read', error: e, tag: 'PaymentNotificationService');
    }
  }

  /// Show in-app notification
  static void showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}