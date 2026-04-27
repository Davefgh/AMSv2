import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/sizing_utils.dart';
import '../../models/student_subject_detail.dart';
import '../../widgets/skeleton_loader.dart';

class StudentSchedulesScreen extends StatefulWidget {
  const StudentSchedulesScreen({super.key});

  @override
  State<StudentSchedulesScreen> createState() => _StudentSchedulesScreenState();
}

class _StudentSchedulesScreenState extends State<StudentSchedulesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentSubjectDetail> _subjects = [];
  String _selectedDay = 'All';

  final List<String> _days = [
    'All',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

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
      final subjects = await _apiService.getStudentSubjects();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<StudentSubjectDetail> get _filteredSubjects {
    if (_selectedDay == 'All') return _subjects;
    return _subjects
        .where((s) =>
            s.schedule.displayDay.toLowerCase() == _selectedDay.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SkeletonListView(itemCount: 6)
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
                      _buildHeader(),
                      SizedBox(height: Sizing.h(24)),
                      _buildDayFilter(),
                      SizedBox(height: Sizing.h(24)),
                      _buildScheduleList(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Schedules',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(24),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: Sizing.h(8)),
        Text(
          '${_subjects.length} ${_subjects.length == 1 ? 'Subject' : 'Subjects'} Enrolled',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: Sizing.sp(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDayFilter() {
    return SizedBox(
      height: Sizing.h(40),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          return Padding(
            padding: EdgeInsets.only(right: Sizing.w(12)),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizing.w(20),
                  vertical: Sizing.h(10),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Sizing.r(12)),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF38BDF8)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: Sizing.sp(13),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    final filteredSubjects = _filteredSubjects;

    if (filteredSubjects.isEmpty) {
      return _buildEmptyState();
    }

    // Group subjects by day for better organization
    final groupedByDay = <String, List<StudentSubjectDetail>>{};
    for (var subject in filteredSubjects) {
      final day = subject.schedule.displayDay;
      groupedByDay.putIfAbsent(day, () => []).add(subject);
    }

    // Sort subjects within each day by time
    for (var subjects in groupedByDay.values) {
      subjects.sort((a, b) => a.schedule.timeIn.compareTo(b.schedule.timeIn));
    }

    // Sort days
    final sortedDays = groupedByDay.keys.toList()
      ..sort((a, b) {
        final dayOrder = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        return dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedDay == 'All')
          ...sortedDays.map((day) => _buildDaySection(day, groupedByDay[day]!))
        else
          ...filteredSubjects.map((s) => _buildSubjectCard(s)),
      ],
    );
  }

  Widget _buildDaySection(String day, List<StudentSubjectDetail> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: Sizing.h(12)),
          child: Row(
            children: [
              Container(
                width: Sizing.w(4),
                height: Sizing.h(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(Sizing.r(2)),
                ),
              ),
              SizedBox(width: Sizing.w(12)),
              Text(
                day,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Sizing.sp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: Sizing.w(8)),
              Text(
                '${subjects.length} ${subjects.length == 1 ? 'class' : 'classes'}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: Sizing.sp(13),
                ),
              ),
            ],
          ),
        ),
        ...subjects.map((s) => _buildSubjectCard(s)),
        SizedBox(height: Sizing.h(24)),
      ],
    );
  }

  Widget _buildSubjectCard(StudentSubjectDetail detail) {
    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(16)),
      width: double.infinity,
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Sizing.w(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
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
                        color: Colors.white,
                        fontSize: Sizing.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      detail.subject.code,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: Sizing.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedDay == 'All')
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.w(10), vertical: Sizing.h(4)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Sizing.r(8)),
                  ),
                  child: Text(
                    detail.schedule.displayDay,
                    style: TextStyle(
                      color: const Color(0xFF38BDF8),
                      fontSize: Sizing.sp(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Sizing.h(20)),
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time_rounded,
                '${detail.schedule.timeIn.substring(0, 5)} - ${detail.schedule.timeOut.substring(0, 5)}',
              ),
              SizedBox(width: Sizing.w(12)),
              Flexible(
                child: _buildInfoChip(
                  Icons.room_rounded,
                  detail.classroom.name,
                ),
              ),
            ],
          ),
          SizedBox(height: Sizing.h(12)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Sizing.w(6)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline_rounded,
                    size: Sizing.sp(14),
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
              SizedBox(width: Sizing.w(8)),
              Expanded(
                child: Text(
                  'Instructor: ${detail.instructor.fullName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: Sizing.sp(13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: Sizing.w(10), vertical: Sizing.h(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: Sizing.sp(14), color: Colors.white.withValues(alpha: 0.4)),
          SizedBox(width: Sizing.w(6)),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: Sizing.sp(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Sizing.w(32)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: Sizing.sp(48),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          SizedBox(height: Sizing.h(16)),
          Text(
            _selectedDay == 'All'
                ? 'No schedules found'
                : 'No classes on $_selectedDay',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: Sizing.sp(16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: Sizing.h(4)),
          Text(
            _selectedDay == 'All'
                ? 'Your class schedules will appear here.'
                : 'Try selecting a different day.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: Sizing.sp(13),
            ),
          ),
        ],
      ),
    );
  }
}
