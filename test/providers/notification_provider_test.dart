import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amsv2/models/notification_model.dart';
import 'package:amsv2/providers/notification_provider.dart';

void main() {
  group('NotificationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is empty with zero unread', () {
      final state = container.read(notificationProvider);
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
    });

    test('addNotification appends notification and increments unread', () {
      final notification = NotificationModel(
        title: 'Test',
        message: 'Hello',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );

      container.read(notificationProvider.notifier).addNotification(notification);

      final state = container.read(notificationProvider);
      expect(state.notifications.length, 1);
      expect(state.notifications.first.title, 'Test');
      expect(state.unreadCount, 1);
    });

    test('addNotification appends multiple notifications', () {
      final n1 = NotificationModel(
        title: 'First',
        message: 'M1',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );
      final n2 = NotificationModel(
        title: 'Second',
        message: 'M2',
        type: 'Success',
        category: 'Attendance',
        timestamp: DateTime.now(),
      );

      container.read(notificationProvider.notifier).addNotification(n1);
      container.read(notificationProvider.notifier).addNotification(n2);

      final state = container.read(notificationProvider);
      expect(state.notifications.length, 2);
      expect(state.unreadCount, 2);
    });

    test('clearNotifications resets state', () {
      final notification = NotificationModel(
        title: 'Test',
        message: 'Hello',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );

      container.read(notificationProvider.notifier).addNotification(notification);
      container.read(notificationProvider.notifier).clearNotifications();

      final state = container.read(notificationProvider);
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
    });

    test('markAllRead keeps notifications but resets unread count', () {
      final notification = NotificationModel(
        title: 'Test',
        message: 'Hello',
        type: 'Info',
        category: 'Session',
        timestamp: DateTime.now(),
      );

      container.read(notificationProvider.notifier).addNotification(notification);
      container.read(notificationProvider.notifier).markAllRead();

      final state = container.read(notificationProvider);
      expect(state.notifications.length, 1);
      expect(state.unreadCount, 0);
    });
  });
}
