import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/services/user_service.dart';
import '/utils/app_logger.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class WalletTopupManagementWidget extends StatefulWidget {
  const WalletTopupManagementWidget({Key? key}) : super(key: key);

  @override
  State<WalletTopupManagementWidget> createState() =>
      _WalletTopupManagementWidgetState();
}

class _WalletTopupManagementWidgetState
    extends State<WalletTopupManagementWidget> {
  List<Map<String, dynamic>> pendingTopUps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingTopUps();
  }

  Future<void> _loadPendingTopUps() async {
    setState(() => isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('wallet_topup_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final topUps = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Get user info
        String userName = 'Unknown User';
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('user')
              .doc(data['userId'])
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userName =
                userData['display_name'] ?? userData['nom'] ?? 'Unknown User';
          }
        } catch (e) {
          AppLogger.w('Error fetching user data',
              error: e, tag: 'WalletTopupManagement');
        }

        topUps.add({
          'id': doc.id,
          'userId': data['userId'],
          'userName': userName,
          'studentName': data['studentName'],
          'amount': data['amount'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'expiresAt': (data['expiresAt'] as Timestamp?)?.toDate(),
          'flouciPaymentId': data['flouciPaymentId'],
        });
      }

      setState(() {
        pendingTopUps = topUps;
      });
    } catch (e) {
      AppLogger.e('Error loading pending top-ups',
          error: e, tag: 'WalletTopupManagement');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Recharges'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPendingTopUps,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingTopUps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: theme.success),
                      SizedBox(height: 16),
                      Text(
                        'Aucune recharge en attente',
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
                  itemCount: pendingTopUps.length,
                  itemBuilder: (context, index) =>
                      _buildTopUpCard(pendingTopUps[index], theme),
                ),
    );
  }

  Widget _buildTopUpCard(Map<String, dynamic> topUp, FlutterFlowTheme theme) {
    final createdAt = topUp['createdAt'] as DateTime?;
    final amount = topUp['amount'] as double;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topUp['userName'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Montant: ${amount.toStringAsFixed(3)} DT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.warning),
                  ),
                  child: Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.warning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (createdAt != null)
              Text(
                'Créé: ${_formatDateTime(createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectTopUp(topUp['id']),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.error,
                      side: BorderSide(color: theme.error),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmTopUp(topUp),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.success,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmTopUp(Map<String, dynamic> topUp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la Recharge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir confirmer cette recharge?'),
            SizedBox(height: 16),
            Text('Étudiant: ${topUp['userName']}'),
            Text('Montant: ${topUp['amount'].toStringAsFixed(3)} DT'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).success,
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final transactionId = 'ADMIN_${DateTime.now().millisecondsSinceEpoch}';

        // Update payment status
        await FirebaseFirestore.instance
            .collection('wallet_topup_requests')
            .doc(topUp['id'])
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'transactionId': transactionId,
          'flouciStatus': 'SUCCESS',
        });

        // Add money to user account
        final result = await UserService.instance.addMoneyToUser(
          userId: topUp['userId'],
          amount: topUp['amount'],
          description: 'Wallet top-up confirmed by admin - $transactionId',
        );

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recharge confirmée avec succès!'),
              backgroundColor: FlutterFlowTheme.of(context).success,
            ),
          );
          _loadPendingTopUps(); // Refresh list
        } else {
          throw Exception(result['error']);
        }
      } catch (e) {
        AppLogger.e('Error confirming top-up',
            error: e, tag: 'WalletTopupManagement');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _rejectTopUp(String topUpId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejeter la Recharge'),
        content: Text('Êtes-vous sûr de vouloir rejeter cette recharge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('wallet_topup_requests')
            .doc(topUpId)
            .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recharge rejetée'),
            backgroundColor: FlutterFlowTheme.of(context).warning,
          ),
        );
        _loadPendingTopUps(); // Refresh list
      } catch (e) {
        AppLogger.e('Error rejecting top-up',
            error: e, tag: 'WalletTopupManagement');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
}
