/**
 * Test script to verify price conversion works correctly
 * 
 * This script tests the conversion between TND and millimes
 * for the ReservationRecord schema updates.
 * 
 * Usage:
 *   flutter test test_price_conversion.dart
 */

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Price Conversion Tests', () {
    test('should convert TND to millimes correctly', () {
      // Test common price values
      const double price1 = 0.2; // 200 millimes
      const double price2 = 5.75; // 5750 millimes
      const double price3 = 12.0; // 12000 millimes
      
      final int millimes1 = (price1 * 1000).round();
      final int millimes2 = (price2 * 1000).round();
      final int millimes3 = (price3 * 1000).round();
      
      expect(millimes1, equals(200));
      expect(millimes2, equals(5750));
      expect(millimes3, equals(12000));
    });
    
    test('should convert millimes to TND correctly', () {
      // Test conversion back to TND for display
      const int millimes1 = 200; // 0.2 TND
      const int millimes2 = 5750; // 5.75 TND
      const int millimes3 = 12000; // 12.0 TND
      
      final double tnd1 = millimes1 / 1000.0;
      final double tnd2 = millimes2 / 1000.0;
      final double tnd3 = millimes3 / 1000.0;
      
      expect(tnd1, equals(0.2));
      expect(tnd2, equals(5.75));
      expect(tnd3, equals(12.0));
    });
    
    test('should format prices correctly for display', () {
      // Test price formatting
      const int millimes = 200; // 0.2 TND
      final double tnd = millimes / 1000.0;
      final String formatted = '${tnd.toStringAsFixed(2)} TND';
      
      expect(formatted, equals('0.20 TND'));
      
      // Test with larger amount
      const int millimes2 = 5750; // 5.75 TND
      final double tnd2 = millimes2 / 1000.0;
      final String formatted2 = '${tnd2.toStringAsFixed(2)} TND';
      
      expect(formatted2, equals('5.75 TND'));
    });
    
    test('should handle schema conversion logic', () {
      // Simulate the schema conversion logic
      Map<String, dynamic> testData = {
        'prix': 0.2, // Old format (double in TND)
        'total': 0.2,
      };
      
      // Convert like the schema does
      int convertedPrix;
      int convertedTotal;
      
      final prixValue = testData['prix'];
      if (prixValue is double) {
        convertedPrix = (prixValue * 1000).round();
      } else {
        convertedPrix = prixValue as int;
      }
      
      final totalValue = testData['total'];
      if (totalValue is double) {
        convertedTotal = (totalValue * 1000).round();
      } else {
        convertedTotal = totalValue as int;
      }
      
      expect(convertedPrix, equals(200));
      expect(convertedTotal, equals(200));
      
      // Test with already converted data
      Map<String, dynamic> newData = {
        'prix': 200, // New format (int in millimes)
        'total': 200,
      };
      
      final prixValue2 = newData['prix'];
      int convertedPrix2;
      if (prixValue2 is double) {
        convertedPrix2 = (prixValue2 * 1000).round();
      } else {
        convertedPrix2 = prixValue2 as int;
      }
      
      expect(convertedPrix2, equals(200)); // Should remain unchanged
    });
    
    test('should handle edge cases', () {
      // Test zero values
      const double zeroTND = 0.0;
      final int zeroMillimes = (zeroTND * 1000).round();
      expect(zeroMillimes, equals(0));
      
      // Test very small values
      const double smallTND = 0.001;
      final int smallMillimes = (smallTND * 1000).round();
      expect(smallMillimes, equals(1));
      
      // Test large values
      const double largeTND = 999.99;
      final int largeMillimes = (largeTND * 1000).round();
      expect(largeMillimes, equals(999990));
    });
  });
}