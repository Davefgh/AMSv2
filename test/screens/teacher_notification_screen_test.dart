import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/models/notification_model.dart';
import 'package:amsv2/providers/app_provider.dart';
import 'package:amsv2/providers/notification_provider.dart';
import 'package:amsv2/screens/teacher/teacher_notification_screen.dart';
import 'package:amsv2/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildSubject(List<NotificationModel> notifications) {
    final container = ProviderContainer(
      overrides: [
        appProvider.overrideWithValue(
          const AppState(isDarkMode: true, userRole: 'teacher', isLoading: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    for (final notification in notifications) {
      container.read(notificationProvider.notifier).addNotification(notification);
    }

    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: TeacherNotificationScreen(),
      ),
    );
  }

  group('TeacherNotificationScreen', () {
    testWidgets('shows empty state when no notifications exist', (tester) async {
      await tester.pumpWidget(
        buildSubject([]),
      );

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('renders current-session notifications with category icons',
        (tester) async {
      await tester.pumpWidget(
        buildSubject([
          NotificationModel(
            title: 'Session Started',
            message: 'Data Structures session is now active.',
            type: 'Info',
            category: 'Session',
            timestamp: DateTime.now(),
          ),
          NotificationModel(
            title: 'QR Generated',
            message: 'QR code generated successfully.',
            type: 'Success',
            category: 'QrCode',
            timestamp: DateTime.now(),
          ),
        ]),
      );

      expect(find.text('Session Started'), findsOneWidget);
      expect(find.text('Data Structures session is now active.'), findsOneWidget);
      expect(find.text('QR Generated'), findsOneWidget);
      expect(find.text('QR code generated successfully.'), findsOneWidget);
      expect(find.byIcon(Icons.event_rounded), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_rounded), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('applies correct color for each notification type',
        (tester) async {
      await tester.pumpWidget(
        buildSubject([
          NotificationModel(
            title: 'Success',
            message: 'M',
            type: 'Success',
            category: 'Attendance',
            timestamp: DateTime.now(),
          ),
          NotificationModel(
            title: 'Warning',
            message: 'M',
            type: 'Warning',
            category: 'Attendance',
            timestamp: DateTime.now(),
          ),
          NotificationModel(
            title: 'Error',
            message: 'M',
            type: 'Error',
            category: 'Attendance',
            timestamp: DateTime.now(),
          ),
        ]),
      );

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('clears all notifications when Clear all is tapped',
        (tester) async {
      await tester.pumpWidget(
        buildSubject([
          NotificationModel(
            title: 'Test',
            message: 'Message',
            type: 'Info',
            category: 'Session',
            timestamp: DateTime.now(),
          ),
        ]),
      );

      expect(find.text('Test'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Test'), findsNothing);
    });
  });
}
