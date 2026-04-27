import 'package:flutter/material.dart';
import '../../screens/shared/profile/profile_screen.dart';
import '../../screens/shared/settings/settings_screen.dart';
import '../../screens/shared/profile/edit_profile_screen.dart';
import '../../screens/shared/settings/notifications_screen.dart';
import '../../screens/teacher/teacher_dashboard_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/session_dashboard_screen.dart';

import '../../screens/teacher/teacher_notification_screen.dart';
import '../../screens/teacher/teacher_schedules_screen.dart';
import '../../screens/teacher/teacher_profile_edit_screen.dart';
import '../../screens/student/student_dashboard_screen.dart';
import '../../screens/student/student_scan_screen.dart';
import '../../screens/student/student_fingerprint_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String attendance = '/attendance';
  static const String sessionDashboard = '/session-dashboard';

  static const String teacherSchedules = '/teacher-schedules';
  static const String teacherProfileEdit = '/teacher-profile-edit';
  static const String studentDashboard = '/student-dashboard';
  static const String studentScan = '/student-scan';
  static const String teacherNotifications = '/teacher-notifications';
  static const String studentFingerprint = '/student-fingerprint';

  static Map<String, WidgetBuilder> get routes {
    return {
      profile: (context) => const ProfileScreen(),
      editProfile: (context) => const EditProfileScreen(),
      settings: (context) => const SettingsScreen(),
      notifications: (context) => const NotificationsScreen(),
      teacherDashboard: (context) => const TeacherDashboardScreen(),
      attendance: (context) => const AttendanceScreen(),
      sessionDashboard: (context) => const SessionDashboardScreen(),

      teacherSchedules: (context) => const TeacherSchedulesScreen(),
      teacherProfileEdit: (context) => const TeacherProfileEditScreen(),
      studentDashboard: (context) => const StudentDashboardScreen(),
      studentScan: (context) => const StudentScanScreen(),
      teacherNotifications: (context) => const TeacherNotificationScreen(),
      studentFingerprint: (context) => const StudentFingerprintScreen(),
    };
  }
}
