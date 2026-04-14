import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/register_user_modal.dart';
import '../../services/api_service.dart';
import '../../models/app_user.dart';
import '../../models/health_status.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _apiService = ApiService();
  List<AppUser> _users = [];
  bool _isLoading = true;
  HealthStatusResponse? _health;
  bool _healthLoading = true;
  String? _healthError;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchHealth();
  }

  Future<void> _fetchUsers() async {
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

  Future<void> _refreshUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  Future<void> _fetchHealth() async {
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    try {
      final h = await _apiService.getHealth();
      if (mounted) {
        setState(() {
          _health = h;
          _healthLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _health = null;
          _healthLoading = false;
          _healthError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Stack(
        children: [
          // Background Glowing Orbs for ambiance
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
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
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 120,
                      spreadRadius: 60)
                ],
              ),
            ),
          ),
          // Backdrop blur for the glowing orbs to look smoothly ambient
          IgnorePointer(
            ignoring: true,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF38BDF8),
                    onRefresh: () async {
                      await Future.wait([
                        _refreshUsers(),
                        _fetchHealth(),
                      ]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      children: [
                        _buildHealthStatusSection(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('User Growth'),
                        const SizedBox(height: 16),
                        _buildUserGrowthChart(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        'Role Distribution',
                        trailing: _buildAddButton(),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCards(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Recently Added'),
                      const SizedBox(height: 16),
                      _buildRecentUsersList(),
                      const SizedBox(height: 24),
                    ],
                    ),
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
                'Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'edit_profile') {
                Navigator.pushNamed(context, '/edit-profile');
              } else if (value == 'logout') {
                // Future logout implementation
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            color: const Color(0xFF1E293B), // Dark slate
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 50),
            padding: EdgeInsets.zero,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'edit_profile',
                child:
                    Text('Edit Profile', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'logout',
                child:
                    Text('Log out', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF38BDF8),
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusSection() {
    if (_healthLoading && _health == null) {
      return _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Checking API health…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_healthError != null) {
      return _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: Color(0xFFFBBF24), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Service health unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _fetchHealth,
                  child: const Text('Retry'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _healthError!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final h = _health!;
    final ok = h.overallHealthy;
    final chipColor =
        ok ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chipColor.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: chipColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.service ?? 'Attendance Monitoring API',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (h.timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        h.timestamp!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  h.status.toUpperCase(),
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (h.database != null) ...[
            const SizedBox(height: 14),
            _healthRow(
              Icons.storage_rounded,
              'Database',
              h.database!.connected
                  ? 'Connected · ${h.database!.status}'
                  : 'Not connected',
              h.database!.connected
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
            ),
          ],
          if (h.dataIntegrity != null) ...[
            const SizedBox(height: 10),
            _healthRow(
              Icons.fact_check_outlined,
              'Data integrity',
              '${h.dataIntegrity!.status} · orphaned users: ${h.dataIntegrity!.orphanedUserCount}',
              h.dataIntegrity!.isHealthy
                  ? const Color(0xFF34D399)
                  : const Color(0xFFFBBF24),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Text(
                'Soft-delete issues: students ${h.dataIntegrity!.softDeleteInconsistencies.students}, '
                'instructors ${h.dataIntegrity!.softDeleteInconsistencies.instructors}, '
                'admins ${h.dataIntegrity!.softDeleteInconsistencies.admins}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthRow(
      IconData icon, String label, String value, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label · ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const RegisterUserModal(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF38BDF8).withValues(alpha: 0.1),
        splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF38BDF8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return _GlassCard(
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Users',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _users.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: Colors.greenAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+14%',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 100,
            child: Row(
              children: [
                // Y-axis
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('10',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('5',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('0',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 16),
                // Chart
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1),
                        ),
                      ),
                      // Custom Curve Graph
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedChartPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov']
                  .map((e) => Text(e,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCards() {
    final students =
        _users.where((u) => u.role.toLowerCase() == 'student').length;
    final instructors = _users
        .where((u) => u.role.toLowerCase() == 'instructor' || u.role.toLowerCase() == 'teacher')
        .length;
    final admins =
        _users.where((u) => u.role.toLowerCase() == 'admin' || u.role.toLowerCase() == 'administrator').length;

    return Row(
      children: [
        Expanded(
            child: _buildSingleRoleCard('Students', students.toString(),
                Icons.school, const Color(0xFF34D399))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSingleRoleCard('Teachers', instructors.toString(),
                Icons.person, const Color(0xFF60A5FA))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSingleRoleCard('Admins', admins.toString(),
                Icons.admin_panel_settings, const Color(0xFFA78BFA))),
      ],
    );
  }

  Widget _buildSingleRoleCard(
      String title, String count, IconData icon, Color color) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _users.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withValues(alpha: 0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = _users[index];
          final color = _getRoleColor(user.role);

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              ),
            ),
            subtitle: Text(
              user.role,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            trailing: Text(
              'Active',
              style: TextStyle(
                color: Colors.greenAccent.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        currentIndex: 3, // Users tab
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
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/enrollment');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/classes');
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

  const _GlassCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
    );
  }
}

class _CurvedChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Smooth sample data simulating growth
    final data = [2.0, 2.5, 3.2, 4.0, 5.5, 7.0, 7.8, 8.5, 9.2, 9.8, 10.0];
    final maxData = 12.0;

    final xStep = size.width / (data.length - 1);

    path.moveTo(0, size.height - (data[0] / maxData) * size.height);

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * xStep;
      final y1 = size.height - (data[i] / maxData) * size.height;
      final x2 = (i + 1) * xStep;
      final y2 = size.height - (data[i + 1] / maxData) * size.height;

      final ctrl1X = x1 + (x2 - x1) / 2;
      final ctrl1Y = y1;
      final ctrl2X = x1 + (x2 - x1) / 2;
      final ctrl2Y = y2;

      path.cubicTo(ctrl1X, ctrl1Y, ctrl2X, ctrl2Y, x2, y2);
    }

    // Draw main line
    canvas.drawPath(path, paint);

    // Draw gradient fill below
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.4),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
