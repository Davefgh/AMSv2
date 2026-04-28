import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/routes/app_routes.dart';
import '../../utils/sizing_utils.dart';
import '../../services/api_service.dart';
import '../../models/student_subject_detail.dart';
import '../../providers/app_provider.dart';
import '../../widgets/skeleton_loader.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentSubjectDetail> _todaySubjects = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _apiService.getStudentSubjects();

      // Get current day of week (Monday, Tuesday, etc.)
      final todayName = DateFormat('EEEE').format(DateTime.now());

      // Filter for today's classes
      final filtered = subjects.where((s) {
        return s.schedule.displayDay.trim().toLowerCase() ==
            todayName.toLowerCase();
      }).toList();

      // Sort by time
      filtered.sort((a, b) => a.schedule.timeIn.compareTo(b.schedule.timeIn));

      if (mounted) {
        setState(() {
          _todaySubjects = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(appProvider).isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final subtitleColor =
        isDark ? Colors.white60 : const Color(0xFF001F3F).withOpacity(0.5);

    if (_errorMessage != null) {
      return _buildErrorState(titleColor, subtitleColor);
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF38BDF8),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.symmetric(
            horizontal: Sizing.w(24), vertical: Sizing.h(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(titleColor, subtitleColor),
            SizedBox(height: Sizing.h(32)),

            // Current Schedule Section (Only if classes exist today)
            if (_isLoading)
              const SkeletonListView(itemCount: 1)
            else if (_todaySubjects.isNotEmpty) ...[
              _buildTodayScheduleHeader(titleColor),
              SizedBox(height: Sizing.h(16)),
              ..._todaySubjects.map((s) => _buildSubjectCard(s, isDark)),
              SizedBox(height: Sizing.h(32)),
            ],

            _buildQuickActions(isDark, titleColor),
            SizedBox(height: Sizing.h(80)), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color titleColor, Color bodyColor) {
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
              style: TextStyle(color: titleColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(Color titleColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: subtitleColor,
            fontSize: Sizing.sp(16),
          ),
        ),
        Text(
          'Ready to Learn?',
          style: TextStyle(
            color: titleColor,
            fontSize: Sizing.sp(28),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayScheduleHeader(Color titleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today\'s Classes',
          style: TextStyle(
            color: titleColor,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: Sizing.w(10), vertical: Sizing.h(4)),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(Sizing.r(8)),
          ),
          child: Text(
            DateFormat('EEEE').format(DateTime.now()),
            style: TextStyle(
              color: const Color(0xFF38BDF8),
              fontSize: Sizing.sp(11),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(StudentSubjectDetail detail, bool isDark) {
    final cardBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF001F3F).withOpacity(0.08);
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final subtitleColor =
        isDark ? Colors.white60 : const Color(0xFF001F3F).withOpacity(0.5);

    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(16)),
      width: double.infinity,
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF001F3F).withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Sizing.w(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Sizing.r(12)),
                ),
                child: Icon(Icons.book_rounded,
                    color: const Color(0xFF38BDF8), size: Sizing.sp(20)),
              ),
              SizedBox(width: Sizing.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.subject.name,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: Sizing.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      detail.subject.code,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: Sizing.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Sizing.h(16)),
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time_rounded,
                '${detail.schedule.timeIn.substring(0, 5)} - ${detail.schedule.timeOut.substring(0, 5)}',
                isDark,
              ),
              SizedBox(width: Sizing.w(12)),
              Flexible(
                child: _buildInfoChip(
                  Icons.room_rounded,
                  detail.classroom.name,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    final chipBg =
        isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F5FF);
    final textColor =
        isDark ? Colors.white70 : const Color(0xFF001F3F).withOpacity(0.7);

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: Sizing.w(10), vertical: Sizing.h(6)),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(Sizing.r(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: Sizing.sp(14),
              color: const Color(0xFF38BDF8).withOpacity(0.7)),
          SizedBox(width: Sizing.w(6)),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: Sizing.sp(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: titleColor,
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
                isDark,
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
                isDark,
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
      Color color, bool isDark, VoidCallback onTap) {
    final cardBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF001F3F).withOpacity(0.08);
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final subtitleColor =
        isDark ? Colors.white60 : const Color(0xFF001F3F).withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Sizing.w(20)),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Sizing.r(24)),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF001F3F).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(Sizing.w(10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Sizing.r(12)),
              ),
              child: Icon(icon, color: color, size: Sizing.sp(24)),
            ),
            SizedBox(height: Sizing.h(16)),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: Sizing.sp(15),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Sizing.h(4)),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: Sizing.sp(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
