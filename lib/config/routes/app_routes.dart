import 'package:flutter/material.dart';
import '../../screens/admin/dashboard/dashboard_screen.dart';
import '../../screens/shared/profile/profile_screen.dart';
import '../../screens/shared/settings/settings_screen.dart';
import '../../screens/admin/enrollment/enrollment_screen.dart';
import '../../screens/admin/users/users_screen.dart';
import '../../screens/admin/classes/classes_screen.dart';
import '../../screens/shared/profile/edit_profile_screen.dart';
import '../../screens/admin/students/students_screen.dart';
import '../../screens/admin/instructors/instructors_screen.dart';
import '../../screens/shared/settings/notifications_screen.dart';
import '../../screens/admin/health/health_screen.dart';
import '../../screens/teacher/teacher_dashboard_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/session_dashboard_screen.dart';
import '../../screens/teacher/teacher_sections_screen.dart';
import '../../screens/teacher/teacher_notification_screen.dart';
import '../../screens/student/student_dashboard_screen.dart';
import '../../screens/student/student_scan_screen.dart';
import '../../screens/admin/fingerprint/fingerprint_enrollment_screen.dart';
import '../../screens/student/student_fingerprint_screen.dart';

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
  static const String studentDashboard = '/student-dashboard';
  static const String studentScan = '/student-scan';
  static const String teacherNotifications = '/teacher-notifications';
  static const String fingerprintEnrollment = '/fingerprint-enrollment';
  static const String studentFingerprint = '/student-fingerprint';

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
      studentDashboard: (context) => const StudentDashboardScreen(),
      studentScan: (context) => const StudentScanScreen(),
      teacherNotifications: (context) => const TeacherNotificationScreen(),
      fingerprintEnrollment: (context) => const FingerprintEnrollmentScreen(),
      studentFingerprint: (context) => const StudentFingerprintScreen(),
    };
  }
}
