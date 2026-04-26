import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import 'session_details_screen.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class SessionDashboardScreen extends StatefulWidget {
  const SessionDashboardScreen({super.key});

  @override
  State<SessionDashboardScreen> createState() => _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends State<SessionDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<ClassSession> _allSessions = [];
  List<ClassSession> _filteredSessions = [];
  List<Schedule> _instructorSchedules = [];
  int _activeTabIndex =
      0; // 0: All, 1: Not Started, 2: Active, 3: Completed, 4: Cancelled

  // Premium Dark Theme Colors
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color headerTextColor = Colors.white;
  static const Color subtitleTextColor = Color(0xFF94A3B8);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dividerColor = Colors.white10;

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
      final mySessions = await _apiService.getMySessions();
      final schedules = await _apiService.getMySchedules();
      setState(() {
        _allSessions = mySessions;
        _instructorSchedules = schedules;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_activeTabIndex) {
        case 1: // Not Started
          _filteredSessions = _allSessions
              .where((s) =>
                  s.status.toLowerCase() == 'pending' ||
                  s.status.toLowerCase() == 'not_started')
              .toList();
          break;
        case 2: // Active
          _filteredSessions = _allSessions
              .where((s) =>
                  s.status.toLowerCase() == 'active' ||
                  s.status.toLowerCase() == 'started')
              .toList();
          break;
        case 3: // Completed
          _filteredSessions = _allSessions
              .where((s) =>
                  s.status.toLowerCase() == 'ended' ||
                  s.status.toLowerCase() == 'completed')
              .toList();
          break;
        case 4: // Cancelled
          _filteredSessions = _allSessions
              .where((s) =>
                  s.status.toLowerCase() == 'cancelled' ||
                  s.status.toLowerCase() == 'deleted')
              .toList();
          break;
        default:
          _filteredSessions = _allSessions;
      }
    });
  }

  int _getCount(int index) {
    switch (index) {
      case 1:
        return _allSessions
            .where((s) =>
                s.status.toLowerCase() == 'pending' ||
                s.status.toLowerCase() == 'not_started')
            .length;
      case 2:
        return _allSessions
            .where((s) =>
                s.status.toLowerCase() == 'active' ||
                s.status.toLowerCase() == 'started')
            .length;
      case 3:
        return _allSessions
            .where((s) =>
                s.status.toLowerCase() == 'ended' ||
                s.status.toLowerCase() == 'completed')
            .length;
      case 4:
        return _allSessions
            .where((s) =>
                s.status.toLowerCase() == 'cancelled' ||
                s.status.toLowerCase() == 'deleted')
            .length;
      default:
        return _allSessions.length;
    }
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return 'TBD';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  void _onCreateSession() {
    if (_instructorSchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No schedules assigned to you.')));
      return;
    }

    Schedule? selectedSchedule = _instructorSchedules.first;
    DateTime selectedDate = DateTime.now();
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
        text: DateFormat('MM/dd/yyyy').format(selectedDate));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        bool isOffSchedule = false;
        if (selectedSchedule != null && selectedSchedule!.dayOfWeek != null) {
          isOffSchedule = selectedDate.weekday != selectedSchedule!.dayOfWeek;
        }

        final isReasonValid =
            !isOffSchedule || reasonController.text.trim().length >= 5;

        return Dialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: primaryBlue,
              colorScheme: const ColorScheme.dark(primary: primaryBlue),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create New Session',
                          style: TextStyle(
                              color: headerTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: subtitleTextColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: dividerColor),
                    const SizedBox(height: 16),
                    _buildLabel('Schedule *'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Schedule>(
                          value: selectedSchedule,
                          isExpanded: true,
                          dropdownColor: surfaceColor,
                          items: _instructorSchedules
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      '${s.subjectCode} - Section ${s.sectionName} (${s.dayName})',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedSchedule = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Session Date *'),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: primaryBlue,
                                surface: surfaceColor,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                            dateController.text =
                                DateFormat('MM/dd/yyyy').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            hintStyle: const TextStyle(color: Colors.white24),
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18, color: primaryBlue),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: dividerColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: dividerColor)),
                          ),
                        ),
                      ),
                    ),
                    if (isOffSchedule) ...[
                      const SizedBox(height: 16),
                      _buildLabel('Reason for Off-Schedule Session *'),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Required: Why this day?',
                          hintStyle: const TextStyle(color: Colors.white24),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: dividerColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: dividerColor)),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildLabel('Description (Optional)'),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Notes...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: dividerColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: dividerColor)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (!isReasonValid || _isLoading)
                                ? null
                                : () async {
                                    setModalState(() => _isLoading = true);
                                    try {
                                      await _apiService.createSession({
                                        'scheduleId': selectedSchedule!.id,
                                        'sessionDate':
                                            selectedDate.toIso8601String(),
                                        'description':
                                            notesController.text.trim().isEmpty
                                                ? null
                                                : notesController.text.trim(),
                                        if (isOffSchedule) ...{
                                          'allowOffScheduleDate': true,
                                          'offScheduleReason':
                                              reasonController.text.trim(),
                                        },
                                      });
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _loadData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setModalState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(e.toString())));
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Create Session',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: subtitleTextColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sessions',
      currentIndex: 2, // Sessions tab
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: _onCreateSession,
            icon: const Icon(Icons.add_circle_outline, color: primaryBlue),
            tooltip: 'Create Session',
          ),
        ),
      ],
      body: _isLoading
          ? const SkeletonSessionList()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: primaryBlue,
                  backgroundColor: surfaceColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabContainer(),
                          const SizedBox(height: 24),
                          _buildTableContainer(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTabContainer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab('All', 0),
          _buildTab('Not Started', 1),
          _buildTab('Active', 2),
          _buildTab('Completed', 3),
          _buildTab('Cancelled', 4),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool active = _activeTabIndex == index;
    int count = _getCount(index);
    return InkWell(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
          _applyFilter();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? headerTextColor : subtitleTextColor,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? primaryBlue.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? primaryBlue : subtitleTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer() {
    if (_filteredSessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final s = _filteredSessions[index];
        return _buildSessionCard(s);
      },
    );
  }

  Widget _buildSessionCard(ClassSession s) {
    final status = s.status.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Info & Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.subjectCode,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.subjectName,
                            style: const TextStyle(
                              color: headerTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoItem(
                        Icons.calendar_today,
                        DateFormat('MMM d')
                            .format(s.sessionDate ?? DateTime.now())),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.door_front_door_outlined,
                        s.actualRoomName ?? s.scheduledRoomName),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                        Icons.access_time,
                        s.actualStartTime != null
                            ? DateFormat('h:mm a').format(s.actualStartTime!)
                            : _formatTime(s.scheduledTimeIn)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Section: ${s.sectionName}',
                  style:
                      const TextStyle(color: subtitleTextColor, fontSize: 13),
                ),
              ],
            ),
          ),

          // Bottom Section: Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: const Border(top: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                _buildActionButtons(s, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: subtitleTextColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: subtitleTextColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    String label;

    if (status == 'active' || status == 'started') {
      color = successGreen;
      label = 'ACTIVE';
    } else if (status == 'pending' || status == 'not_started') {
      color = primaryBlue;
      label = 'SCHEDULED';
    } else if (status == 'ended' || status == 'completed') {
      color = subtitleTextColor;
      label = 'ENDED';
    } else {
      color = dangerRed;
      label = 'CANCELLED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionButtons(ClassSession s, String status) {
    if (status == 'active' || status == 'started') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                  'Attendances', Icons.people_outline, () => _openDetails(s)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPrimaryButton('End Now', Icons.stop_circle_outlined,
                  dangerRed, () => _openDetails(s)),
            ),
          ],
        ),
      );
    } else if (status == 'pending' || status == 'not_started') {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                  'Start Session',
                  Icons.play_arrow_rounded,
                  successGreen,
                  () => _showStartSessionDialog(s)),
            ),
            const SizedBox(width: 12),
            _buildIconButton(
                Icons.delete_outline, dangerRed, () => _confirmDelete(s)),
          ],
        ),
      );
    } else {
      return Expanded(
        child: _buildSecondaryButton(
            'View Details', Icons.visibility_outlined, () => _openDetails(s)),
      );
    }
  }

  Widget _buildPrimaryButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _openDetails(ClassSession s) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SessionDetailsScreen(session: s)));
  }

  void _showStartSessionDialog(ClassSession s) {
    int attendanceCutoff = 15;

    final sourceSchedule = _instructorSchedules.cast<Schedule?>().firstWhere(
          (sch) => sch?.id == s.scheduleId,
          orElse: () => null,
        );
    String? selectedRoomId = sourceSchedule?.classroomId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surfaceColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Start Session',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: headerTextColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: subtitleTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: dividerColor),
                  const SizedBox(height: 16),

                  // Session Details Info Box
                  _buildDetailRow(
                      'Course:', '${s.subjectCode} - ${s.subjectName}'),
                  _buildDetailRow(
                      'Date:',
                      DateFormat('EEEE, MMMM d, yyyy')
                          .format(s.sessionDate ?? DateTime.now())),
                  _buildDetailRow('Scheduled Time:',
                      '${_formatTime(s.scheduledTimeIn)} - ${_formatTime(s.scheduledTimeOut)}'),

                  const SizedBox(height: 24),
                  const Divider(color: dividerColor),
                  const SizedBox(height: 24),

                  // Room Selection
                  const Text('Actual Room (Optional)',
                      style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: dividerColor),
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRoomId,
                        isExpanded: true,
                        dropdownColor: surfaceColor,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: subtitleTextColor),
                        items: [
                          if (selectedRoomId != null)
                            DropdownMenuItem(
                                value: selectedRoomId,
                                child: Text(
                                    'Use scheduled room (${s.scheduledRoomName})',
                                    style: const TextStyle(fontSize: 14))),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedRoomId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Select if the session is being held in a different room',
                      style: TextStyle(color: subtitleTextColor, fontSize: 11)),

                  const SizedBox(height: 24),

                  // Cutoff Input
                  const Text('Attendance Cutoff (minutes)',
                      style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      suffixText: 'minutes',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixStyle: const TextStyle(
                          color: subtitleTextColor, fontSize: 13),
                      hintText: '15',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: dividerColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: dividerColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryBlue)),
                    ),
                    onChanged: (val) =>
                        attendanceCutoff = int.tryParse(val) ?? 15,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Students can check in up to this many minutes after session start (0-120)',
                      style: TextStyle(color: subtitleTextColor, fontSize: 11)),

                  const SizedBox(height: 32),

                  // Summary Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: successGreen.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_outline,
                            color: successGreen, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ready to start?',
                                  style: TextStyle(
                                      color: successGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              SizedBox(height: 2),
                              Text(
                                  'The session will begin immediately and students can start checking in.',
                                  style: TextStyle(
                                      color: successGreen, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setDialogState(() => _isLoading = true);
                            try {
                              await _apiService.startSession(
                                s.id,
                                actualRoomId: selectedRoomId,
                                attendanceCutoffMinutes: attendanceCutoff,
                                rowVersion: s.rowVersion ?? '',
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                _loadData();
                              }
                            } catch (e) {
                              if (mounted) {
                                setDialogState(() => _isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())));
                              }
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start Session',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: headerTextColor,
                            side: const BorderSide(color: dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: subtitleTextColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: headerTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ClassSession s) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.dark(),
        child: AlertDialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Are you sure you want to cancel this session? This action cannot be undone.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: const TextStyle(color: subtitleTextColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back',
                    style: TextStyle(color: subtitleTextColor))),
            TextButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                try {
                  await _apiService.deleteSession(s.id,
                      reason: reasonController.text.trim(),
                      rowVersion: s.rowVersion ?? '');
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Cancel Session',
                  style:
                      TextStyle(color: dangerRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: dangerRed, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred',
              style: const TextStyle(color: headerTextColor)),
          TextButton(
              onPressed: _loadData,
              child: const Text('Retry', style: TextStyle(color: primaryBlue))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No sessions found for this category',
              style: TextStyle(color: subtitleTextColor, fontSize: 16)),
        ],
      ),
    );
  }
}
