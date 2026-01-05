import 'package:flutter_test/flutter_test.dart';
import '../../lib/student/profile/profile_widget.dart';

void main() {
  group('Profile Widget Basic Tests', () {
    test('should create ProfileWidget instance', () {
      // Test that the widget can be instantiated
      const widget = ProfileWidget();
      expect(widget, isNotNull);
      expect(widget.runtimeType, ProfileWidget);
    });

    test('should have correct route configuration', () {
      // Test route constants
      expect(ProfileWidget.routeName, equals('Profile'));
      expect(ProfileWidget.routePath, equals('/profile'));
    });
  });
}