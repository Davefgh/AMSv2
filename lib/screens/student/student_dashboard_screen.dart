import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';
import '../../utils/sizing_utils.dart';
import '../../widgets/skeleton_loader.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load any necessary data for dashboard overview
      // For now, just simulate loading
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SkeletonDashboard()
        : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF38BDF8),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.w(24), vertical: Sizing.h(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(),
                      SizedBox(height: Sizing.h(32)),
                      _buildFingerprintBanner(),
                      SizedBox(height: Sizing.h(32)),
                      _buildAttendanceStats(),
                      SizedBox(height: Sizing.h(32)),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.studentFingerprint),
      child: Container(
        padding: EdgeInsets.all(Sizing.w(16)),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Sizing.r(16)),
          border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Sizing.w(10)),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Sizing.r(12)),
              ),
              child: Icon(Icons.fingerprint_rounded,
                  color: const Color(0xFF38BDF8), size: Sizing.sp(24)),
            ),
            SizedBox(width: Sizing.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Fingerprints',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Sizing.sp(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'View your enrolled fingerprint records',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: Sizing.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: Sizing.sp(16),
          ),
        ),
        Text(
          'Ready to Learn?',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(28),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(16)),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Schedules',
                'Check your class schedules',
                Icons.calendar_today_rounded,
                const Color(0xFF38BDF8),
                () {
                  Navigator.pushNamed(context, AppRoutes.studentSchedules);
                },
              ),
            ),
            SizedBox(width: Sizing.w(16)),
            Expanded(
              child: _buildActionCard(
                'Scan QR',
                'Mark your attendance',
                Icons.qr_code_scanner_rounded,
                const Color(0xFF10B981),
                () {
                  Navigator.pushNamed(context, AppRoutes.studentScan);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Sizing.w(20)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Sizing.r(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(Sizing.w(10)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Sizing.r(12)),
              ),
              child: Icon(icon, color: color, size: Sizing.sp(24)),
            ),
            SizedBox(height: Sizing.h(16)),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: Sizing.sp(15),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Sizing.h(4)),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: Sizing.sp(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(16)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Present',
                '0',
                Colors.greenAccent,
                Icons.check_circle_outline_rounded,
              ),
            ),
            SizedBox(width: Sizing.w(16)),
            Expanded(
              child: _buildStatCard(
                'Absent',
                '0',
                Colors.redAccent,
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Sizing.sp(20)),
          ),
          SizedBox(height: Sizing.h(16)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: Sizing.sp(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: Sizing.sp(13),
            ),
          ),
        ],
      ),
    );
  }
}
