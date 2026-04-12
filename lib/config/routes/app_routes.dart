import 'package:flutter/material.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/enrollment/enrollment_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/classes/classes_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String enrollment = '/enrollment';
  static const String classes = '/classes';
  static const String users = '/users';

  static Map<String, WidgetBuilder> get routes {
    return {
      dashboard: (context) => const DashboardScreen(),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),
      enrollment: (context) => const EnrollmentScreen(),
      classes: (context) => const ClassesScreen(),
      users: (context) => const UsersScreen(),
    };
  }
}
