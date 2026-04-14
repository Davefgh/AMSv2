import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/app_user.dart';
import '../../models/realtime_checkin_preference.dart';

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
  bool _realtimeCheckInEnabled = false;
  bool _notifPrefLoading = true;
  bool _notifPrefSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchRealtimeCheckinPreference();
  }

  Future<void> _fetchRealtimeCheckinPreference() async {
    setState(() => _notifPrefLoading = true);
    try {
      final pref = await _apiService.getRealtimeCheckinPreference();
      if (mounted) {
        setState(() {
          _realtimeCheckInEnabled = pref.enabled;
          _notifPrefLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notifPrefLoading = false);
    }
  }

  Future<void> _onRealtimeCheckInChanged(bool value) async {
    setState(() {
      _realtimeCheckInEnabled = value;
      _notifPrefSaving = true;
    });
    try {
      final updated = await _apiService.putRealtimeCheckinPreference(
        RealtimeCheckinPreference(enabled: value),
      );
      if (mounted) {
        setState(() {
          _realtimeCheckInEnabled = updated.enabled;
          _notifPrefSaving = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _notifPrefSaving = false);
      await _fetchRealtimeCheckinPreference();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update preference: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Stack(
        children: [
          // Background Glowing Orbs for ambiance (Navy and Sky Blue theme)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(0xFF38BDF8).withValues(alpha: 0.3), // Sky Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      blurRadius: 100,
                      spreadRadius: 50)
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
                color:
                    const Color(0xFF1E3A8A).withValues(alpha: 0.5), // Navy Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                      blurRadius: 120,
                      spreadRadius: 60)
                ],
              ),
            ),
          ),
          // Backdrop blur for the glowing orbs
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const breakpoint = 720.0;
                      final wide = constraints.maxWidth >= breakpoint;
                      final sections = _buildDashboardMainSections();

                      if (!wide) {
                        return ListView(
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          children: [
                            _buildRealtimeNotificationPanel(),
                            const SizedBox(height: 24),
                            ...sections,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 12,
                            child: ListView(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(
                                  24, 12, 12, 12),
                              children: sections,
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: ListView(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(
                                  12, 12, 24, 12),
                              children: [
                                _buildRealtimeNotificationPanel(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/aclc_logo.png',
                height: 48,
                width: 48,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Icon(
            Icons.notifications_active_outlined,
            color: Colors.white.withValues(alpha: 0.35),
            size: 26,
          ),
        ],
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
      const Text(
        'Recent User Trace',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 16),
      _buildRecentUsersList(),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildRealtimeNotificationPanel() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF38BDF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Realtime check-in alerts when attendance is recorded.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 18),
          if (_notifPrefLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Realtime check-in',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                if (_notifPrefSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                Switch.adaptive(
                  value: _realtimeCheckInEnabled,
                  activeThumbColor: const Color(0xFF38BDF8),
                  activeTrackColor:
                      const Color(0xFF38BDF8).withValues(alpha: 0.45),
                  onChanged:
                      _notifPrefSaving ? null : _onRealtimeCheckInChanged,
                ),
              ],
            ),
        ],
      ),
    );
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

    return GridView.count(
      crossAxisCount: 2,
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

  Widget _buildRecentUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }

    if (_users.isEmpty) {
      return _GlassCard(
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    // Show top 5 recent users
    final recentUsers = _users.take(5).toList();

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentUsers.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = recentUsers[index];
          final color = _getRoleColor(user.role);
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(_getRoleIcon(user.role), color: color, size: 24),
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              user.role,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, 
                color: Colors.white.withValues(alpha: 0.2), size: 14),
          );
        },
      ),
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

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 0, // Dashboard tab
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded), label: 'Enrollment'),
          BottomNavigationBarItem(
              icon: Icon(Icons.class_rounded), label: 'Classes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Users'),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/enrollment');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/classes');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/users');
          }
        },
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
