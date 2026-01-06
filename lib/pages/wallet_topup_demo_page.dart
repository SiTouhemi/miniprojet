import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '/backend/backend.dart';
import '/backend/services/flouci_payment_service.dart';
import '/backend/services/user_service.dart';
import '/utils/app_logger.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/config/app_config.dart';

class WalletTopupDemoPage extends StatefulWidget {
  const WalletTopupDemoPage({Key? key}) : super(key: key);

  @override
  State<WalletTopupDemoPage> createState() => _WalletTopupDemoPageState();
}

class _WalletTopupDemoPageState extends State<WalletTopupDemoPage> {
  double selectedAmount = 10.0;
  bool isProcessing = false;
  String? paymentUrl;
  String? paymentRequestId;
  DateTime? expiresAt;
  List<Map<String, dynamic>> pendingTopUps = [];
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;

  // Predefined amounts
  final List<double> predefinedAmounts = [5.0, 10.0, 20.0, 50.0];

  // Demo user data
  final demoUser = {
    'uid': 'demo_student_123',
    'displayName': 'Ahmed Ben Ali',
    'pocket': 25.500,
    'tickets': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadPendingTopUps();
  }

  @override
  void dispose() {
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingTopUps() async {
    // Demo pending top-ups
    setState(() {
      pendingTopUps = [
        {
          'id': 'demo_pending_1',
          'amount': 15.0,
          'status': 'pending',
          'createdAt': DateTime.now().subtract(Duration(minutes: 5)),
          'expiresAt': DateTime.now().add(Duration(minutes: 25)),
          'paymentUrl': 'https://demo-flouci.com/pay/demo123',
        }
      ];
    });
  }

  void _startPaymentStatusListener() {
    if (paymentRequestId == null) return;

    // Simulate payment completion after 10 seconds
    Timer(Duration(seconds: 10), () {
      if (mounted) {
        _showPaymentSuccessDialog();
        _clearPaymentData();
        _updateDemoBalance();
      }
    });
  }

  void _updateDemoBalance() {
    // In a real app, this would update the user's balance in Firestore
    setState(() {
      // Simulate balance update
    });
  }

  void _clearPaymentData() {
    setState(() {
      paymentUrl = null;
      paymentRequestId = null;
      expiresAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recharger le Portefeuille'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _showTopUpHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Balance Card
            _buildBalanceCard(theme),
            SizedBox(height: 24),

            // Amount Selection
            _buildAmountSelection(theme),
            SizedBox(height: 24),

            // Payment Button or QR Display
            if (paymentUrl == null)
              _buildPaymentButton(theme)
            else
              _buildPaymentQRSection(theme),

            SizedBox(height: 24),

            // Pending Top-ups
            if (pendingTopUps.isNotEmpty) _buildPendingTopUps(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(FlutterFlowTheme theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Solde Actuel',
                style: theme.titleMedium.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${(demoUser['pocket'] as double).toStringAsFixed(3)} DT',
            style: theme.displaySmall.override(
              fontFamily: 'Inter Tight',
              color: Colors.white,
              letterSpacing: 0.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.confirmation_number,
                  color: Colors.white.withOpacity(0.8), size: 16),
              SizedBox(width: 6),
              Text(
                '${demoUser['tickets']} tickets disponibles',
                style: theme.bodySmall.override(
                  fontFamily: 'Inter',
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir le montant à recharger',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter Tight',
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),

        // Predefined amounts
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: predefinedAmounts
              .map((amount) => GestureDetector(
                    onTap: () => setState(() => selectedAmount = amount),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedAmount == amount
                            ? theme.primary
                            : theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedAmount == amount
                              ? theme.primary
                              : theme.alternate,
                          width: 2,
                        ),
                        boxShadow: selectedAmount == amount
                            ? [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${amount.toStringAsFixed(0)}',
                            style: theme.headlineMedium.override(
                              fontFamily: 'Inter Tight',
                              color: selectedAmount == amount
                                  ? Colors.white
                                  : theme.primaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'DT',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: selectedAmount == amount
                                  ? Colors.white.withOpacity(0.9)
                                  : theme.secondaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),

        SizedBox(height: 16),

        // Custom amount input
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Montant personnalisé',
            hintText: 'Entrez un montant',
            suffixText: 'DT',
            prefixIcon: Icon(Icons.edit),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.alternate),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null && amount > 0) {
              setState(() => selectedAmount = amount);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaymentButton(FlutterFlowTheme theme) {
    return FFButtonWidget(
      onPressed: isProcessing ? null : _generatePayment,
      text: 'Générer le paiement - ${selectedAmount.toStringAsFixed(3)} DT',
      icon: Icon(Icons.qr_code, size: 24),
      options: FFButtonOptions(
        width: double.infinity,
        height: 56,
        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
        iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        color: theme.primary,
        textStyle: theme.titleMedium.override(
          fontFamily: 'Inter Tight',
          color: Colors.white,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w600,
        ),
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        disabledColor: theme.secondaryText.withOpacity(0.3),
        disabledTextColor: Colors.white.withOpacity(0.7),
      ),
      showLoadingIndicator: isProcessing,
    );
  }

  Widget _buildPaymentQRSection(FlutterFlowTheme theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scanner pour payer',
                style: theme.headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.success.withOpacity(0.3)),
                ),
                child: Text(
                  '${selectedAmount.toStringAsFixed(3)} DT',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: theme.success,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // QR Code
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: QrImageView(
              data: paymentUrl!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),

          SizedBox(height: 16),

          // Instructions
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.success.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scannez ce code avec votre application Flouci',
                        style: theme.bodySmall.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.autorenew, color: theme.success, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le paiement sera traité automatiquement dans 10 secondes (DEMO)',
                        style: theme.bodySmall.override(
                          fontFamily: 'Inter',
                          color: theme.success,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: _openPaymentUrl,
                  text: 'Ouvrir Flouci',
                  icon: Icon(Icons.open_in_new, size: 18),
                  options: FFButtonOptions(
                    height: 44,
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                    color: theme.success,
                    textStyle: theme.titleSmall.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: FFButtonWidget(
                  onPressed: _cancelPayment,
                  text: 'Annuler',
                  options: FFButtonOptions(
                    height: 44,
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    color: theme.secondaryBackground,
                    textStyle: theme.titleSmall.override(
                      fontFamily: 'Inter Tight',
                      color: theme.error,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0,
                    borderSide: BorderSide(color: theme.error, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTopUps(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiements en attente',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter Tight',
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...pendingTopUps.map((topUp) => _buildPendingTopUpCard(topUp, theme)),
      ],
    );
  }

  Widget _buildPendingTopUpCard(
      Map<String, dynamic> topUp, FlutterFlowTheme theme) {
    final amount = topUp['amount'] as double;
    final createdAt = topUp['createdAt'] as DateTime?;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.pending, color: theme.warning, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${amount.toStringAsFixed(3)} DT',
                  style: theme.titleMedium.override(
                    fontFamily: 'Inter Tight',
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    'Créé ${_formatDateTime(createdAt)}',
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, color: theme.primary),
            onPressed: () => _openPendingPayment(topUp),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _generatePayment() async {
    if (selectedAmount <= 0) {
      _showErrorSnackBar('Veuillez sélectionner un montant valide');
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Simulate payment generation
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        paymentUrl =
            'FLOUCI_DEMO|${selectedAmount.toStringAsFixed(3)}|TND|${demoUser['displayName']}|demo_${DateTime.now().millisecondsSinceEpoch}';
        paymentRequestId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
        expiresAt = DateTime.now().add(Duration(minutes: 30));
      });

      // Start listening for payment status changes
      _startPaymentStatusListener();

      _showSuccessSnackBar(
          'Code QR généré avec succès! Paiement sera traité automatiquement.');
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Paiement Réussi!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre recharge a été traitée avec succès.'),
            SizedBox(height: 12),
            Text('Montant: ${selectedAmount.toStringAsFixed(3)} DT'),
            Text(
                'Nouveau solde: ${((demoUser['pocket'] as double) + selectedAmount).toStringAsFixed(3)} DT'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Update demo balance
              setState(() {
                demoUser['pocket'] =
                    (demoUser['pocket'] as double) + selectedAmount;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Parfait!'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentUrl() async {
    _showSuccessSnackBar('Ouverture de Flouci... (simulation)');
  }

  void _cancelPayment() {
    _paymentStatusSubscription?.cancel();
    setState(() {
      paymentUrl = null;
      paymentRequestId = null;
      expiresAt = null;
    });
    _showSuccessSnackBar('Paiement annulé');
  }

  void _openPendingPayment(Map<String, dynamic> topUp) {
    final url = topUp['paymentUrl'] as String?;
    if (url != null) {
      setState(() {
        paymentUrl = url;
        paymentRequestId = topUp['id'];
        expiresAt = topUp['expiresAt'];
        selectedAmount = topUp['amount'];
      });
    }
  }

  void _showTopUpHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historique des recharges'),
        content: Text('Fonctionnalité de démonstration - Historique simulé'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlutterFlowTheme.of(context).success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlutterFlowTheme.of(context).error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
