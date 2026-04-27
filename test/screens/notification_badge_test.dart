import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/models/notification_model.dart';
import 'package:amsv2/providers/app_provider.dart';
import 'package:amsv2/providers/notification_provider.dart';
import 'package:amsv2/services/storage_service.dart';
import 'package:amsv2/widgets/navigation_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildSubject(int unreadCount) {
    final container = ProviderContainer(
      overrides: [
        appProvider.overrideWithValue(
          const AppState(isDarkMode: true, userRole: 'student', isLoading: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    for (var i = 0; i < unreadCount; i++) {
      container.read(notificationProvider.notifier).addNotification(
            NotificationModel(
              title: 'Notification $i',
              message: 'Message $i',
              type: 'Info',
              category: 'Session',
              timestamp: DateTime.now(),
            ),
          );
    }

    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: NavigationShell(isStudent: true),
      ),
    );
  }

  group('Notification badge', () {
    testWidgets('shows badge with unread count when notifications exist',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject(5));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });

    testWidgets(
        'hides badge and shows outline icon when no unread notifications',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject(0));
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('caps badge count at 99+', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject(150));
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });

    // TODO: Teacher badge test requires more complex setup due to NavigationShell rendering
    // Test manually or add integration test for teacher dashboard badge
  });
}
