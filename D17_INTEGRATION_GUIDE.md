# D17 Payment Integration Guide

## Overview
This guide explains how to integrate D17 payment system into your Flutter restaurant reservation app for student ticket purchases.

## What is D17?
D17 is Tunisia's national mobile payment application developed by La Poste Tunisienne. It allows users to:
- Pay bills and services
- Transfer money between e-dinar accounts
- Make QR code payments (Masterpass QR certified)
- Top up mobile credit
- Pay government fees

## Integration Strategy

### Current Implementation
We've implemented a **QR Code-based payment flow** since D17 doesn't have a publicly available API for direct integration.

### How It Works
1. **Payment Request**: User selects D17 as payment method
2. **QR Generation**: App generates a QR code containing payment details
3. **User Scans**: Student scans QR code with their D17 app
4. **Payment Processing**: Student completes payment in D17 app
5. **Status Check**: App checks payment status (manual verification for now)
6. **Reservation Creation**: Upon payment confirmation, reservation is created

## Files Created

### 1. D17PaymentService (`lib/backend/services/d17_payment_service.dart`)
- Handles QR code generation
- Manages payment requests in Firestore
- Provides payment status checking
- Supports payment cancellation

### 2. PaymentMethodSelector (`lib/components/payment_method_selector.dart`)
- UI component for choosing payment method (Wallet vs D17)
- Displays QR code for D17 payments
- Handles payment flow for both methods
- Shows payment status and expiration

### 3. TicketPurchaseExample (`lib/pages/ticket_purchase_example.dart`)
- Example implementation showing how to use the payment system
- Integrates with existing reservation service
- Handles success/error scenarios

## Setup Instructions

### 1. Update Dependencies
The integration uses existing dependencies:
- `qr_flutter` - for QR code generation
- `cloud_firestore` - for payment request storage

### 2. Firestore Security Rules
Updated rules include payment_requests collection with proper access controls.

### 3. Database Structure
New collection: `payment_requests`
```json
{
  "userId": "string",
  "amount": "number",
  "currency": "TND",
  "description": "string",
  "orderId": "string",
  "paymentMethod": "D17",
  "status": "pending|completed|expired|cancelled",
  "createdAt": "timestamp",
  "expiresAt": "timestamp",
  "transactionId": "string",
  "completedAt": "timestamp"
}
```

## Usage Example

```dart
// Show payment options
void _showPaymentOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => PaymentMethodSelector(
      amount: 5.500, // TND
      description: 'Lunch ticket',
      orderId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      user: currentUser,
      onPaymentComplete: (result) {
        if (result['success']) {
          // Create reservation with payment info
          ReservationService.instance.createReservation(
            userId: currentUser.uid,
            timeSlotId: selectedTimeSlot.id,
            mealType: 'lunch',
            paymentMethod: result['paymentMethod'],
            transactionId: result['transactionId'],
          );
        }
      },
    ),
  );
}
```

## QR Code Format
The QR code contains payment information in this format:
```
MERCHANT_ID|AMOUNT|CURRENCY|ORDER_ID|PAYMENT_REQUEST_ID
```
Example: `ISET_RESTAURANT|5.500|TND|ticket_123456|payment_req_789`

## Payment Flow States

### 1. Wallet Payment
- ✅ Instant processing
- ✅ Balance validation
- ✅ Automatic deduction

### 2. D17 Payment
- 🔄 QR code generation (15-minute expiry)
- 📱 User scans with D17 app
- ⏳ Manual status verification (for now)
- ✅ Payment confirmation

## Production Considerations

### 1. Payment Verification
Currently uses manual verification. For production, consider:
- **Webhook integration** (if D17 provides webhooks)
- **SMS notifications** for payment confirmations
- **Admin dashboard** for manual payment verification
- **Automatic expiry handling**

### 2. Security Enhancements
- Implement payment request signing
- Add merchant authentication
- Use secure QR code formats
- Implement fraud detection

### 3. User Experience
- Add payment status notifications
- Implement automatic status polling
- Show payment history
- Add refund capabilities

## Testing

### Test Scenarios
1. **Wallet Payment**: Test with sufficient/insufficient balance
2. **D17 QR Generation**: Verify QR code creation and expiry
3. **Payment Status**: Test status checking and updates
4. **Error Handling**: Test network failures and edge cases

### Mock Testing
For development, you can simulate D17 payments by:
1. Generate QR code
2. Manually update payment status in Firestore
3. Test reservation creation flow

## Next Steps

### Immediate
1. Test the integration with real D17 app
2. Set up admin dashboard for payment verification
3. Implement proper error handling

### Future Enhancements
1. Contact La Poste Tunisienne for official API access
2. Implement webhook support
3. Add payment analytics
4. Support for partial payments and refunds

## Support

For issues or questions about D17 integration:
1. Check Firestore logs for payment requests
2. Verify QR code generation
3. Test with D17 app scanning
4. Contact La Poste Tunisienne for merchant account setup

## Alternative Payment Solutions

If D17 integration proves challenging, consider:
- **Flouci**: Licensed payment facilitator in Tunisia
- **Konnect**: Tunisian payment gateway with API
- **Bank card integration**: Direct bank card processing
- **Cash payments**: With QR code for verification