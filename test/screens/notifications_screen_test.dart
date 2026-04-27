import 'package:amsv2/models/notification_model.dart';
import 'package:amsv2/providers/notification_provider.dart';
import 'package:amsv2/screens/shared/settings/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(NotificationState state) {
    return ProviderScope(
      overrides: [
        notificationProvider.overrideWithValue(state),
      ],
      child: const MaterialApp(
        home: NotificationsScreen(),
      ),
    );
  }

  testWidgets('shows empty state when no runtime notifications exist',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const NotificationState(notifications: [], unreadCount: 0),
      ),
    );

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('renders current-session notifications', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        NotificationState(
          unreadCount: 1,
          notifications: [
            NotificationModel(
              title: 'Session Started',
              message: 'Data Structures session is now active.',
              type: 'Info',
              category: 'Session',
              timestamp: DateTime.now(),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Session Started'), findsOneWidget);
    expect(find.text('Data Structures session is now active.'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
  });
}
