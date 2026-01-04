import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/services/d17_payment_service.dart';
import '/utils/app_logger.dart';

class AdminPaymentDashboard extends StatefulWidget {
  const AdminPaymentDashboard({Key? key}) : super(key: key);

  @override
  State<AdminPaymentDashboard> createState() => _AdminPaymentDashboardState();
}

class _AdminPaymentDashboardState extends State<AdminPaymentDashboard> {
  List<Map<String, dynamic>> pendingPayments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    setState(() => isLoading = true);
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payment_requests')
          .where('status', isEqualTo: 'pending')
          .where('paymentMethod', isEqualTo: 'd17')
          .orderBy('createdAt', descending: true)
          .get();

      final payments = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        
        // Check if expired
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          await doc.reference.update({'status': 'expired'});
          continue;
        }
        
        // Get user info
        String userName = 'Unknown User';
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('user')
              .doc(data['userId'])
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userName = userData['display_name'] ?? userData['nom'] ?? 'Unknown User';
          }
        } catch (e) {
          AppLogger.w('Error fetching user data', error: e, tag: 'AdminPaymentDashboard');
        }
        
        payments.add({
          'id': doc.id,
          'userId': data['userId'],
          'userName': userName,
          'amount': data['amount'],
          'currency': data['currency'] ?? 'TND',
          'description': data['description'],
          'orderId': data['orderId'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'expiresAt': expiresAt,
        });
      }

      setState(() {
        pendingPayments = payments;
      });
    } catch (e) {
      AppLogger.e('Error loading pending payments', error: e, tag: 'AdminPaymentDashboard');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPendingPayments,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No pending D17 payments',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: pendingPayments.length,
                  itemBuilder: (context, index) => _buildPaymentCard(pendingPayments[index]),
                ),
    );
  }
  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final createdAt = payment['createdAt'] as DateTime?;
    final expiresAt = payment['expiresAt'] as DateTime?;
    final timeRemaining = expiresAt?.difference(DateTime.now());
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment['userName'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              payment['description'] ?? 'Payment',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  '${payment['amount'].toStringAsFixed(3)} TND',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Created: ${_formatDateTime(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (timeRemaining != null && !timeRemaining.isNegative) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'Expires in: ${_formatDuration(timeRemaining)}',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment['id']),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPayment(payment),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _confirmPayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to confirm this payment?'),
            SizedBox(height: 16),
            Text('User: ${payment['userName']}'),
            Text('Amount: ${payment['amount'].toStringAsFixed(3)} TND'),
            Text('Description: ${payment['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final transactionId = 'd17_admin_${DateTime.now().millisecondsSinceEpoch}';
        
        final result = await D17PaymentService.instance.confirmPayment(
          paymentRequestId: payment['id'],
          transactionId: transactionId,
        );

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment confirmed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPendingPayments(); // Refresh list
        } else {
          throw Exception(result['error']);
        }
      } catch (e) {
        AppLogger.e('Error confirming payment', error: e, tag: 'AdminPaymentDashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Payment'),
        content: Text('Are you sure you want to reject this payment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('payment_requests')
            .doc(paymentId)
            .update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': 'admin',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingPayments(); // Refresh list
      } catch (e) {
        AppLogger.e('Error rejecting payment', error: e, tag: 'AdminPaymentDashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}