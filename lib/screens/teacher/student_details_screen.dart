import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/attendance_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/fingerprint_enrollment_modal.dart';
import '../../utils/sizing_utils.dart';
import '../../providers/app_provider.dart';

class StudentDetailsScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String? sectionName;

  const StudentDetailsScreen({
    super.key,
    required this.studentId,
    this.sectionName,
  });

  @override
  ConsumerState<StudentDetailsScreen> createState() =>
      _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends ConsumerState<StudentDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  Student? _student;
  List<Enrollment> _enrollments = [];
  List<AttendanceRecord> _attendanceRecords = [];
  List<dynamic> _fingerprints = []; // FingerprintInfo list

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
      final student = await _apiService.getStudent(widget.studentId);

      List<Enrollment> enrollments = [];
      try {
        enrollments =
            await _apiService.getEnrollmentsByStudent(widget.studentId);
      } catch (_) {}

      List<AttendanceRecord> attendanceRecords = [];
      try {
        attendanceRecords =
            await _apiService.getAttendanceByStudent(widget.studentId);
      } catch (_) {}

      List<dynamic> fingerprints = [];
      try {
        fingerprints =
            await _apiService.getFingerprintsByStudent(widget.studentId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _student = student;
          _enrollments = enrollments;
          _attendanceRecords = attendanceRecords;
          _fingerprints = fingerprints;
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

  int get _totalSessions {
    // Count unique sessions from attendance records
    return _attendanceRecords.map((a) => a.sessionId).toSet().length;
  }

  int get _presentCount {
    return _attendanceRecords
        .where((a) => a.status.toLowerCase() == 'present')
        .length;
  }

  int get _absentCount {
    return _attendanceRecords
        .where((a) => a.status.toLowerCase() == 'absent')
        .length;
  }

  int get _lateCount {
    return _attendanceRecords
        .where((a) => a.status.toLowerCase() == 'late')
        .length;
  }

  double get _attendanceRate {
    if (_totalSessions == 0) return 0.0;
    return (_presentCount / _totalSessions) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Student Details',
      currentIndex: -1,
      isStudent: false,
      showBackButton: true,
      body: _isLoading
          ? const SkeletonListView()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_student == null) {
      return const Center(child: Text('Student not found'));
    }

    final appState = ref.watch(appProvider);
    final isDark = appState.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);

    return RefreshIndicator(
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
            // Student Header Card
            _buildStudentHeader(isDark, textColor, subtitleColor),
            SizedBox(height: Sizing.h(24)),

            // Fingerprint Section
            _buildFingerprintSection(isDark, textColor),
            SizedBox(height: Sizing.h(24)),

            // Enrollments Section
            _buildSectionLabel('Enrollments', isDark, textColor),
            SizedBox(height: Sizing.h(16)),
            if (_enrollments.isEmpty)
              _buildEmptyEnrollmentsState(isDark, subtitleColor)
            else
              _buildEnrollmentsTable(isDark, textColor, subtitleColor),

            SizedBox(height: Sizing.h(32)),

            // Attendance Summary Section
            _buildSectionLabel('Attendance Summary', isDark, textColor),
            SizedBox(height: Sizing.h(16)),
            _buildAttendanceSummary(isDark, textColor, subtitleColor),

            SizedBox(height: Sizing.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(
      bool isDark, Color textColor, Color subtitleColor) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: Sizing.w(56),
                height: Sizing.w(56),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    _student!.firstname.isNotEmpty
                        ? _student!.firstname[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: const Color(0xFF38BDF8),
                      fontSize: Sizing.sp(24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Sizing.w(16)),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _student!.fullName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: Sizing.sp(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Sizing.h(4)),
                    Text(
                      'ID: ${_student!.id}',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: Sizing.sp(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _student!.isRegular
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _student!.isRegular ? 'REGULAR' : 'IRREGULAR',
                  style: TextStyle(
                    color: _student!.isRegular
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: Sizing.sp(10),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Sizing.h(16)),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          SizedBox(height: Sizing.h(12)),
          // Section row — use widget.sectionName if passed, otherwise
          // fall back to the first enrollment's section, then omit
          if (widget.sectionName != null ||
              _enrollments.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.school_outlined,
                    size: Sizing.sp(16), color: subtitleColor),
                SizedBox(width: Sizing.w(8)),
                Expanded(
                  child: Text(
                    widget.sectionName ??
                        _enrollments.first.sectionName ??
                        _enrollments.first.sectionId,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: Sizing.sp(13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizing.h(8)),
          ],
        ],
      ),
    );
  }

  Widget _buildFingerprintSection(bool isDark, Color textColor) {
    final hasFingerprint = _fingerprints.isNotEmpty;
    final statusText = hasFingerprint
        ? '${_fingerprints.length} fingerprint${_fingerprints.length > 1 ? 's' : ''} enrolled'
        : 'No fingerprint enrolled';
    final statusColor = hasFingerprint
        ? Colors.greenAccent
        : (isDark
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.4));

    return _GlassCard(
      isDark: isDark,
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            size: Sizing.sp(24),
            color: hasFingerprint
                ? Colors.greenAccent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3)),
          ),
          SizedBox(width: Sizing.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fingerprint',
                  style: TextStyle(
                    color: textColor,
                    fontSize: Sizing.sp(15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Sizing.h(4)),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: Sizing.sp(12),
                  ),
                ),
              ],
            ),
          ),
          // Enroll Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FingerprintEnrollmentModal(
                  student: _student!,
                  onEnrollmentComplete: () {
                    _loadData();
                  },
                ),
              );
            },
            icon: Icon(Icons.add, size: Sizing.sp(16)),
            label: Text(
              hasFingerprint ? 'Add More' : 'Enroll',
              style: TextStyle(fontSize: Sizing.sp(12)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: Sizing.w(16), vertical: Sizing.h(8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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

  Widget _buildEnrollmentCard(Enrollment enrollment, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(bottom: Sizing.h(12)),
      child: _GlassCard(
        isDark: isDark,
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
                        enrollment.subjectName ?? 'Software Engineer 2',
                        style: TextStyle(
                          color: textColor,
                          fontSize: Sizing.sp(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Sizing.h(4)),
                      Text(
                        enrollment.subjectCode ?? enrollment.subjectId,
                        style: TextStyle(
                          color: const Color(0xFF38BDF8),
                          fontSize: Sizing.sp(11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    enrollment.enrollmentType.toUpperCase(),
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: Sizing.sp(9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizing.h(12)),
            Row(
              children: [
                Icon(Icons.class_outlined,
                    size: Sizing.sp(14), color: subtitleColor),
                SizedBox(width: Sizing.w(6)),
                Text(
                  enrollment.sectionName ?? enrollment.sectionId,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: Sizing.sp(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsTable(
      bool isDark, Color textColor, Color subtitleColor) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: Sizing.w(12), vertical: Sizing.h(12)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subject',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: Sizing.sp(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Section',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: Sizing.sp(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Enrollment Type',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: Sizing.sp(11),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ..._enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            final isLast = index == _enrollments.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Sizing.w(12), vertical: Sizing.h(14)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.subjectName ?? 'Unknown Subject',
                          style: TextStyle(
                            color: textColor,
                            fontSize: Sizing.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: Sizing.h(2)),
                        Text(
                          enrollment.subjectCode ?? enrollment.subjectId,
                          style: TextStyle(
                            color: const Color(0xFF38BDF8),
                            fontSize: Sizing.sp(10),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      enrollment.sectionName ?? enrollment.sectionId,
                      style: TextStyle(
                        color: textColor,
                        fontSize: Sizing.sp(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          enrollment.enrollmentType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: Sizing.sp(9),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(
      bool isDark, Color textColor, Color subtitleColor) {
    return Column(
      children: [
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'TOTAL SESSIONS',
                '$_totalSessions',
                textColor,
                subtitleColor,
                isDark,
              ),
            ),
            SizedBox(width: Sizing.w(12)),
            Expanded(
              child: _buildStatCard(
                'PRESENT',
                '$_presentCount',
                textColor,
                subtitleColor,
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: Sizing.h(12)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'ABSENT',
                '$_absentCount',
                textColor,
                subtitleColor,
                isDark,
              ),
            ),
            SizedBox(width: Sizing.w(12)),
            Expanded(
              child: _buildStatCard(
                'LATE',
                '$_lateCount',
                textColor,
                subtitleColor,
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: Sizing.h(16)),
        // Attendance Rate Bar
        Container(
          padding: EdgeInsets.all(Sizing.w(20)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'ATTENDANCE RATE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: Sizing.sp(11),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: Sizing.h(8)),
              Text(
                '${_attendanceRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Sizing.sp(32),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor,
      Color subtitleColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtitleColor,
              fontSize: Sizing.sp(10),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: Sizing.h(8)),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: Sizing.sp(24),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sizing.h(40)),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: Sizing.sp(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEnrollmentsState(bool isDark, Color subtitleColor) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(24)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: Sizing.sp(48),
            color: subtitleColor.withValues(alpha: 0.3),
          ),
          SizedBox(height: Sizing.h(16)),
          Text(
            'No enrollments found',
            style: TextStyle(
              color: subtitleColor,
              fontSize: Sizing.sp(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Sizing.h(8)),
          Text(
            'This student has not been enrolled in any subjects yet.',
            style: TextStyle(
              color: subtitleColor.withValues(alpha: 0.6),
              fontSize: Sizing.sp(12),
            ),
            textAlign: TextAlign.center,
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
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
