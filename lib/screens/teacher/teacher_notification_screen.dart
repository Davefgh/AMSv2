import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/main_scaffold.dart';

class TeacherNotificationScreen extends ConsumerWidget {
  const TeacherNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider).notifications;
    final isDark = ref.watch(appProvider).isDarkMode;

    return MainScaffold(
      title: 'Notifications',
      currentIndex: -1,
      showBackButton: true,
      body: _buildContent(context, ref, notifications, isDark),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      List<NotificationModel> notifications, bool isDark) {
    if (notifications.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final clearColor = isDark
        ? Colors.white.withOpacity(0.7)
        : const Color(0xFF001F3F).withOpacity(0.6);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).clearNotifications(),
                icon: Icon(Icons.clear_all, size: 18, color: clearColor),
                label: Text('Clear all', style: TextStyle(color: clearColor)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _buildNotificationCard(notifications[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isDark) {
    final iconData = _iconForCategory(notification.category);
    final color = _colorForType(notification.type);

    final cardBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF001F3F).withOpacity(0.08);
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final bodyColor = isDark
        ? Colors.white.withOpacity(0.6)
        : const Color(0xFF001F3F).withOpacity(0.55);
    final timeColor = isDark
        ? Colors.white.withOpacity(0.35)
        : const Color(0xFF001F3F).withOpacity(0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF001F3F).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.timestamp),
                  style: TextStyle(color: timeColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final iconBg = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF001F3F).withOpacity(0.05);
    final iconColor = isDark
        ? Colors.white.withOpacity(0.2)
        : const Color(0xFF001F3F).withOpacity(0.2);
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final bodyColor = isDark
        ? Colors.white.withOpacity(0.4)
        : const Color(0xFF001F3F).withOpacity(0.4);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No messages yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check-in activity and alerts will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: bodyColor, fontSize: 14),
        ),
      ],
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'qrcode':
        return Icons.qr_code_rounded;
      case 'session':
        return Icons.event_rounded;
      case 'attendance':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.greenAccent;
      case 'warning':
        return Colors.orangeAccent;
      case 'error':
        return Colors.redAccent;
      default:
        return const Color(0xFF38BDF8);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
