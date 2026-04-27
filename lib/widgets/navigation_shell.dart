import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../screens/teacher/teacher_dashboard_screen.dart';
import '../screens/teacher/attendance_screen.dart';
import '../screens/teacher/session_dashboard_screen.dart';
import '../screens/student/student_dashboard_screen.dart';
import '../screens/student/student_scan_screen.dart';
import '../screens/shared/profile/profile_screen.dart';
import '../config/routes/app_routes.dart';
import '../utils/responsive.dart';
import '../utils/sizing_utils.dart';
import '../providers/app_provider.dart';
import '../providers/notification_provider.dart';
import 'dart:ui';

part 'navigation_shell.g.dart';

// Navigation index notifier
@riverpod
class NavigationIndex extends _$NavigationIndex {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class NavigationShell extends ConsumerWidget {
  final bool isStudent;

  const NavigationShell({
    super.key,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Sizing.init(context);
    final currentIndex = ref.watch(navigationIndexProvider);
    final appState = ref.watch(appProvider);
    final isDark = appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    // Define screens for each tab
    final List<Widget> screens = isStudent
        ? [
            const StudentDashboardScreen(),
            StudentScanScreen(isVisible: currentIndex == 1),
            const ProfileScreen(),
          ]
        : const [
            TeacherDashboardScreen(),
            AttendanceScreen(),
            SessionDashboardScreen(),
            ProfileScreen(),
          ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Responsive(
        mobile: _buildMobileLayout(context, isDark, screens, currentIndex, ref),
        tablet: _buildTabletLayout(context, isDark, screens, currentIndex, ref),
        desktop:
            _buildTabletLayout(context, isDark, screens, currentIndex, ref),
      ),
      bottomNavigationBar: Responsive.isMobile(context)
          ? _buildBottomNavBar(context, isDark, currentIndex, ref)
          : null,
    );
  }

  Widget _buildBackground(bool isDark) {
    if (!isDark) {
      return Container(color: Colors.white);
    }

    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  blurRadius: 100,
                  spreadRadius: 50,
                )
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  blurRadius: 120,
                  spreadRadius: 60,
                )
              ],
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark,
      List<Widget> screens, int currentIndex, WidgetRef ref) {
    return Stack(
      children: [
        _buildBackground(isDark),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, currentIndex, ref),
              Expanded(
                // IndexedStack keeps all screens alive
                child: IndexedStack(
                  index: currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark,
      List<Widget> screens, int currentIndex, WidgetRef ref) {
    return Row(
      children: [
        _buildNavigationRail(context, isDark, currentIndex, ref,
            extended: MediaQuery.of(context).size.width > 900),
        Expanded(
          child: Stack(
            children: [
              _buildBackground(isDark),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark, currentIndex, ref),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: IndexedStack(
                            index: currentIndex,
                            children: screens,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, int currentIndex, WidgetRef ref) {
    final textColor = isDark ? Colors.white : Colors.black;
    final titles = isStudent
        ? ['Student Dashboard', 'Scan QR', 'Profile']
        : ['Instructor Dashboard', 'Attendance', 'Sessions', 'Profile'];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Sizing.w(24),
        vertical: Sizing.h(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/aclc_logo.png',
                  height: Sizing.h(40),
                  width: Sizing.w(40),
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shield, color: textColor, size: Sizing.sp(32)),
                ),
                SizedBox(width: Sizing.w(12)),
                Expanded(
                  child: Text(
                    titles[currentIndex],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Sizing.sp(22),
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Add actions based on current screen if needed
          if (isStudent && currentIndex == 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount =
                        ref.watch(notificationProvider).unreadCount;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(notificationProvider.notifier)
                                .markAllRead();
                            Navigator.pushNamed(
                                context, AppRoutes.notifications);
                          },
                          icon: Icon(
                            unreadCount > 0
                                ? Icons.notifications_rounded
                                : Icons.notifications_none_rounded,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          splashRadius: 20,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          // Add notification icon for teachers
          if (!isStudent)
            Consumer(
              builder: (context, ref, child) {
                final unreadCount = ref.watch(notificationProvider).unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(notificationProvider.notifier).markAllRead();
                        Navigator.pushNamed(
                            context, AppRoutes.teacherNotifications);
                      },
                      icon: Icon(
                        unreadCount > 0
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      splashRadius: 20,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(
      BuildContext context, bool isDark, int currentIndex, WidgetRef ref,
      {required bool extended}) {
    final destinations =
        isStudent ? _studentDestinations : _teacherDestinations;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: NavigationRail(
        extended: extended,
        backgroundColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
        indicatorColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
        selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
        unselectedIconTheme: IconThemeData(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4)),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
        ),
        leading: extended
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/aclc_logo.png',
                      height: 32,
                      width: 32,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.shield,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AMSv2',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Image.asset(
                  'assets/aclc_logo.png',
                  height: 32,
                  width: 32,
                  errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shield,
                      color: isDark ? Colors.white : Colors.black),
                ),
              ),
        destinations: destinations
            .map((d) => NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.icon),
                  label: Text(d.label),
                ))
            .toList(),
      ),
    );
  }

  List<_NavDestination> get _teacherDestinations => const [
        _NavDestination(Icons.home_rounded, 'Home'),
        _NavDestination(Icons.library_books_rounded, 'Attendance'),
        _NavDestination(Icons.qr_code_scanner_rounded, 'Sessions'),
        _NavDestination(Icons.person_rounded, 'Profile'),
      ];

  List<_NavDestination> get _studentDestinations => const [
        _NavDestination(Icons.dashboard_rounded, 'Dashboard'),
        _NavDestination(Icons.qr_code_scanner_rounded, 'Scan'),
        _NavDestination(Icons.person_rounded, 'Profile'),
      ];

  Widget _buildBottomNavBar(
      BuildContext context, bool isDark, int currentIndex, WidgetRef ref) {
    final destinations =
        isStudent ? _studentDestinations : _teacherDestinations;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.1);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: isDark
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.4),
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
        items: destinations
            .map((d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination(this.icon, this.label);
}
