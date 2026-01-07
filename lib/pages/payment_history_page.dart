import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/payment_history_service.dart';
import '/utils/app_logger.dart';

class PaymentHistoryPage extends StatefulWidget {
  final UserRecord user;

  const PaymentHistoryPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> payments = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() => isLoading = true);

    try {
      final [paymentHistory, paymentStats] = await Future.wait([
        PaymentHistoryService.instance.getUserPaymentHistory(widget.user.uid),
        PaymentHistoryService.instance.getUserPaymentStats(widget.user.uid),
      ]);

      setState(() {
        payments = paymentHistory as List<Map<String, dynamic>>;
        stats = paymentStats as Map<String, dynamic>;
      });
    } catch (e) {
      AppLogger.e('Error loading payment data',
          error: e, tag: 'PaymentHistoryPage');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentData,
              child: CustomScrollView(
                slivers: [
                  // Stats section
                  SliverToBoxAdapter(child: _buildStatsSection()),

                  // Payment list
                  payments.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No payment history',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildPaymentTile(payments[index]),
                            childCount: payments.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  '${stats['totalSpent']?.toStringAsFixed(3) ?? '0.000'} TND',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transactions',
                  '${stats['totalTransactions'] ?? 0}',
                  Icons.receipt,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${stats['successRate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'D17 Payments',
                  '${stats['d17Payments'] ?? 0}',
                  Icons.qr_code,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> payment) {
    final status = payment['status'] as String;
    final amount = payment['amount'] as double;
    final paymentMethod = payment['paymentMethod'] as String;
    final createdAt = payment['createdAt'] as DateTime?;
    final completedAt = payment['completedAt'] as DateTime?;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.access_time;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(
              paymentMethod == 'd17'
                  ? Icons.qr_code
                  : Icons.account_balance_wallet,
              color: statusColor,
            ),
          ),
          title: Text(
            payment['description'] ?? 'Payment',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${amount.toStringAsFixed(3)} TND'),
              if (createdAt != null)
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () => _showPaymentDetails(payment),
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Amount', '${payment['amount'].toStringAsFixed(3)} TND'),
            _buildDetailRow(
                'Method', payment['paymentMethod'].toString().toUpperCase()),
            _buildDetailRow(
                'Status', payment['status'].toString().toUpperCase()),
            _buildDetailRow('Order ID', payment['orderId'] ?? 'N/A'),
            if (payment['transactionId'] != null)
              _buildDetailRow('Transaction ID', payment['transactionId']),
            if (payment['createdAt'] != null)
              _buildDetailRow('Created', _formatDateTime(payment['createdAt'])),
            if (payment['completedAt'] != null)
              _buildDetailRow(
                  'Completed', _formatDateTime(payment['completedAt'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
