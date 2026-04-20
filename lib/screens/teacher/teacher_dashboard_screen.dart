import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/user_profile.dart';
import '../../models/session_model.dart';
import '../../models/instructor_model.dart';
import 'attendance_screen.dart';
import 'session_dashboard_screen.dart';
import '../../widgets/main_scaffold.dart';
import '../../utils/responsive.dart';
import '../../config/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  List<ClassSession> _sessions = [];
  
  Timer? _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('h:mm a').format(now);
      _currentDate = DateFormat('EEEE, MMM d').format(now);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final instructor = await _apiService.getInstructorProfile();
      final schedules = await _apiService.getSchedulesByInstructorAll(instructor.id);
      final sessions = await _apiService.getMySessions();

      setState(() {
        _instructor = instructor;
        _schedules = schedules;
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Stats Calculation ---
  int get _totalSessions => _sessions.length;
  double get _attendanceRate => 100.0; // Place holder or calculate if possible
  int get _activeClassesCount => _sessions.where((s) => s.status.toLowerCase() == 'active' || s.status.toLowerCase() == 'started').length;
  int get _subjectsTaughtCount => _schedules.map((s) => s.subjectId).toSet().length;

  List<ClassSession> get _activeSessions => _sessions
      .where((s) => s.status.toLowerCase() == 'active' || s.status.toLowerCase() == 'started')
      .toList();

  Map<String, List<Schedule>> get _groupedSchedules {
    final Map<String, List<Schedule>> grouped = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
    };
    for (var s in _schedules) {
      if (s.displayDay.isNotEmpty && grouped.containsKey(s.displayDay)) {
        grouped[s.displayDay]!.add(s);
      }
    }
    // Sort each day by time
    grouped.forEach((day, list) {
      list.sort((a, b) => a.timeIn.compareTo(b.timeIn));
    });
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      isAdmin: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF38BDF8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildTabLayout(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: const Color(0xFF38BDF8),
            labelColor: const Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white38,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'ACTIVE SESSIONS'),
              Tab(text: 'WEEKLY SCHEDULE'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400, // Fixed height to prevent infinite scroll issues in some layouts
            child: TabBarView(
              children: [
                SingleChildScrollView(child: _buildActiveSessionsList()),
                SingleChildScrollView(child: _buildWeeklySchedule()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _instructor != null ? '${_instructor!.firstname} ${_instructor!.lastname}' : 'Instructor';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1E293B),
                child: Text(name[0], style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('INSTRUCTOR', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(_currentDate, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1024 ? 4 : (constraints.maxWidth > 640 ? 4 : 2);
      final aspectRatio = constraints.maxWidth > 1024 ? 1.0 : (constraints.maxWidth > 640 ? 1.1 : 1.0);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: aspectRatio,
        children: [
          _buildStatCard('Total Sessions', '$_totalSessions', Icons.calendar_today_rounded, Colors.indigoAccent),
          _buildStatCard('Attendance Rate', '${_attendanceRate.toInt()}%', Icons.check_circle_outline_rounded, const Color(0xFF34D399)),
          _buildStatCard('Active Classes', '$_activeClassesCount', Icons.timer_outlined, const Color(0xFFFBBF24)),
          _buildStatCard('Subjects Taught', '$_subjectsTaughtCount', Icons.book_outlined, const Color(0xFF38BDF8)),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildActiveSessionsList(),
        const SizedBox(height: 32),
        _buildWeeklySchedule(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildActiveSessionsList()),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: _buildWeeklySchedule()),
      ],
    );
  }

  Widget _buildActiveSessionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Active Sessions'),
        const SizedBox(height: 16),
        if (_activeSessions.isEmpty)
          _buildEmptyState('No sessions currently active.')
        else
          ..._activeSessions.map((s) => _buildActiveSessionCard(s)),
      ],
    );
  }

  Widget _buildActiveSessionCard(ClassSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.subjectCode, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(session.sectionName, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(session.subjectName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text(session.actualRoomName ?? session.scheduledRoomName, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text('Started: ${DateFormat('h:mm a').format(session.actualStartTime ?? session.createdAt ?? DateTime.now())}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final grouped = _groupedSchedules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Weekly Schedule'),
        const SizedBox(height: 16),
        ...grouped.keys.map((day) {
          final daySchedules = grouped[day]!;
          if (daySchedules.isEmpty) return const SizedBox.shrink();
          final isToday = day == DateFormat('EEEE').format(DateTime.now());
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isToday ? '$day (Today)' : day,
                  style: TextStyle(color: isToday ? const Color(0xFF38BDF8) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Divider(color: Colors.white10),
              ...daySchedules.map((s) => _buildScheduleItem(s)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule s) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.timeIn} - ${s.timeOut}', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                const SizedBox(height: 2),
                Text('${s.subjectCode} - ${s.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${s.classroomName} • ${s.sectionName}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(msg, style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
      ),
    );
  }
}
