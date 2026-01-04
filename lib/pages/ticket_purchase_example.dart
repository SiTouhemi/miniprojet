import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/services/reservation_service.dart';
import '/components/payment_method_selector.dart';
import '/utils/app_logger.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/config/app_config.dart';

class TicketPurchaseExample extends StatefulWidget {
  final TimeSlotRecord timeSlot;
  final UserRecord user;

  const TicketPurchaseExample({
    Key? key,
    required this.timeSlot,
    required this.user,
  }) : super(key: key);

  @override
  State<TicketPurchaseExample> createState() => _TicketPurchaseExampleState();
}

class _TicketPurchaseExampleState extends State<TicketPurchaseExample> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Ticket'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time slot info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          '${widget.timeSlot.startTime?.toString().substring(11, 16)} - ${widget.timeSlot.endTime?.toString().substring(11, 16)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          widget.timeSlot.mealType ?? 'Meal',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          '${widget.timeSlot.price.toStringAsFixed(3)} TND',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // User info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Name: ${widget.user.displayName ?? widget.user.nom ?? 'Unknown'}'),
                    Text('Class: ${widget.user.classe ?? 'N/A'}'),
                    Text('Wallet Balance: ${widget.user.pocket.toStringAsFixed(3)} TND'),
                  ],
                ),
              ),
            ),
            
            Spacer(),
            
            // Purchase button
            ElevatedButton(
              onPressed: isProcessing ? null : _showPaymentOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Purchase Ticket - ${widget.timeSlot.price.toStringAsFixed(3)} TND',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentMethodSelector(
          amount: widget.timeSlot.price,
          description: 'Meal ticket - ${widget.timeSlot.mealType}',
          orderId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
          user: widget.user,
          onPaymentComplete: _handlePaymentComplete,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _handlePaymentComplete(Map<String, dynamic> paymentResult) async {
    Navigator.of(context).pop(); // Close payment modal
    
    if (!paymentResult['success']) {
      _showErrorDialog('Payment failed: ${paymentResult['error']}');
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Create reservation with payment info
      final reservationResult = await ReservationService.instance.createReservation(
        userId: widget.user.uid,
        timeSlotId: widget.timeSlot.reference.id,
        mealType: widget.timeSlot.mealType ?? 'meal',
        paymentMethod: paymentResult['paymentMethod'],
        transactionId: paymentResult['transactionId'],
      );

      if (reservationResult['success']) {
        _showSuccessDialog(
          'Ticket purchased successfully!\n\n'
          'Payment Method: ${paymentResult['paymentMethod']}\n'
          'Amount: ${paymentResult['amount'].toStringAsFixed(3)} TND\n'
          'Transaction ID: ${paymentResult['transactionId']}'
        );
      } else {
        _showErrorDialog('Failed to create reservation: ${reservationResult['error']}');
      }
    } catch (e) {
      AppLogger.e('Error processing ticket purchase', error: e, tag: 'TicketPurchaseExample');
      _showErrorDialog('An error occurred while processing your purchase.');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}