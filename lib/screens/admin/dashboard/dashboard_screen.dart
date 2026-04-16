import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../models/app_user.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  String _selectedPeriod = 'Monthly';
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          icon: Icon(
            Icons.notifications_active_outlined,
            color: Colors.white.withOpacity(0.55),
            size: 26,
          ),
        ),
      ],
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 12),
        children: _buildDashboardMainSections(),
      ),
    );
  }


  List<Widget> _buildDashboardMainSections() {
    return [
      const Text(
        'Overview',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 16),
      _buildStatsGrid(),
      const SizedBox(height: 32),
      const Text(
        'Attendance Overview',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 16),
      _buildAttendanceOverview(),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildStatsGrid() {
    final int total = _users.length;
    final int students =
        _users.where((u) => u.role.toLowerCase() == 'student').length;
    final int instructors = _users
        .where((u) => u.role.toLowerCase() == 'instructor' || u.role.toLowerCase() == 'teacher')
        .length;
    final int admins =
        _users.where((u) => u.role.toLowerCase() == 'admin' || u.role.toLowerCase() == 'administrator').length;

    int crossAxisCount = 2;
    if (Responsive.isDesktop(context)) {
      crossAxisCount = 4;
    } else if (Responsive.isTablet(context)) {
      crossAxisCount = 3;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          total.toString(),
          'Total Registered',
          const Color(0xFF38BDF8),
          Icons.people,
          total > 0 ? 100 : 0,
          onTap: () => Navigator.pushNamed(context, '/users'),
        ), // Sky Blue
        _buildStatCard(
          students.toString(),
          'Total Students',
          const Color(0xFF34D399),
          Icons.school,
          total > 0 ? (students * 100 ~/ total) : 0,
          onTap: () => Navigator.pushNamed(context, '/students'),
        ),
        _buildStatCard(
          instructors.toString(),
          'Total Instructors',
          const Color(0xFF60A5FA),
          Icons.person,
          total > 0 ? (instructors * 100 ~/ total) : 0,
          onTap: () => Navigator.pushNamed(context, '/instructors'),
        ), // Navy Blue
        _buildStatCard(
          admins.toString(),
          'Admins',
          const Color(0xFFA78BFA),
          Icons.admin_panel_settings,
          total > 0 ? (admins * 100 ~/ total) : 0,
        ), // Purple-ish
      ],
    );
  }


  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const Color(0xFFA78BFA);
      case 'instructor':
      case 'teacher':
        return const Color(0xFF60A5FA);
      case 'student':
        return const Color(0xFF34D399);
      default:
        return Colors.white70;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return Icons.admin_panel_settings_rounded;
      case 'instructor':
      case 'teacher':
        return Icons.person_rounded;
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.people_alt_rounded;
    }
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon,
      int percentage,
      {VoidCallback? onTap}) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Attendance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '85.4%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPeriodButton('Today', 'Today'),
                        _buildPeriodButton('Weekly', 'Weekly'),
                        _buildPeriodButton('Monthly', 'Monthly'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('100%',
                          style:
                              TextStyle(fontSize: 10, color: Colors.white70)),
                      Text('50%',
                          style:
                              TextStyle(fontSize: 10, color: Colors.white70)),
                      Text('0%',
                          style:
                              TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final data = [100, 85, 90, 95, 88, 92];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final maxHeight = 100.0;

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          data.length,
          (index) {
            final height = (data[index] / 100) * maxHeight;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                        const Color(0xFF38BDF8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
