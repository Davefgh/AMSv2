import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import '../../models/instructor_model.dart';
import 'session_details_screen.dart';
import 'dart:ui';

class SessionDashboardScreen extends StatefulWidget {
  const SessionDashboardScreen({super.key});

  @override
  State<SessionDashboardScreen> createState() => _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends State<SessionDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<Schedule> _instructorSchedules = [];
  List<ClassSession> _upcomingSessions = [];
  List<ClassSession> _filteredSessions = [];
  Schedule? _selectedSchedule;
  Map<int, Schedule> _scheduleMap = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;
  String _currentTime = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startClock();
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final schedules = await _apiService.getMySchedules();
      final mySessions = await _apiService.getMySessions();

      setState(() {
        _instructorSchedules = schedules;
        _upcomingSessions = mySessions;
        _filteredSessions = mySessions;
        
        _scheduleMap = {for (var s in schedules) s.id: s};
        
        if (_instructorSchedules.isNotEmpty) {
          _selectedSchedule = _findNearestSchedule(schedules);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Schedule? _findNearestSchedule(List<Schedule> schedules) {
    if (schedules.isEmpty) return null;
    
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final currentTimeStr = DateFormat('HH:mm:ss').format(now);
    
    final todaySchedules = schedules.where((s) => s.dayOfWeek == todayWeekday).toList();
    if (todaySchedules.isNotEmpty) {
      todaySchedules.sort((a, b) => a.timeIn.compareTo(b.timeIn));
      for (var s in todaySchedules) {
        if (s.timeIn.compareTo(currentTimeStr) <= 0 && s.timeOut.compareTo(currentTimeStr) >= 0) {
          return s;
        }
        if (s.timeIn.compareTo(currentTimeStr) > 0) {
          return s;
        }
      }
      return todaySchedules.first;
    }
    
    return schedules.first;
  }

  void _filterSessions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSessions = _upcomingSessions;
      } else {
        _filteredSessions = _upcomingSessions.where((s) {
          final title = (s.subjectName.isNotEmpty ? s.subjectName : 'Software Engineering 1').toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _handleCreateSession() {
    if (_selectedSchedule == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsScreen(schedule: _selectedSchedule),
      ),
    ).then((_) {
      _loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildCreateSessionCard(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Schedules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    _buildViewToggle(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF38BDF8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_filteredSessions.length}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 24),
            if (_filteredSessions.isEmpty)
              _buildEmptyState()
            else if (_isGridView)
              _buildGridView()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSessions.length,
                itemBuilder: (context, index) => _buildUpcomingSessionCard(_filteredSessions[index]),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildClock() {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      onTap: () {}, // Make it clickable or just visual
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Current Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            _currentTime,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(Icons.list_rounded, !_isGridView),
          _buildToggleItem(Icons.grid_view_rounded, _isGridView),
        ],
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isGridView = icon == Icons.grid_view_rounded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFF0F172A) : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSessions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 175,
      ),
      itemBuilder: (context, index) => _buildUpcomingSessionGridItem(_filteredSessions[index]),
    );
  }

  Widget _buildUpcomingSessionGridItem(ClassSession s) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_rounded, color: Color(0xFF38BDF8), size: 18),
          ),
          const Spacer(),
          Text(
            s.subjectName.isNotEmpty ? s.subjectName : 'Software Engineering 1',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(_scheduleMap[s.scheduleId]?.timeIn ?? '10:00:00'),
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 4),
              Text(
                _sessionDateLabel(s.sessionDate),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSessionCard() {
    return _GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Session',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a schedule to begin.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 32),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned Schedule',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildScheduleDropdown(),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildClockSection(),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleCreateSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Create Session',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockSection() {
    return Column(
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'Courier',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Schedule>(
          value: _selectedSchedule,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white30),
          items: _instructorSchedules.map((Schedule s) {
            return DropdownMenuItem<Schedule>(
              value: s,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.subjectName} (${s.sectionName})',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedSchedule?.id == s.id)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 16),
                ],
              ),
            );
          }).toList(),
          onChanged: (Schedule? newValue) {
            setState(() => _selectedSchedule = newValue);
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSessions,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search sessions...',
          hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: Colors.white24, size: 20),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionCard(ClassSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s)),
          );
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.subjectName.isNotEmpty ? s.subjectName : 'Software Engineering 1',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 4),
                      Text(
                        _sessionDateLabel(s.sessionDate),
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
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
                  _formatTime(_scheduleMap[s.scheduleId]?.timeIn ?? '10:00:00'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDurationText(_scheduleMap[s.scheduleId]),
                  style: TextStyle(
                    color: const Color(0xFF38BDF8).withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sessionDateLabel(DateTime? date) {
    if (date == null) return 'No Date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

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

  String _getDurationText(Schedule? s) {
    if (s == null) return '45 min';
    try {
      final t1 = s.timeIn.split(':').map((e) => int.parse(e)).toList();
      final t2 = s.timeOut.split(':').map((e) => int.parse(e)).toList();
      final start = DateTime(2000, 1, 1, t1[0], t1[1]);
      final end = DateTime(2000, 1, 1, t2[0], t2[1]);
      final diff = end.difference(start).inMinutes;
      return '$diff min';
    } catch (_) {
      return '45 min';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.calendar_today_rounded, size: 48, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              'No upcoming schedules for today.',
              style: TextStyle(color: Colors.white24),
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
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
