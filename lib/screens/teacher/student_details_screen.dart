import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/attendance_model.dart';
import '../../models/device_model.dart';
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
  List<dynamic> _devices = []; // FingerprintDevice list
  bool _isFingerprintExpanded = false;
  bool _isDeletingFingerprint = false;
  String? _deleteError;

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
      // Fetch fingerprints first to determine if we need devices
      final fingerprints =
          await _apiService.getFingerprintsByStudent(widget.studentId);

      // Prepare futures for parallel fetching
      final futures = <Future>[
        _apiService.getStudent(widget.studentId),
        _apiService
            .getEnrollmentsByStudent(widget.studentId)
            .catchError((_) => <Enrollment>[]),
        _apiService
            .getAttendanceByStudent(widget.studentId)
            .catchError((_) => <AttendanceRecord>[]),
      ];

      // Only fetch devices if fingerprints exist
      if (fingerprints.isNotEmpty) {
        futures.add(_apiService
            .getFingerprintDevices()
            .catchError((_) => <FingerprintDevice>[]));
      }

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _student = results[0] as Student;
          _enrollments = results[1] as List<Enrollment>;
          _attendanceRecords = results[2] as List<AttendanceRecord>;
          _fingerprints = fingerprints;
          _devices = fingerprints.isNotEmpty && results.length > 3
              ? results[3] as List
              : [];
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
          if (widget.sectionName != null || _enrollments.isNotEmpty) ...[
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
      child: Column(
        children: [
          // Header row with expand/collapse
          InkWell(
            onTap: hasFingerprint
                ? () {
                    setState(() {
                      _isFingerprintExpanded = !_isFingerprintExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(Sizing.w(4)),
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
                  // Expand/collapse icon
                  if (hasFingerprint)
                    Icon(
                      _isFingerprintExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: Sizing.sp(24),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  SizedBox(width: Sizing.w(8)),
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
            ),
          ),
          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFingerprintExpanded && hasFingerprint
                ? Column(
                    children: [
                      SizedBox(height: Sizing.h(12)),
                      Divider(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      SizedBox(height: Sizing.h(12)),
                      _buildFingerprintList(isDark, textColor),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Helper method to get device for a fingerprint
  dynamic _getDeviceForFingerprint(dynamic fingerprint) {
    if (_devices.isEmpty || fingerprint.deviceId == null) return null;
    try {
      return _devices.firstWhere(
        (device) => device.id == fingerprint.deviceId,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildFingerprintList(bool isDark, Color textColor) {
    return Column(
      children: _fingerprints.map((fingerprint) {
        return Padding(
          padding: EdgeInsets.only(bottom: Sizing.h(12)),
          child: _buildFingerprintCard(fingerprint, isDark, textColor),
        );
      }).toList(),
    );
  }

  Widget _buildFingerprintCard(
      dynamic fingerprint, bool isDark, Color textColor) {
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final device = _getDeviceForFingerprint(fingerprint);
    final hasDeviceInfo = device != null;

    // Format enrollment date
    String formattedDate = 'Unknown date';
    if (fingerprint.createdAt != null) {
      final date = fingerprint.createdAt as DateTime;
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      formattedDate =
          '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
    }

    return Container(
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fingerprint icon
          Container(
            padding: EdgeInsets.all(Sizing.w(10)),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fingerprint,
              size: Sizing.sp(24),
              color: Colors.greenAccent,
            ),
          ),
          SizedBox(width: Sizing.w(12)),
          // Fingerprint details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ENROLLED',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: Sizing.sp(9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: Sizing.h(8)),
                // Device information
                if (hasDeviceInfo) ...[
                  Row(
                    children: [
                      Icon(Icons.devices_rounded,
                          size: Sizing.sp(14), color: subtitleColor),
                      SizedBox(width: Sizing.w(6)),
                      Expanded(
                        child: Text(
                          '${device.name}${device.location != null ? ' (${device.location})' : ''}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: Sizing.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: Sizing.sp(14),
                          color: Colors.orange.withValues(alpha: 0.7)),
                      SizedBox(width: Sizing.w(6)),
                      Expanded(
                        child: Text(
                          '⚠️ Device information unavailable',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.7),
                            fontSize: Sizing.sp(12),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: Sizing.h(6)),
                // Enrollment date
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: Sizing.sp(14), color: subtitleColor),
                    SizedBox(width: Sizing.w(6)),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: Sizing.sp(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: Sizing.w(8)),
          // Delete button
          InkWell(
            onTap: _isDeletingFingerprint
                ? null
                : () => _showDeleteBottomSheet(fingerprint, isDark, textColor),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(Sizing.w(10)),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: _isDeletingFingerprint
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.redAccent,
                size: Sizing.sp(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBottomSheet(
      dynamic fingerprint, bool isDark, Color textColor) {
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final device = _getDeviceForFingerprint(fingerprint);
    final hasDeviceInfo = device != null;

    // Format enrollment date
    String formattedDate = 'Unknown date';
    if (fingerprint.createdAt != null) {
      final date = fingerprint.createdAt as DateTime;
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      formattedDate =
          '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(Sizing.w(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: Sizing.w(40),
                    height: Sizing.h(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: Sizing.h(20)),
                // Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Sizing.w(10)),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: Sizing.sp(24),
                      ),
                    ),
                    SizedBox(width: Sizing.w(12)),
                    Expanded(
                      child: Text(
                        'Delete Fingerprint',
                        style: TextStyle(
                          color: textColor,
                          fontSize: Sizing.sp(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Sizing.h(20)),
                // Fingerprint details
                Container(
                  padding: EdgeInsets.all(Sizing.w(16)),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDeviceInfo) ...[
                        Row(
                          children: [
                            Icon(Icons.devices_rounded,
                                size: Sizing.sp(14), color: subtitleColor),
                            SizedBox(width: Sizing.w(8)),
                            Expanded(
                              child: Text(
                                '${device.name}${device.location != null ? ' (${device.location})' : ''}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: Sizing.sp(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Sizing.h(8)),
                      ],
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: Sizing.sp(14), color: subtitleColor),
                          SizedBox(width: Sizing.w(8)),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: Sizing.sp(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Sizing.h(16)),
                // Warning message
                Container(
                  padding: EdgeInsets.all(Sizing.w(16)),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: Sizing.sp(20),
                      ),
                      SizedBox(width: Sizing.w(12)),
                      Expanded(
                        child: Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            color: isDark
                                ? Colors.orange.shade300
                                : Colors.orange.shade900,
                            fontSize: Sizing.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Error message
                if (_deleteError != null) ...[
                  SizedBox(height: Sizing.h(16)),
                  Container(
                    padding: EdgeInsets.all(Sizing.w(16)),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: Sizing.sp(20),
                        ),
                        SizedBox(width: Sizing.w(12)),
                        Expanded(
                          child: Text(
                            _deleteError!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.red.shade300
                                  : Colors.red.shade900,
                              fontSize: Sizing.sp(13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: Sizing.h(24)),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isDeletingFingerprint
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                          padding: EdgeInsets.symmetric(vertical: Sizing.h(14)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: Sizing.sp(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Sizing.w(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDeletingFingerprint
                            ? null
                            : () => _deleteFingerprint(
                                fingerprint, context, setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          padding: EdgeInsets.symmetric(vertical: Sizing.h(14)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isDeletingFingerprint
                            ? SizedBox(
                                width: Sizing.w(20),
                                height: Sizing.w(20),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: Sizing.sp(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Sizing.h(8)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteFingerprint(dynamic fingerprint,
      BuildContext modalContext, StateSetter setModalState) async {
    setState(() {
      _isDeletingFingerprint = true;
      _deleteError = null;
    });
    setModalState(() {});

    try {
      await _apiService.deleteFingerprint(fingerprint.id);

      if (mounted) {
        setState(() {
          _isDeletingFingerprint = false;
        });
        setModalState(() {});

        // Close bottom sheet
        if (modalContext.mounted) {
          Navigator.pop(modalContext);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Fingerprint deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Refresh data
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeletingFingerprint = false;
          _deleteError =
              'Failed to delete fingerprint. Please check your connection and try again.';
        });
        setModalState(() {});
      }
    }
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
