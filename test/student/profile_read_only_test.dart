import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../../lib/student/profile/profile_widget.dart';
import '../../lib/flutter_flow/app_state.dart';
import '../../lib/backend/schema/user_record.dart';

// Mock classes for testing
class MockFFAppState extends Mock implements FFAppState {}
class MockUserRecord extends Mock implements UserRecord {}

void main() {
  group('Student Profile Read-Only Tests', () {
    late MockFFAppState mockAppState;
    late MockUserRecord mockUser;

    setUp(() {
      mockAppState = MockFFAppState();
      mockUser = MockUserRecord();
      
      // Setup mock user data
      when(mockUser.displayName).thenReturn('John Doe');
      when(mockUser.nom).thenReturn('John Doe');
      when(mockUser.email).thenReturn('john.doe@example.com');
      when(mockUser.phoneNumber).thenReturn('+1234567890');
      when(mockUser.classe).thenReturn('CS101');
      when(mockUser.language).thenReturn('en');
      when(mockUser.notificationsEnabled).thenReturn(true);
      when(mockUser.pocket).thenReturn(25.50);
      when(mockUser.tickets).thenReturn(5);
      
      when(mockAppState.currentUser).thenReturn(mockUser);
    });

    testWidgets('should display profile information as read-only', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FFAppState>.value(
            value: mockAppState,
            child: ProfileWidget(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that no TextFormField widgets exist (no editable fields)
      expect(find.byType(TextFormField), findsNothing);
      
      // Verify that no DropdownButtonFormField exists (no editable dropdowns)
      expect(find.byType(DropdownButtonFormField), findsNothing);
      
      // Verify that no SwitchListTile exists (no editable switches)
      expect(find.byType(SwitchListTile), findsNothing);
      
      // Verify that read-only indicator is present
      expect(find.text('Read Only'), findsOneWidget);
      
      // Verify that lock icons are present (indicating read-only fields)
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      
      // Verify that profile information is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      
      // Verify that no "Update Profile" button exists
      expect(find.text('Update Profile'), findsNothing);
      expect(find.text('Mettre à Jour le Profil'), findsNothing);
      expect(find.text('تحديث الملف الشخصي'), findsNothing);
      
      // Verify that only logout button exists (the only allowed action)
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('should display read-only notice', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FFAppState>.value(
            value: mockAppState,
            child: ProfileWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that read-only notice is displayed
      expect(
        find.text('Your profile information is managed by the administration and cannot be modified. Please contact support if you need to update your details.'),
        findsOneWidget,
      );
    });

    testWidgets('should display balance information as read-only', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FFAppState>.value(
            value: mockAppState,
            child: ProfileWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that balance is displayed but not editable
      expect(find.textContaining('25.50'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget); // tickets
    });

    testWidgets('should not allow any profile modifications', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FFAppState>.value(
            value: mockAppState,
            child: ProfileWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that there are no interactive elements except logout
      // No form submission or profile update buttons
      expect(find.text('Update'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });
  });

  group('Profile Security Tests', () {
    testWidgets('should not expose any form controllers', (WidgetTester tester) async {
      final mockAppState = MockFFAppState();
      final mockUser = MockUserRecord();
      
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.nom).thenReturn('Test User');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.phoneNumber).thenReturn('');
      when(mockUser.classe).thenReturn('');
      when(mockUser.language).thenReturn('en');
      when(mockUser.notificationsEnabled).thenReturn(true);
      when(mockUser.pocket).thenReturn(0.0);
      when(mockUser.tickets).thenReturn(0);
      
      when(mockAppState.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<FFAppState>.value(
            value: mockAppState,
            child: ProfileWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that no TextEditingController is accessible
      // This ensures no form fields can be manipulated
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}