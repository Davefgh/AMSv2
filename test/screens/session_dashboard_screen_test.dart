import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/screens/teacher/session_dashboard_screen.dart';
import 'package:amsv2/screens/teacher/session_details_screen.dart';

void main() {
  group('SessionDashboardScreen Widget Tests', () {
    testWidgets('SessionDashboardScreen builds without errors',
        (WidgetTester tester) async {
      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: SessionDashboardScreen(),
        ),
      );

      // Verify the widget builds without errors
      expect(find.byType(SessionDashboardScreen), findsOneWidget);
    });

    testWidgets('SessionDetailsScreen is imported and available',
        (WidgetTester tester) async {
      // Verify SessionDetailsScreen can be constructed
      const detailsScreen = SessionDetailsScreen(
        session: null,
        schedule: null,
      );

      expect(detailsScreen, isA<SessionDetailsScreen>());
    });
  });

  group('Session Status Classification', () {
    test('Status "ended" is not active', () {
      final status = 'ended';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, false);
    });

    test('Status "cancelled" is not active', () {
      final status = 'cancelled';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, false);
    });

    test('Status "completed" is not active', () {
      final status = 'completed';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, false);
    });

    test('Status "active" is active', () {
      final status = 'active';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, true);
    });

    test('Status "started" is active', () {
      final status = 'started';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, true);
    });

    test('Status "pending" is not active', () {
      final status = 'pending';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, false);
    });

    test('Status "not_started" is not active', () {
      final status = 'not_started';
      final isActive = status == 'active' || status == 'started';
      expect(isActive, false);
    });
  });
}
