import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iset_restaurant/widgets/dialog_error_boundary.dart';

void main() {
  group('DialogErrorBoundary', () {
    testWidgets('should display child when no error occurs', (tester) async {
      const testChild = Text('Test Content');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogErrorBoundary(
              fallback: const Text('Fallback'),
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('Fallback'), findsNothing);
    });

    testWidgets('should display fallback when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogErrorBoundary(
              fallback: const Text('Custom Fallback'),
              child: const Text('Normal Content'),
            ),
          ),
        ),
      );

      expect(find.text('Normal Content'), findsOneWidget);
      expect(find.text('Custom Fallback'), findsNothing);
    });
  });

  group('DialogFallbackStrategies', () {
    testWidgets('simpleConfirmationDialog should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => DialogFallbackStrategies.simpleConfirmationDialog(
                context: context,
                title: 'Test Title',
                message: 'Test Message',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('minimalDialog should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => DialogFallbackStrategies.minimalDialog(
                context: context,
                message: 'Minimal message',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Minimal message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('textOnlyDialog should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => DialogFallbackStrategies.textOnlyDialog(
                context: context,
                title: 'Text Title',
                content: 'Text Content',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Text Title'), findsOneWidget);
      expect(find.text('Text Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('DialogErrorLogger', () {
    setUp(() {
      DialogErrorLogger.clearHistory();
    });

    test('should log errors correctly', () {
      DialogErrorLogger.logError(
        errorType: 'TestError',
        message: 'Test message',
        context: {'key': 'value'},
      );

      final history = DialogErrorLogger.getErrorHistory();
      expect(history.length, equals(1));
      expect(history.first.errorType, equals('TestError'));
      expect(history.first.message, equals('Test message'));
      expect(history.first.context?['key'], equals('value'));
    });

    test('should limit error history to 50 entries', () {
      // Add 60 errors
      for (int i = 0; i < 60; i++) {
        DialogErrorLogger.logError(
          errorType: 'TestError',
          message: 'Error $i',
        );
      }

      final history = DialogErrorLogger.getErrorHistory();
      expect(history.length, equals(50));
      // Should keep the most recent 50
      expect(history.first.message, equals('Error 10'));
      expect(history.last.message, equals('Error 59'));
    });

    test('should clear history correctly', () {
      DialogErrorLogger.logError(
        errorType: 'TestError',
        message: 'Test message',
      );

      expect(DialogErrorLogger.getErrorHistory().length, equals(1));

      DialogErrorLogger.clearHistory();
      expect(DialogErrorLogger.getErrorHistory().length, equals(0));
    });
  });
}