import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../utils/sizing_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/app_provider.dart';
import 'package:intl/intl.dart';

class TeacherSchedulesScreen extends StatefulWidget {
  const TeacherSchedulesScreen({super.key});

  @override
  State<TeacherSchedulesScreen> createState() => _TeacherSchedulesScreenState();
}

class _TeacherSchedulesScreenState extends State<TeacherSchedulesScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Schedule> _schedules = [];
  String _selectedDay = 'All';

  final List<String> _days = ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final schedules = await _apiService.getMySchedules();
      setState(() {
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

  Map<String, List<Schedule>> get _groupedSchedules {
    final Map<String, List<Schedule>> grouped = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
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

  String get _todayName {
    return DateFormat('EEEE').format(DateTime.now());
  }

  List<Schedule> get _filteredSchedules {
    if (_selectedDay == 'All') {
      return _schedules;
    }
    return _groupedSchedules[_selectedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'My Schedules',
      currentIndex: 3,
      isAdmin: false,
      body: _isLoading
          ? const SkeletonDashboard()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildSchedulesList(),
    );
  }

  Widget _buildSchedulesList() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final isDark = appProvider.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
        final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final secondaryTextColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.6);

        if (_schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 64, color: secondaryTextColor),
                SizedBox(height: Sizing.h(16)),
                Text(
                  'No schedules assigned',
                  style: TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(16)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadSchedules,
          color: const Color(0xFF38BDF8),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Sizing.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(isDark, textColor, secondaryTextColor),
                SizedBox(height: Sizing.h(24)),
                _buildDayFilter(isDark, textColor, secondaryTextColor),
                SizedBox(height: Sizing.h(24)),
                _buildFilteredSchedules(isDark, cardColor, textColor, secondaryTextColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(bool isDark, Color textColor, Color secondaryTextColor) {
    final grouped = _groupedSchedules;
    final daysWithSchedules = grouped.values.where((list) => list.isNotEmpty).length;

    return Container(
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(Sizing.r(16)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.calendar_today_rounded,
            label: 'Total Schedules',
            value: '${_schedules.length}',
            color: const Color(0xFF38BDF8),
            isDark: isDark,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildSummaryItem(
            icon: Icons.event_available_rounded,
            label: 'Days',
            value: '$daysWithSchedules',
            color: const Color(0xFF34D399),
            isDark: isDark,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Sizing.w(12)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: Sizing.sp(24)),
        ),
        SizedBox(height: Sizing.h(8)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(4)),
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: Sizing.sp(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDayFilter(bool isDark, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Day',
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(14),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(12)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: EdgeInsets.only(right: Sizing.w(8)),
                child: FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  selectedColor: const Color(0xFF38BDF8),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF38BDF8) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredSchedules(bool isDark, Color cardColor, Color textColor, Color secondaryTextColor) {
    final filteredSchedules = _filteredSchedules;

    if (filteredSchedules.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Sizing.h(40)),
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: secondaryTextColor),
              SizedBox(height: Sizing.h(12)),
              Text(
                'No schedules for $_selectedDay',
                style: TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(14)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedules for $_selectedDay',
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(12)),
        ...filteredSchedules.map((schedule) => _buildScheduleCard(
          schedule,
          isDark,
          cardColor,
          textColor,
          secondaryTextColor,
        )),
      ],
    );
  }

  Widget _buildAllSchedulesByDay(bool isDark, Color cardColor, Color textColor, Color secondaryTextColor) {
    final grouped = _groupedSchedules;
    final daysOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(16)),
        ...daysOrder.map((day) {
          final daySchedules = grouped[day]!;
          if (daySchedules.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: Sizing.h(12)),
                child: Text(
                  day,
                  style: TextStyle(
                    color: textColor,
                    fontSize: Sizing.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 1,
              ),
              SizedBox(height: Sizing.h(12)),
              ...daySchedules.map((schedule) => _buildScheduleCard(
                schedule,
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              )),
              SizedBox(height: Sizing.h(16)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSchedulesByDay(bool isDark, Color cardColor, Color textColor, Color secondaryTextColor) {
    final grouped = _groupedSchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(16)),
        ...grouped.keys.map((day) {
          final daySchedules = grouped[day]!;
          if (daySchedules.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: Sizing.h(12)),
                child: Text(
                  day,
                  style: TextStyle(
                    color: textColor,
                    fontSize: Sizing.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 1,
              ),
              SizedBox(height: Sizing.h(12)),
              ...daySchedules.map((schedule) => _buildScheduleCard(
                schedule,
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              )),
              SizedBox(height: Sizing.h(16)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildScheduleCard(
    Schedule schedule,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(12)),
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Sizing.r(12)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.subjectCode,
                      style: TextStyle(
                        color: const Color(0xFF38BDF8),
                        fontSize: Sizing.sp(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Sizing.h(4)),
                    Text(
                      schedule.subjectName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: Sizing.sp(14),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizing.w(8),
                  vertical: Sizing.h(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${schedule.timeIn} - ${schedule.timeOut}',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Sizing.h(12)),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: Sizing.sp(14), color: secondaryTextColor),
              SizedBox(width: Sizing.w(6)),
              Expanded(
                child: Text(
                  schedule.classroomName,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: Sizing.sp(12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Sizing.h(8)),
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: Sizing.sp(14), color: secondaryTextColor),
              SizedBox(width: Sizing.w(6)),
              Expanded(
                child: Text(
                  schedule.sectionName,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: Sizing.sp(12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          SizedBox(height: Sizing.h(16)),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
          SizedBox(height: Sizing.h(24)),
          ElevatedButton(
            onPressed: _loadSchedules,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
