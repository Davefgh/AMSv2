import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification_model.dart';

part 'notification_provider.g.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationState({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  @override
  NotificationState build() {
    return const NotificationState(notifications: [], unreadCount: 0);
  }

  void addNotification(NotificationModel notification) {
    state = state.copyWith(
      notifications: [...state.notifications, notification],
      unreadCount: state.unreadCount + 1,
    );
  }

  void clearNotifications() {
    state = const NotificationState(notifications: [], unreadCount: 0);
  }

  void markAllRead() {
    state = state.copyWith(unreadCount: 0);
  }
}
