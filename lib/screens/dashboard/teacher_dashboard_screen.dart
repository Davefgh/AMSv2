import 'dart:ui';
import 'package:flutter/material.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  final Color _navy = const Color(0xFF001F3F);
  final Color _skyBlue = const Color(0xFF38BDF8);
  final Color _bgLight = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    children: [
                      _buildSectionHeader('Dashboard Overview'),
                      const SizedBox(height: 16),
                      _buildOverviewGrid(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Your Schedule'),
                      const SizedBox(height: 16),
                      _buildClassCard(
                        title: 'Mathematics 101',
                        details: 'Room 305 · 10:30 AM',
                        timer: '01:30:23',
                        icon: Icons.functions_rounded,
                        color: const Color(0xFF3B82F6),
                        isCurrent: true,
                      ),
                      const SizedBox(height: 16),
                      _buildClassCard(
                        title: 'Science 201',
                        details: 'Room 205 · 12:00 PM',
                        timer: '02:14:53',
                        icon: Icons.science_rounded,
                        color: const Color(0xFF8B5CF6),
                        isCurrent: false,
                      ),
                      const SizedBox(height: 120), // Spacing for bottom nav
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation (Glass Slab)
          _buildFloatingBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _navy.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Image.asset(
                  'assets/aclc_logo.png',
                  height: 36,
                  width: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shield_rounded, color: _navy, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Aclc Dashboard',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          _GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 14,
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded,
                  color: _navy.withValues(alpha: 0.8), size: 28),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _navy,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
            '156', 'Students', Icons.people_rounded, const Color(0xFF60A5FA)),
        _buildStatCard(
            '5', 'Classes', Icons.class_rounded, const Color(0xFF34D399)),
        _buildStatCard('92%', 'Attendance', Icons.verified_rounded,
            const Color(0xFFFBBF24)),
        _buildStatCard(
            '12', 'Teachers', Icons.person_rounded, const Color(0xFFA78BFA)),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: _navy),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String title,
    required String details,
    required String timer,
    required IconData icon,
    required Color color,
    required bool isCurrent,
  }) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent ? 'Current Session' : 'Upcoming Session',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: _navy),
                ),
                Text(
                  details,
                  style: TextStyle(
                      fontSize: 13,
                      color: _navy.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent ? _skyBlue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isCurrent
                      ? _skyBlue.withValues(alpha: 0.2)
                      : _navy.withValues(alpha: 0.1)),
            ),
            child: Text(
              timer,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isCurrent ? _skyBlue : _navy.withValues(alpha: 0.5),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: 35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.how_to_reg_rounded, 'Attend'),
            _buildNavItem(2, Icons.grid_view_rounded, 'Rooms'),
            _buildNavItem(3, Icons.people_rounded, 'Users'),
            _buildNavItem(4, Icons.person_rounded, 'Me'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _skyBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _skyBlue : _navy.withValues(alpha: 0.3),
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? _skyBlue : _navy.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.all(2), // Micro margin to prevent shadow clipping
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              // Applying Sky Blue tint to the glass surface
              color: const Color(0xFFBAE6FD).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
