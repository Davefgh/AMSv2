import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import '../../models/instructor_model.dart';
import '../../utils/sizing_utils.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../widgets/skeleton_loader.dart';
import '../../providers/app_provider.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

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
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
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
      final profile = await _apiService.getMe();
      if (profile.instructorProfile == null) {
        throw Exception('Instructor profile not found.');
      }
      final instructor = Instructor(
        id: profile.instructorProfile!.id,
        firstname: profile.instructorProfile!.firstname ?? 'Instructor',
        lastname: profile.instructorProfile!.lastname ?? '',
        userId: profile.userId,
        email: profile.email,
        createdAt: profile.instructorProfile!.createdAt,
        updatedAt: profile.instructorProfile!.updatedAt,
      );
      final schedules = await _apiService.getMySchedules();
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
  int get _activeClassesCount => _sessions
      .where((s) =>
          s.status.toLowerCase() == 'active' ||
          s.status.toLowerCase() == 'started')
      .length;
  int get _subjectsTaughtCount =>
      _schedules.map((s) => s.subjectId).toSet().length;

  List<ClassSession> get _activeSessions => _sessions
      .where((s) =>
          s.status.toLowerCase() == 'active' ||
          s.status.toLowerCase() == 'started')
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
    return _isLoading
        ? const SkeletonDashboard()
        : _errorMessage != null
            ? _buildErrorState()
            : _buildDashboard();
  }

  Widget _buildDashboard() {
    final appState = ref.watch(appProvider);
    final isDark = appState.isDarkMode;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.6);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF38BDF8),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Sizing.w(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, textColor, secondaryTextColor),
            SizedBox(height: Sizing.h(24)),
            _buildStatsGrid(isDark, cardColor),
            SizedBox(height: Sizing.h(24)),
            _buildTabLayout(isDark, cardColor, textColor, secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLayout(
      bool isDark, Color cardColor, Color textColor, Color secondaryTextColor) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: const Color(0xFF38BDF8),
            labelColor: const Color(0xFF38BDF8),
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                TextStyle(fontWeight: FontWeight.bold, fontSize: Sizing.sp(13)),
            tabs: const [
              Tab(text: 'ACTIVE SESSIONS'),
              Tab(text: 'WEEKLY SCHEDULE'),
            ],
          ),
          SizedBox(height: Sizing.h(20)),
          SizedBox(
            height: Sizing.h(400),
            child: TabBarView(
              children: [
                SingleChildScrollView(
                    child: _buildActiveSessionsList(
                        isDark, cardColor, textColor, secondaryTextColor)),
                SingleChildScrollView(
                    child: _buildWeeklySchedule(
                        isDark, textColor, secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color secondaryTextColor) {
    final name = _instructor != null
        ? '${_instructor!.firstname} ${_instructor!.lastname}'
        : 'Instructor';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: Sizing.r(18),
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                child: Text(
                    _instructor != null
                        ? '${_instructor!.firstname[0]}${_instructor!.lastname[0]}'
                            .toUpperCase()
                        : 'I',
                    style: TextStyle(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: Sizing.sp(12))),
              ),
              SizedBox(width: Sizing.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: Sizing.sp(16),
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: Sizing.h(2)),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: Sizing.w(8), vertical: Sizing.h(2)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('INSTRUCTOR',
                          style: TextStyle(
                              color: const Color(0xFF38BDF8),
                              fontSize: Sizing.sp(9),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: Sizing.w(12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currentTime,
                style: TextStyle(
                    color: textColor,
                    fontSize: Sizing.sp(16),
                    fontWeight: FontWeight.w900)),
            Text(_currentDate,
                style: TextStyle(
                    color: secondaryTextColor, fontSize: Sizing.sp(10))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark, Color cardColor) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1024
          ? 4
          : (constraints.maxWidth > 640 ? 4 : 2);
      final aspectRatio = constraints.maxWidth > 1024
          ? 2.0
          : (constraints.maxWidth > 640 ? 2.2 : 1.8);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Sizing.w(16),
        crossAxisSpacing: Sizing.w(16),
        childAspectRatio: aspectRatio,
        children: [
          _buildStatCard(
              'Total Sessions',
              '$_totalSessions',
              Icons.calendar_today_rounded,
              Colors.indigoAccent,
              isDark,
              cardColor),
          _buildStatCard(
              'Attendance Rate',
              '${_attendanceRate.toInt()}%',
              Icons.check_circle_outline_rounded,
              const Color(0xFF34D399),
              isDark,
              cardColor),
          _buildStatCard('Active Classes', '$_activeClassesCount',
              Icons.timer_outlined, const Color(0xFFFBBF24), isDark, cardColor),
          _buildStatCard('Subjects Taught', '$_subjectsTaughtCount',
              Icons.book_outlined, const Color(0xFF38BDF8), isDark, cardColor),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isDark, Color cardColor) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.6);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(12), vertical: Sizing.h(10)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Sizing.r(16)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Sizing.r(10)),
            ),
            child: Icon(icon, color: color, size: Sizing.sp(18)),
          ),
          SizedBox(width: Sizing.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: Sizing.sp(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Sizing.h(2)),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: Sizing.sp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsList(
      bool isDark, Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Active Sessions', isDark, textColor),
        const SizedBox(height: 16),
        if (_activeSessions.isEmpty)
          _buildEmptyState(
              'No sessions currently active.', isDark, secondaryTextColor)
        else
          ..._activeSessions.map((s) => _buildActiveSessionCard(
              s, isDark, cardColor, textColor, secondaryTextColor)),
      ],
    );
  }

  Widget _buildActiveSessionCard(ClassSession session, bool isDark,
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  Text(session.subjectCode,
                      style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Text(session.sectionName,
                      style:
                          TextStyle(color: secondaryTextColor, fontSize: 10)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ACTIVE',
                    style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(session.subjectName,
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: secondaryTextColor),
              const SizedBox(width: 6),
              Text(session.actualRoomName ?? session.scheduledRoomName,
                  style: TextStyle(color: secondaryTextColor, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: secondaryTextColor),
              const SizedBox(width: 6),
              Text(
                  'Started: ${DateFormat('h:mm a').format(session.actualStartTime ?? session.createdAt ?? DateTime.now())}',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule(
      bool isDark, Color textColor, Color secondaryTextColor) {
    final grouped = _groupedSchedules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Weekly Class Schedule', isDark, textColor),
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
                  style: TextStyle(
                      color: isToday ? const Color(0xFF38BDF8) : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              ...daySchedules.map((s) =>
                  _buildScheduleItem(s, isDark, textColor, secondaryTextColor)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildScheduleItem(
      Schedule s, bool isDark, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFF38BDF8),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.timeIn} - ${s.timeOut}',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text('${s.subjectCode} - ${s.subjectName}',
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('${s.classroomName} • ${s.sectionName}',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, Color textColor) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFF34D399), shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
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

  Widget _buildEmptyState(String msg, bool isDark, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(msg, style: TextStyle(color: secondaryTextColor)),
      ),
    );
  }
}
