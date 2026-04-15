import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/user_profile.dart';
import '../../models/instructor_model.dart';
import 'attendance_screen.dart';
import 'session_dashboard_screen.dart';
import '../../widgets/main_scaffold.dart';
import '../../utils/responsive.dart';
import '../../config/routes/app_routes.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? _profile;
  Instructor? _instructor;
  List<Schedule> _schedules = [];

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
      // 1. Get logged-in user profile
      final profile = await _apiService.getMe();

      // 2. Find the matching instructor by userId
      final instructors = await _apiService.getInstructors();
      final instructor = instructors.firstWhere(
        (i) => i.userId == profile.userId,
        orElse: () => throw Exception('No instructor profile found for this account.'),
      );

      // 3. Fetch all schedules for this instructor
      final schedules = await _apiService.getSchedulesByInstructorAll(instructor.id);

      setState(() {
        _profile = profile;
        _instructor = instructor;
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Derived stats ---
  int get _totalSections => _schedules
      .map((s) => (s.section?['id'] as num?)?.toInt() ?? s.sectionId)
      .whereType<int>()
      .toSet()
      .length;
  int get _totalSubjects => _schedules
      .map((s) => (s.subject?['id'] as num?)?.toInt() ?? s.subjectId)
      .whereType<int>()
      .toSet()
      .length;
  int get _totalClasses => _schedules.length;

  String get _todayDayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  int get _todayDayOfWeek => DateTime.now().weekday; // 1=Mon, 7=Sun

  List<Schedule> get _todaySchedules => _schedules
      .where((s) => s.dayOfWeek == _todayDayOfWeek || s.dayName == _todayDayName)
      .toList()
    ..sort((a, b) => a.timeIn.compareTo(b.timeIn));

  String _formatTime(String raw) {
    if (raw.isEmpty) return '--:--';
    try {
      final parts = raw.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final suffix = h >= 12 ? 'PM' : 'AM';
      h = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Teacher Dashboard',
      currentIndex: 0,
      isAdmin: false,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final name = _instructor != null
        ? '${_instructor!.firstname} ${_instructor!.lastname}'
        : _profile?.username ?? 'Instructor';

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: _loadData,
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Overview'),
          const SizedBox(height: 16),
          _buildStatsList(),
          const SizedBox(height: 32),
          _buildSectionTitle("Today's Schedule"),
          const SizedBox(height: 4),
          Text(
            _todayDayName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 16),
          if (_todaySchedules.isEmpty)
            _buildEmptyState('No classes scheduled for today.')
          else
            ..._todaySchedules
                .map((s) => _buildScheduleCard(s, highlight: true)),
          const SizedBox(height: 32),
          _buildSectionTitle('All Schedules'),
          const SizedBox(height: 16),
          if (_schedules.isEmpty)
            _buildEmptyState('No schedules assigned yet.')
          else
            ..._schedules.map((s) => _buildScheduleCard(s, highlight: false)),
          const SizedBox(height: 40),
        ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }


  Widget _buildStatsList() {
    return Column(
      children: [
        _buildStatCard(
          '$_totalSections',
          'Sections',
          Icons.view_module_rounded,
          const Color(0xFF38BDF8),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '$_totalSubjects',
          'Subjects',
          Icons.menu_book_rounded,
          const Color(0xFF34D399),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '$_totalClasses',
          'Schedules',
          Icons.schedule_rounded,
          const Color(0xFFFBBF24),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule s, {required bool highlight}) {
    final color = highlight ? const Color(0xFF38BDF8) : const Color(0xFF60A5FA);
    final subj = s.subjectName.isNotEmpty ? s.subjectName : 'Unknown Subject';
    final room = s.classroomName.isNotEmpty ? s.classroomName : 'No Room';
    final section = s.sectionName.isNotEmpty ? s.sectionName : 'No Section';
    final day = s.displayDay;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highlight ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: highlight ? 0.35 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.schedule_rounded, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.isNotEmpty)
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    subj,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 13, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        room,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.layers_outlined,
                          size: 13, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        section,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(s.timeIn),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(s.timeOut),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
