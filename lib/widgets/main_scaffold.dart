import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive.dart';
import '../utils/sizing_utils.dart';
import '../config/routes/app_routes.dart';
import '../providers/app_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool isStudent;
  final bool showBackButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    this.actions,
    this.floatingActionButton,
    this.isStudent = false,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Sizing.init(context);
    final appState = ref.watch(appProvider);
    final isDark = appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Responsive(
        mobile: _buildMobileLayout(context, isDark),
        tablet: _buildTabletLayout(context, isDark),
        desktop: _buildTabletLayout(context, isDark),
      ),
      bottomNavigationBar: (currentIndex >= 0 && Responsive.isMobile(context))
          ? _buildBottomNavBar(context, isDark)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBackground(bool isDark) {
    if (!isDark) {
      // Light mode: soft blue gradient matching navigation_shell
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF0FF),
              Color(0xFFF5F8FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
      );
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

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Stack(
      children: [
        _buildBackground(isDark),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, showLogo: true),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildNavigationRail(context, isDark,
            extended: MediaQuery.of(context).size.width > 900),
        Expanded(
          child: Stack(
            children: [
              _buildBackground(isDark),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark, showLogo: false),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: body,
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

  Widget _buildHeader(BuildContext context, bool isDark,
      {bool showLogo = true}) {
    final textColor = Colors.white; // always white — header is navy in both modes
    final headerBg = isDark ? Colors.transparent : const Color(0xFF001F3F);

    return Container(
      color: headerBg,
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
                if (showBackButton) ...[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: Sizing.sp(20)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                  SizedBox(width: Sizing.w(16)),
                ] else if (showLogo) ...[
                  Image.asset(
                    'assets/aclc_logo.png',
                    height: Sizing.h(40),
                    width: Sizing.w(40),
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.shield,
                        color: textColor,
                        size: Sizing.sp(32)),
                  ),
                  SizedBox(width: Sizing.w(12)),
                ],
                Expanded(
                  child: Text(
                    title,
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
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, bool isDark,
      {required bool extended}) {
    List<_NavDestination> destinations;
    if (isStudent) {
      destinations = _studentDestinations;
    } else {
      destinations = _teacherDestinations;
    }

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF001F3F).withValues(alpha: 0.12);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF001F3F);
    final railIconColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.5);
    final railLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        extended: extended,
        backgroundColor: Colors.transparent,
        selectedIndex: currentIndex == -1 ? null : currentIndex,
        onDestinationSelected: (index) => _onNavigate(context, index),
        indicatorColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
        selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
        unselectedIconTheme: IconThemeData(color: railIconColor),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: railLabelColor),
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
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.shield, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AMSv2',
                      style: TextStyle(
                        color: Colors.white,
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
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shield, color: Colors.white),
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
        _NavDestination(Icons.home_rounded, 'Home', AppRoutes.teacherDashboard),
        _NavDestination(
            Icons.library_books_rounded, 'Attendance', AppRoutes.attendance),
        _NavDestination(Icons.qr_code_scanner_rounded, 'Sessions',
            AppRoutes.sessionDashboard),
        _NavDestination(
            Icons.school_rounded, 'Classes', AppRoutes.teacherSchedules),
      ];

  List<_NavDestination> get _studentDestinations => const [
        _NavDestination(
            Icons.dashboard_rounded, 'Dashboard', AppRoutes.studentDashboard),
        _NavDestination(
            Icons.qr_code_scanner_rounded, 'Scan', AppRoutes.studentScan),
        _NavDestination(Icons.person_rounded, 'Profile', AppRoutes.profile),
      ];

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    List<_NavDestination> destinations;
    if (isStudent) {
      destinations = _studentDestinations;
    } else {
      destinations = _teacherDestinations;
    }

    // Navy bottom nav in both modes — consistent brand look
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF001F3F);
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFF00172E);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF001F3F).withValues(alpha: isDark ? 0.0 : 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.5),
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
        onTap: (index) => _onNavigate(context, index),
      ),
    );
  }

  void _onNavigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    List<_NavDestination> destinations;
    if (isStudent) {
      destinations = _studentDestinations;
    } else {
      destinations = _teacherDestinations;
    }

    if (index < 0 || index >= destinations.length) return;

    Navigator.pushReplacementNamed(context, destinations[index].route);
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  const _NavDestination(this.icon, this.label, this.route);
}
