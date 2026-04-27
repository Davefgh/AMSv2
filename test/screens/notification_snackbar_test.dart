import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amsv2/main.dart';
import 'package:amsv2/models/notification_model.dart';
import 'package:amsv2/services/notification_hub_service.dart';
import 'package:amsv2/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  tearDown(() {
    NotificationHubService().setOnNotification((_) {});
  });

  group('Foreground snackbar', () {
    testWidgets('displays snackbar with notification title and message',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(initialRoute: '/', initialRole: 'student'),
        ),
      );
      await tester.pumpAndSettle();

      final notification = NotificationModel(
        title: 'Attendance Recorded',
        message: 'You checked in successfully.',
        type: 'Success',
        category: 'Attendance',
        timestamp: DateTime.now(),
      );

      NotificationHubService().triggerTestNotification(notification);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Attendance Recorded: You checked in successfully.'),
        findsOneWidget,
      );
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('snackbar is floating with 4-second duration', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(initialRoute: '/', initialRole: 'student'),
        ),
      );
      await tester.pumpAndSettle();

      final notification = NotificationModel(
        title: 'Session Started',
        message: 'Class is now active.',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );

      NotificationHubService().triggerTestNotification(notification);
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.duration, const Duration(seconds: 4));
    });

    testWidgets('dismiss action hides snackbar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(initialRoute: '/', initialRole: 'student'),
        ),
      );
      await tester.pumpAndSettle();

      final notification = NotificationModel(
        title: 'Test',
        message: 'Message',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );

      NotificationHubService().triggerTestNotification(notification);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);

      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
