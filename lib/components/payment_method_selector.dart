import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/services/d17_payment_service.dart';
import '/backend/services/payment_history_service.dart';
import '/backend/backend.dart';
import '/utils/app_logger.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/config/app_config.dart';

class PaymentMethodSelector extends StatefulWidget {
  final double amount;
  final String description;
  final String orderId;
  final UserRecord user;
  final Function(Map<String, dynamic>) onPaymentComplete;
  final VoidCallback? onCancel;

  const PaymentMethodSelector({
    Key? key,
    required this.amount,
    required this.description,
    required this.orderId,
    required this.user,
    required this.onPaymentComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  String selectedMethod = 'wallet';
  bool isProcessing = false;
  String? paymentRequestId;
  String? qrData;
  DateTime? qrExpiresAt;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choisir le mode de paiement',
                style: theme.headlineSmall.override(
                  fontFamily: 'Inter Tight',
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(
                  Icons.close,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.0),

          // Amount display
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.1),
                  theme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.primary.withOpacity(0.2),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Montant total',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  '${widget.amount.toStringAsFixed(AppConfig.priceDecimalPlaces)} ${AppConfig.currency}',
                  style: theme.headlineMedium.override(
                    fontFamily: 'Inter Tight',
                    color: theme.primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  widget.description,
                  style: theme.bodySmall.override(
                    fontFamily: 'Inter',
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),

          // Payment method selection
          _buildPaymentMethodTile(
            'wallet',
            'Solde Portefeuille',
            Icons.account_balance_wallet,
            '${widget.user.pocket.toStringAsFixed(AppConfig.priceDecimalPlaces)} ${AppConfig.currency} disponible',
            widget.user.pocket >= widget.amount,
            theme,
          ),
          SizedBox(height: 12.0),
          _buildPaymentMethodTile(
            'd17',
            'Paiement D17',
            Icons.qr_code_scanner,
            'Payer avec l\'application D17',
            true,
            theme,
          ),
          SizedBox(height: 20.0),

          // Payment content
          if (selectedMethod == 'wallet') _buildWalletPayment(theme),
          if (selectedMethod == 'd17') _buildD17Payment(theme),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String method,
    String title,
    IconData icon,
    String subtitle,
    bool enabled,
    FlutterFlowTheme theme,
  ) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: enabled ? () => setState(() => selectedMethod = method) : null,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.primary : theme.alternate,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          color: enabled
              ? (isSelected
                  ? theme.primary.withOpacity(0.1)
                  : theme.secondaryBackground)
              : theme.primaryBackground,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: enabled
                    ? (isSelected
                        ? theme.primary.withOpacity(0.2)
                        : theme.primaryBackground)
                    : theme.alternate,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? (isSelected ? theme.primary : theme.secondaryText)
                    : theme.secondaryText.withOpacity(0.5),
                size: 24.0,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleMedium.override(
                      fontFamily: 'Inter Tight',
                      color: enabled
                          ? theme.primaryText
                          : theme.secondaryText.withOpacity(0.5),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: enabled
                          ? theme.secondaryText
                          : theme.secondaryText.withOpacity(0.5),
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletPayment(FlutterFlowTheme theme) {
    final hasEnoughBalance = widget.user.pocket >= widget.amount;

    return Column(
      children: [
        if (!hasEnoughBalance)
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: theme.error,
                  size: 20.0,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Solde insuffisant. Veuillez recharger votre portefeuille.',
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: theme.error,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16.0),
        FFButtonWidget(
          onPressed:
              hasEnoughBalance && !isProcessing ? _processWalletPayment : null,
          text: 'Payer avec le portefeuille',
          options: FFButtonOptions(
            width: double.infinity,
            height: 50.0,
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            color: theme.success,
            textStyle: theme.titleMedium.override(
              fontFamily: 'Inter Tight',
              color: Colors.white,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
            elevation: 2.0,
            borderRadius: BorderRadius.circular(12.0),
            disabledColor: theme.secondaryText.withOpacity(0.3),
            disabledTextColor: Colors.white.withOpacity(0.7),
          ),
          showLoadingIndicator: isProcessing,
        ),
      ],
    );
  }

  Widget _buildD17Payment(FlutterFlowTheme theme) {
    return Column(
      children: [
        if (qrData != null) ...[
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Scanner avec l\'app D17',
                  style: theme.titleMedium.override(
                    fontFamily: 'Inter Tight',
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.0),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: QrImageView(
                    data: qrData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryText,
                  ),
                ),
                SizedBox(height: 16.0),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: theme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: theme.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.warning,
                        size: 16.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'Expire dans ${_getTimeRemaining()}',
                        style: theme.bodySmall.override(
                          fontFamily: 'Inter',
                          color: theme.warning,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: _cancelD17Payment,
                  text: 'Annuler',
                  options: FFButtonOptions(
                    height: 44.0,
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: theme.secondaryBackground,
                    textStyle: theme.titleSmall.override(
                      fontFamily: 'Inter Tight',
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0.0,
                    borderSide: BorderSide(
                      color: theme.alternate,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: FFButtonWidget(
                  onPressed: _checkD17PaymentStatus,
                  text: 'Vérifier le statut',
                  options: FFButtonOptions(
                    height: 44.0,
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: theme.primary,
                    textStyle: theme.titleSmall.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 2.0,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.info.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: theme.primary,
                  size: 48.0,
                ),
                SizedBox(height: 12.0),
                Text(
                  'Vous pourrez scanner un code QR avec votre application D17 pour finaliser le paiement.',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          FFButtonWidget(
            onPressed: !isProcessing ? _generateD17QR : null,
            text: 'Générer le code QR',
            options: FFButtonOptions(
              width: double.infinity,
              height: 50.0,
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
              iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
              color: theme.primary,
              textStyle: theme.titleMedium.override(
                fontFamily: 'Inter Tight',
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
              elevation: 2.0,
              borderRadius: BorderRadius.circular(12.0),
              disabledColor: theme.secondaryText.withOpacity(0.3),
              disabledTextColor: Colors.white.withOpacity(0.7),
            ),
            showLoadingIndicator: isProcessing,
          ),
        ],
      ],
    );
  }

  String _getTimeRemaining() {
    if (qrExpiresAt == null) return '';

    final remaining = qrExpiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expiré';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _processWalletPayment() async {
    setState(() => isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(Duration(seconds: 1));

      widget.onPaymentComplete({
        'success': true,
        'paymentMethod': 'wallet',
        'amount': widget.amount,
        'transactionId': 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      });
    } catch (e) {
      AppLogger.e('Wallet payment failed',
          error: e, tag: 'PaymentMethodSelector');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec du paiement: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _generateD17QR() async {
    setState(() => isProcessing = true);

    try {
      final result = await D17PaymentService.instance.generatePaymentQR(
        userId: widget.user.uid,
        amount: widget.amount,
        description: widget.description,
        orderId: widget.orderId,
      );

      if (result['success']) {
        setState(() {
          paymentRequestId = result['paymentRequestId'];
          qrData = result['qrData'];
          qrExpiresAt = DateTime.parse(result['expiresAt']);
        });
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      AppLogger.e('D17 QR generation failed',
          error: e, tag: 'PaymentMethodSelector');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de génération du code QR: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _checkD17PaymentStatus() async {
    if (paymentRequestId == null) return;

    try {
      final result = await D17PaymentService.instance
          .checkPaymentStatus(paymentRequestId!);

      if (result['success']) {
        final status = result['status'];

        if (status == 'completed') {
          widget.onPaymentComplete({
            'success': true,
            'paymentMethod': 'd17',
            'amount': widget.amount,
            'transactionId': paymentRequestId,
          });
        } else if (status == 'expired') {
          setState(() {
            qrData = null;
            paymentRequestId = null;
            qrExpiresAt = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Le code QR a expiré. Veuillez en générer un nouveau.'),
                backgroundColor: FlutterFlowTheme.of(context).warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.e('D17 status check failed',
          error: e, tag: 'PaymentMethodSelector');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de vérification du statut de paiement'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _cancelD17Payment() async {
    if (paymentRequestId != null) {
      await D17PaymentService.instance.cancelPayment(paymentRequestId!);
    }

    setState(() {
      qrData = null;
      paymentRequestId = null;
      qrExpiresAt = null;
    });
  }
}
