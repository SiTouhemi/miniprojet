import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iset_restaurant/widgets/safe_alert_dialog.dart';
import 'package:iset_restaurant/widgets/confirmation_row.dart';
import 'package:iset_restaurant/widgets/dialog_title.dart';

void main() {
  group('Reservation Dialog Components', () {
    testWidgets('should render reservation-style dialog without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: DialogTitle(
                title: 'Choose a Time Slot',
                icon: Icons.restaurant_menu,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reservation details:'),
                  SizedBox(height: 12.0),
                  ConfirmationRow(
                    label: 'Date:',
                    value: '15 Janvier 2024',
                  ),
                  ConfirmationRow(
                    label: 'Heure:',
                    value: '12:00 - 13:00',
                  ),
                  ConfirmationRow(
                    label: 'Type:',
                    value: 'LUNCH',
                  ),
                  ConfirmationRow(
                    label: 'Prix:',
                    value: '15.50 TND',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Confirmer'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all components render correctly
      expect(find.text('Choose a Time Slot'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.text('Reservation details:'), findsOneWidget);
      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('15 Janvier 2024'), findsOneWidget);
      expect(find.text('Heure:'), findsOneWidget);
      expect(find.text('12:00 - 13:00'), findsOneWidget);
      expect(find.text('Type:'), findsOneWidget);
      expect(find.text('LUNCH'), findsOneWidget);
      expect(find.text('Prix:'), findsOneWidget);
      expect(find.text('15.50 TND'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('should handle dialog with minimal content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: Text('Simple Title'),
              content: Text('Simple content'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Simple Title'), findsOneWidget);
      expect(find.text('Simple content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}