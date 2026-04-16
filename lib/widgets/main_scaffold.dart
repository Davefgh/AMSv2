import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../config/routes/app_routes.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool isAdmin;
  final bool showBackButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    this.actions,
    this.floatingActionButton,
    this.isAdmin = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Responsive(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      bottomNavigationBar: (currentIndex >= 0 && Responsive.isMobile(context))
          ? _buildBottomNavBar(context)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBackground() {
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
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
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
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.2),
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

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        _buildNavigationRail(context, extended: false),
        Expanded(
          child: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, showLogo: false),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildNavigationRail(context, extended: true),
        Expanded(
          child: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, showLogo: false),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
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

  Widget _buildHeader(BuildContext context, {bool showLogo = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 16),
              ] else if (showLogo) ...[
                Image.asset(
                  'assets/aclc_logo.png',
                  height: 40,
                  width: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shield, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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

  Widget _buildNavigationRail(BuildContext context, {required bool extended}) {
    final destinations = isAdmin ? _adminDestinations : _teacherDestinations;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        extended: extended,
        backgroundColor: Colors.transparent,
        selectedIndex: currentIndex == -1 ? null : currentIndex,
        onDestinationSelected: (index) => _onNavigate(context, index),
        indicatorColor: const Color(0xFF38BDF8).withOpacity(0.2),
        selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
        unselectedIconTheme:
            IconThemeData(color: Colors.white.withOpacity(0.4)),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
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
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
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
                      const Icon(Icons.shield, color: Colors.white),
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

  List<_NavDestination> get _adminDestinations => const [
        _NavDestination(
            Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard),
        _NavDestination(
            Icons.person_add_rounded, 'Enrollment', AppRoutes.enrollment),
        _NavDestination(Icons.class_rounded, 'Classes', AppRoutes.classes),
        _NavDestination(Icons.people_rounded, 'Users', AppRoutes.users),
      ];

  List<_NavDestination> get _teacherDestinations => const [
        _NavDestination(
            Icons.home_rounded, 'Home', AppRoutes.teacherDashboard),
        _NavDestination(
            Icons.library_books_rounded, 'Attendance', AppRoutes.attendance),
        _NavDestination(Icons.qr_code_scanner_rounded, 'Sessions', AppRoutes.sessionDashboard),
        _NavDestination(Icons.people_alt_rounded, 'Sections', AppRoutes.teacherSections),
      ];

  Widget _buildBottomNavBar(BuildContext context) {
    final destinations = isAdmin ? _adminDestinations : _teacherDestinations;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withOpacity(0.4),
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

    final destinations = isAdmin ? _adminDestinations : _teacherDestinations;
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
