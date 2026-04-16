import 'package:flutter/material.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/enrollment/enrollment_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/classes/classes_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/students/students_screen.dart';
import '../../screens/instructors/instructors_screen.dart';
import '../../screens/settings/notifications_screen.dart';
import '../../screens/health/health_screen.dart';
import '../../screens/teacher/teacher_dashboard_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/session_dashboard_screen.dart';
import '../../screens/teacher/teacher_sections_screen.dart';
import '../../screens/teacher/teacher_notification_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String students = '/students';
  static const String instructors = '/instructors';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String enrollment = '/enrollment';
  static const String classes = '/classes';
  static const String users = '/users';
  static const String notifications = '/notifications';
  static const String health = '/health';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String attendance = '/attendance';
  static const String sessionDashboard = '/session-dashboard';
  static const String teacherSections = '/teacher-sections';
  static const String teacherNotifications = '/teacher-notifications';

  static Map<String, WidgetBuilder> get routes {
    return {
      dashboard: (context) => const DashboardScreen(),
      profile: (context) => const ProfileScreen(),
      students: (context) => const StudentsScreen(),
      instructors: (context) => const InstructorsScreen(),
      editProfile: (context) => const EditProfileScreen(),
      settings: (context) => const SettingsScreen(),
      enrollment: (context) => const EnrollmentScreen(),
      classes: (context) => const ClassesScreen(),
      users: (context) => const UsersScreen(),
      notifications: (context) => const NotificationsScreen(),
      health: (context) => const HealthScreen(),
      teacherDashboard: (context) => const TeacherDashboardScreen(),
      attendance: (context) => const AttendanceScreen(),
      sessionDashboard: (context) => const SessionDashboardScreen(),
      teacherSections: (context) => const TeacherSectionsScreen(),
      teacherNotifications: (context) => const TeacherNotificationScreen(),
    };
  }
}
