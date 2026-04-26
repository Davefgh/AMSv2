import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';
import '../../models/schedule_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/skeleton_loader.dart';
import '../../utils/sizing_utils.dart';
import '../../providers/app_provider.dart';

class SectionStudentsScreen extends StatefulWidget {
  final String sectionId;
  final String sectionName;

  const SectionStudentsScreen({
    super.key,
    required this.sectionId,
    required this.sectionName,
  });

  @override
  State<SectionStudentsScreen> createState() => _SectionStudentsScreenState();
}

class _SectionStudentsScreenState extends State<SectionStudentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  
  List<Student> _students = [];
  List<Schedule> _schedules = [];
  String _selectedStatus = 'All'; 

  final List<String> _statusOptions = ['All', 'Regular', 'Irregular', 'Retake'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _apiService.getStudentsBySection(widget.sectionId);
      
      // Use getMySchedules and filter locally to avoid 404 on the 'by-section' endpoint
      final allSchedules = await _apiService.getMySchedules();
      final sectionSchedules = allSchedules.where((s) {
        final sId = s.sectionId ?? (s.section?['id'] as String?);
        return sId == widget.sectionId;
      }).toList();
      
      if (mounted) {
        setState(() {
          _students = students;
          _schedules = sectionSchedules;
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

  List<Student> get _filteredStudents {
    if (_selectedStatus == 'All') {
      return _students;
    } else if (_selectedStatus == 'Regular') {
      return _students.where((s) => s.isRegular).toList();
    } else if (_selectedStatus == 'Irregular') {
      return _students.where((s) => !s.isRegular).toList();
    }
    return []; // 'Retake' or others
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: widget.sectionName,
      currentIndex: -1,
      isAdmin: false,
      showBackButton: true,
      body: _isLoading
          ? const SkeletonListView()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final isDark = appProvider.isDarkMode;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B);

        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF38BDF8),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: Sizing.w(24), vertical: Sizing.h(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Header
                _buildHeader(textColor, subtitleColor),
                SizedBox(height: Sizing.h(32)),

                // Stat Cards
                _buildStatsGrid(isDark),
                SizedBox(height: Sizing.h(32)),

                // Filter Chips
                _buildFilterChips(isDark),
                SizedBox(height: Sizing.h(24)),

                // Handled Classes Section
                _buildSectionLabel('Handled Classes', isDark, textColor),
                SizedBox(height: Sizing.h(16)),
                if (_schedules.isEmpty)
                  _buildEmptyState('No classes handled in this section.')
                else
                  ..._schedules.map((s) => _buildScheduleCard(s, isDark)),

                SizedBox(height: Sizing.h(32)),

                // Students Section
                _buildSectionLabel('Home Section Students', isDark, textColor),
                SizedBox(height: Sizing.h(16)),
                if (_filteredStudents.isEmpty)
                  _buildEmptyState('No students found for this filter.')
                else
                  ..._filteredStudents.map((s) => _buildStudentCard(s, isDark)),
                
                SizedBox(height: Sizing.h(40)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor, Color subtitleColor) {
    String courseName = 'Bachelor of Science in Computer Science';
    if (_schedules.isNotEmpty) {
       try {
          final course = _schedules.first.section?['course'];
          if (course != null && course is Map) {
            courseName = course['name']?.toString() ?? courseName;
          }
       } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.sectionName,
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(32),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          courseName,
          style: TextStyle(
            color: subtitleColor,
            fontSize: Sizing.sp(14),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Handled Classes',
            '${_schedules.length}',
            Icons.book_outlined,
            const Color(0xFF6366F1),
            isDark,
          ),
        ),
        SizedBox(width: Sizing.w(16)),
        Expanded(
          child: _buildStatCard(
            'Home Section Students',
            '${_students.length}',
            Icons.people_outline,
            const Color(0xFF8B5CF6),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: Sizing.sp(22)),
          SizedBox(height: Sizing.h(12)),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
              fontSize: Sizing.sp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: Sizing.sp(24),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusOptions.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = status),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: Sizing.w(20), vertical: Sizing.h(10)),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF38BDF8) 
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF38BDF8) 
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    fontSize: Sizing.sp(13),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: Sizing.sp(18),
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule, bool isDark) {
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B);

    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(12)),
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
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
                      schedule.subjectName,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: Sizing.sp(15)),
                    ),
                    Text(
                      schedule.subjectCode,
                      style: TextStyle(color: const Color(0xFF38BDF8), fontSize: Sizing.sp(11), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                   Text(
                    '${_students.length} Students',
                    style: TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(11), fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.chevron_right_rounded, color: secondaryTextColor, size: Sizing.sp(20)),
                ],
              ),
            ],
          ),
          SizedBox(height: Sizing.h(12)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  schedule.dayName ?? 'Day',
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              SizedBox(width: Sizing.w(12)),
              Icon(Icons.access_time, size: Sizing.sp(12), color: secondaryTextColor),
              SizedBox(width: Sizing.w(4)),
              Text('${schedule.timeIn} - ${schedule.timeOut}', style: TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(11))),
              SizedBox(width: Sizing.w(16)),
              Icon(Icons.location_on_outlined, size: Sizing.sp(12), color: secondaryTextColor),
              SizedBox(width: Sizing.w(4)),
              Text(schedule.classroomName, style: TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(11))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: Sizing.h(12)),
      child: _GlassCard(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: Sizing.w(46),
              height: Sizing.w(46),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  student.firstname.isNotEmpty ? student.firstname[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: const Color(0xFF38BDF8),
                    fontSize: Sizing.sp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: Sizing.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: Sizing.sp(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Sizing.h(4)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.isRegular ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          student.isRegular ? 'REGULAR' : 'IRREGULAR',
                          style: TextStyle(
                            color: student.isRegular ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: Sizing.sp(9),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: Sizing.w(8)),
                      Expanded(
                        child: Text(
                          'ID: ${student.id.length > 8 ? "${student.id.substring(0, 8)}..." : student.id}',
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                            fontSize: Sizing.sp(10),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.info_outline_rounded, color: isDark ? Colors.white10 : Colors.black12, size: Sizing.sp(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sizing.h(40)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.white24))),
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
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(Sizing.w(16)),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
