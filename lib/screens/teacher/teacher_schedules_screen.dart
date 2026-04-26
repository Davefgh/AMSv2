import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/user_profile.dart';
import '../../widgets/main_scaffold.dart';
import '../../utils/sizing_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/app_provider.dart';
import 'section_students_screen.dart';

class TeacherSchedulesScreen extends ConsumerStatefulWidget {
  const TeacherSchedulesScreen({super.key});

  @override
  ConsumerState<TeacherSchedulesScreen> createState() =>
      _TeacherSchedulesScreenState();
}

class _TeacherSchedulesScreenState
    extends ConsumerState<TeacherSchedulesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  UserProfile? _profile;
  List<Schedule> _schedules = [];
  final Map<String, int> _sectionStudentCounts = {};
  int _totalUniqueStudents = 0;

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
      // 1. Get Profile
      final profile = await _apiService.getMe();

      // 2. Get Schedules
      final schedules = await _apiService.getMySchedules();

      if (mounted) {
        setState(() {
          _profile = profile;
          _schedules = schedules;
          _isLoading = false;
        });
      }

      // 3. Extract unique sections like in TeacherSectionsScreen
      final Map<String, dynamic> sectionMap = {};
      for (var s in schedules) {
        final section = s.section;
        final sectionId = (section?['id'] ?? s.sectionId)?.toString();

        if (sectionId != null && sectionId.isNotEmpty) {
          sectionMap[sectionId] = section ??
              {
                'id': sectionId,
                'name': s.sectionName.isNotEmpty
                    ? s.sectionName
                    : 'Section $sectionId',
              };
        }
      }

      final sectionIds = sectionMap.keys.toList();

      // Fetch student counts in background
      for (var id in sectionIds) {
        _apiService.getStudentsBySection(id).then((students) {
          if (mounted) {
            setState(() {
              _sectionStudentCounts[id] = students.length;
            });
          }
        }).catchError((_) {});
      }

      // Calculate total unique students
      _fetchTotalUniqueStudents(sectionIds);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTotalUniqueStudents(List<String> sectionIds) async {
    final Set<String> uniqueIds = {};
    try {
      for (var id in sectionIds) {
        final students = await _apiService.getStudentsBySection(id);
        for (var s in students) {
          uniqueIds.add(s.id);
        }
      }
      if (mounted) {
        setState(() {
          _totalUniqueStudents = uniqueIds.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'My Classes',
      currentIndex: 3,
      body: _isLoading
          ? const SkeletonDashboard()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final appState = ref.watch(appProvider);
    final isDark = appState.isDarkMode;
    final sections = _getGroupedSections();

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final bgColor = isDark ? Colors.transparent : const Color(0xFFF8FAFC);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: Sizing.w(24), vertical: Sizing.h(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'My Classes',
              style: TextStyle(
                color: textColor,
                fontSize: Sizing.sp(28),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Welcome, ${_profile?.fullName ?? "Instructor"}',
              style: TextStyle(
                color: subtitleColor,
                fontSize: Sizing.sp(14),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: Sizing.h(32)),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Sections',
                    '${sections.length}',
                    Icons.book_outlined,
                    const Color(0xFF38BDF8),
                    isDark,
                  ),
                ),
                SizedBox(width: Sizing.w(16)),
                Expanded(
                  child: _buildStatCard(
                    'Total Unique Students',
                    '$_totalUniqueStudents',
                    Icons.people_outline,
                    const Color(0xFF2DD4BF),
                    isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizing.h(32)),

            // Sections Grid
            if (sections.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Sizing.h(60)),
                  child: Text(
                    'No classes found',
                    style: TextStyle(
                        color: subtitleColor, fontSize: Sizing.sp(16)),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900
                      ? 4
                      : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                  crossAxisSpacing: Sizing.w(16),
                  mainAxisSpacing: Sizing.h(16),
                  childAspectRatio: 0.82,
                ),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildSectionCard(section, isDark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(12), vertical: Sizing.h(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(8)),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: Sizing.sp(18)),
          ),
          SizedBox(width: Sizing.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF64748B),
                    fontSize: Sizing.sp(10),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Sizing.h(2)),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: Sizing.sp(18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section, bool isDark) {
    final String sectionId = section['id']?.toString() ?? '';
    final int studentCount = _sectionStudentCounts[sectionId] ?? 0;
    final int classCount = section['classCount'] ?? 0;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (sectionId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectionStudentsScreen(
                  sectionId: sectionId,
                  sectionName: section['name']?.toString() ?? 'Section',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(Sizing.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['name']?.toString() ?? 'Unknown Section',
                    style: TextStyle(
                      color: textColor,
                      fontSize: Sizing.sp(15),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Sizing.h(4)),
                  Text(
                    section['course']?.toString() ?? 'General Education',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: Sizing.sp(10),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Sizing.h(12)),
                  Wrap(
                    spacing: Sizing.w(10),
                    runSpacing: Sizing.h(4),
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined,
                              size: Sizing.sp(12),
                              color: subtitleColor.withValues(alpha: 0.6)),
                          SizedBox(width: Sizing.w(4)),
                          Text(
                            '$classCount Class${classCount > 1 ? 'es' : ''}',
                            style: TextStyle(
                                color: subtitleColor,
                                fontSize: Sizing.sp(10),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: Sizing.sp(12),
                              color: subtitleColor.withValues(alpha: 0.6)),
                          SizedBox(width: Sizing.w(4)),
                          Text(
                            '$studentCount Student${studentCount > 1 ? 's' : ''}',
                            style: TextStyle(
                                color: subtitleColor,
                                fontSize: Sizing.sp(10),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(vertical: Sizing.h(12)),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Section',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF38BDF8),
                      fontSize: Sizing.sp(12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: Sizing.w(4)),
                  Icon(Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF38BDF8),
                      size: Sizing.sp(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getGroupedSections() {
    final Map<String, Map<String, dynamic>> sectionMap = {};
    if (_schedules.isEmpty) return [];

    for (var s in _schedules) {
      final id = (s.section?['id'] ?? s.sectionId)?.toString();
      if (id == null || id.isEmpty) continue;

      final sectionName = s.sectionName;

      if (!sectionMap.containsKey(id)) {
        sectionMap[id] = {
          'id': id,
          'name': sectionName,
          'course': _getCourseName(s),
          'classCount': 0,
          'subjects': <String>{},
        };
      }

      final subjectId = s.subjectId;
      if (subjectId != null && subjectId.isNotEmpty) {
        final Set<String> subjects = sectionMap[id]!['subjects'] as Set<String>;
        subjects.add(subjectId);
        sectionMap[id]!['classCount'] = subjects.length;
      }
    }
    return sectionMap.values.toList();
  }

  String _getCourseName(Schedule s) {
    try {
      final section = s.section;
      if (section != null) {
        final course = section['course'];
        if (course != null && course is Map) {
          final name = course['name'];
          if (name != null) return name.toString();
        }
      }
    } catch (_) {}
    return 'Bachelor of Science in Computer Science';
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
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
