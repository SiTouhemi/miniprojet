import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iset_restaurant/widgets/safe_alert_dialog.dart';
import 'package:iset_restaurant/widgets/confirmation_row.dart';
import 'package:iset_restaurant/widgets/dialog_title.dart';

void main() {
  group('SafeAlertDialog', () {
    testWidgets('should render with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: const Text('Test Title'),
              content: const Text('Test Content'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('should render without title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              content: const Text('Content Only'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Content Only'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should render without content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: const Text('Title Only'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title Only'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('ConfirmationRow', () {
    testWidgets('should display label and value correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationRow(
              label: 'Date',
              value: '2024-01-15',
            ),
          ),
        ),
      );

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('should handle long text values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationRow(
              label: 'Description',
              value: 'This is a very long description that might cause layout issues in some cases',
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      expect(find.textContaining('This is a very long'), findsOneWidget);
    });

    testWidgets('should apply custom styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationRow(
              label: 'Custom',
              value: 'Styled',
              labelStyle: const TextStyle(color: Colors.red),
              valueStyle: const TextStyle(color: Colors.blue),
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Styled'), findsOneWidget);
    });
  });

  group('ConfirmationRowTable', () {
    testWidgets('should display label and value in table format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationRowTable(
              label: 'Price',
              value: '15.50 DT',
            ),
          ),
        ),
      );

      expect(find.text('Price'), findsOneWidget);
      expect(find.text('15.50 DT'), findsOneWidget);
    });
  });

  group('DialogTitle', () {
    testWidgets('should render title without icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogTitle(
              title: 'Simple Title',
            ),
          ),
        ),
      );

      expect(find.text('Simple Title'), findsOneWidget);
    });

    testWidgets('should render title with icon in column layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogTitle(
              title: 'Title with Icon',
              icon: Icons.check_circle,
            ),
          ),
        ),
      );

      expect(find.text('Title with Icon'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should render title with icon in row layout when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogTitle(
              title: 'Row Layout Title',
              icon: Icons.info,
              useRowLayout: true,
            ),
          ),
        ),
      );

      expect(find.text('Row Layout Title'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  group('SimpleDialogTitle', () {
    testWidgets('should render simple text title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleDialogTitle(
              title: 'Simple Dialog Title',
            ),
          ),
        ),
      );

      expect(find.text('Simple Dialog Title'), findsOneWidget);
    });
  });

  group('SafeIconDialogTitle', () {
    testWidgets('should render title with icon above text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeIconDialogTitle(
              title: 'Safe Icon Title',
              icon: Icons.warning,
            ),
          ),
        ),
      );

      expect(find.text('Safe Icon Title'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });

  group('Dialog Integration', () {
    testWidgets('should render complete dialog with all components', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: DialogTitle(
                title: 'Confirmation de réservation',
                icon: Icons.restaurant,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConfirmationRow(
                    label: 'Date',
                    value: 'Lundi 15 Janvier 2024',
                  ),
                  ConfirmationRow(
                    label: 'Heure',
                    value: '12:00 - 13:00',
                  ),
                  ConfirmationRow(
                    label: 'Type de repas',
                    value: 'Déjeuner',
                  ),
                  ConfirmationRow(
                    label: 'Prix',
                    value: '15.50 DT',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all components render correctly
      expect(find.text('Confirmation de réservation'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Lundi 15 Janvier 2024'), findsOneWidget);
      expect(find.text('Heure'), findsOneWidget);
      expect(find.text('12:00 - 13:00'), findsOneWidget);
      expect(find.text('Type de repas'), findsOneWidget);
      expect(find.text('Déjeuner'), findsOneWidget);
      expect(find.text('Prix'), findsOneWidget);
      expect(find.text('15.50 DT'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('should handle dialog with varying content sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeAlertDialog(
              title: SimpleDialogTitle(
                title: 'Variable Content Test',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConfirmationRow(
                    label: 'Short',
                    value: 'OK',
                  ),
                  ConfirmationRow(
                    label: 'Very Long Label That Might Cause Issues',
                    value: 'Very Long Value That Could Potentially Cause Layout Problems',
                  ),
                  ConfirmationRow(
                    label: 'Medium',
                    value: 'Medium Value',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Variable Content Test'), findsOneWidget);
      expect(find.text('Short'), findsOneWidget);
      expect(find.text('OK'), findsAtLeastNWidgets(2)); // One in content, one in actions
      expect(find.textContaining('Very Long Label'), findsOneWidget);
      expect(find.textContaining('Very Long Value'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Medium Value'), findsOneWidget);
    });
  });
}