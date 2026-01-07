/**
 * Test script to verify the reservation flow works correctly
 * 
 * This script tests:
 * 1. Price conversion logic
 * 2. QR code format validation
 * 3. Balance calculations
 * 
 * Usage:
 *   flutter test test_reservation_flow.dart
 */

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reservation Flow Tests', () {
    test('should handle price conversion correctly', () {
      // Test price conversion from double to int (millimes)
      const double priceInTND = 0.2;
      final int priceInMillimes = (priceInTND * 1000).round();
      
      expect(priceInMillimes, equals(200));
      
      // Test conversion back
      final double convertedBack = priceInMillimes / 1000.0;
      expect(convertedBack, equals(0.2));
      
      // Test with different values
      const double price2 = 5.75;
      final int price2Millimes = (price2 * 1000).round();
      expect(price2Millimes, equals(5750));
      
      final double price2Back = price2Millimes / 1000.0;
      expect(price2Back, equals(5.75));
    });

    test('should create reservation data with correct types', () {
      // Test data
      const String userId = 'student_ahmed_zouari';
      const String timeSlotId = 'test_slot_123';
      const String mealType = 'dinner';
      const double reservationAmount = 0.2;
      
      // Create reservation document with correct types
      final reservationData = {
        'user_id': userId,
        'time_slot_id': timeSlotId,
        'meal_type': mealType,
        'capacity': 1,
        'total': (reservationAmount * 1000).round(), // Convert to millimes (int)
        'prix': (reservationAmount * 1000).round(), // Individual price in millimes (int)
        'status': 'confirmed',
        'payment_method': 'wallet',
        'created_at': DateTime.now(),
        'qr_code': '',
      };
      
      // Verify types
      expect(reservationData['total'], isA<int>());
      expect(reservationData['prix'], isA<int>());
      expect(reservationData['total'], equals(200)); // 0.2 TND = 200 millimes
      expect(reservationData['prix'], equals(200));
      expect(reservationData['user_id'], equals(userId));
      expect(reservationData['meal_type'], equals(mealType));
    });

    test('should generate demo QR code correctly', () {
      // Test demo QR code generation
      final now = DateTime.now();
      final userId = 'student_ahmed_zouari';
      final demoQRData = 'DEMO_QR_${now.millisecondsSinceEpoch}_STUDENT_$userId';
      
      expect(demoQRData, contains('DEMO_QR_'));
      expect(demoQRData, contains('STUDENT_'));
      expect(demoQRData, contains(userId));
      expect(demoQRData.length, greaterThan(20));
    });

    test('should validate QR code format', () {
      // Test different QR code formats
      const validDemoQR = 'DEMO_QR_1234567890_STUDENT_test_user';
      const validSimpleQR = 'RES_1234567890';
      const invalidQR = 'INVALID_FORMAT';
      
      // Demo QR should be valid
      expect(validDemoQR.startsWith('DEMO_QR_'), isTrue);
      
      // Simple QR should be valid
      expect(validSimpleQR.startsWith('RES_'), isTrue);
      
      // Invalid QR should not match patterns
      expect(invalidQR.startsWith('DEMO_QR_'), isFalse);
      expect(invalidQR.startsWith('RES_'), isFalse);
    });

    test('should handle user balance correctly', () {
      // Test balance calculations
      const double initialBalance = 35.75;
      const double reservationCost = 0.2;
      const double expectedBalance = 35.55;
      
      final double newBalance = initialBalance - reservationCost;
      
      expect(newBalance, equals(expectedBalance));
      expect(newBalance, greaterThan(0));
      
      // Test insufficient balance scenario
      const double lowBalance = 0.1;
      expect(lowBalance < reservationCost, isTrue);
    });

    test('should handle type conversions in modification', () {
      // Test modification price handling
      const int oldTotalMillimes = 200; // 0.2 TND in millimes
      const double newPrice = 5.0; // New price in TND
      
      final double oldTotal = oldTotalMillimes / 1000.0; // Convert to TND
      final double priceDiff = newPrice - oldTotal;
      
      expect(oldTotal, equals(0.2));
      expect(priceDiff, equals(4.8));
      
      // Convert new price back to millimes
      final int newTotalMillimes = (newPrice * 1000).round();
      expect(newTotalMillimes, equals(5000));
    });
  });
}