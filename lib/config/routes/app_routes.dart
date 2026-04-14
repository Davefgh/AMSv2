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
    };
  }
}
