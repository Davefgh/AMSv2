import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../services/api_service.dart';
import '../../models/classroom_model.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/app_provider.dart';
import 'session_details_screen.dart';

class SessionDashboardScreen extends ConsumerStatefulWidget {
  const SessionDashboardScreen({super.key});

  @override
  ConsumerState<SessionDashboardScreen> createState() =>
      _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends ConsumerState<SessionDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<ClassSession> _allSessions = [];
  List<ClassSession> _filteredSessions = [];
  List<Schedule> _instructorSchedules = [];
  int _activeTabIndex =
      0; // 0: All, 1: Not Started, 2: Active, 3: Completed, 4: Cancelled

  // Theme colors — resolved at build time based on isDark
  bool _isDark = true; // updated in build()

  // Accent / status colors (same in both modes)
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFF1E293B);

  // Dynamic helpers
  Color get _cardBg =>
      _isDark ? surfaceColor.withValues(alpha: 0.4) : Colors.white;
  Color get _titleColor =>
      _isDark ? Colors.white : Color(0xFF001F3F);
  Color get _subtitleColor =>
      _isDark ? Color(0xFF94A3B8) : Color(0xFF475569);
  Color get _divider =>
      _isDark ? Colors.white10 : Color(0xFF001F3F).withOpacity(0.08);
  Color get _cardBorder =>
      _isDark ? Colors.white10 : Color(0xFF001F3F).withOpacity(0.08);
  Color get _tabBg =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : Color(0xFF001F3F).withOpacity(0.06);
  BoxShadow get _cardShadow => BoxShadow(
        color: _isDark
            ? Colors.black.withValues(alpha: 0.1)
            : Color(0xFF001F3F).withOpacity(0.06),
        blurRadius: 10,
        offset: Offset(0, 4),
      );

  // Aliases kept for backward compat (non-— cannot be used in context)
  Color get headerTextColor => _titleColor;
  Color get subtitleTextColor => _subtitleColor;
  Color get dividerColor => _divider;

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
          SnackBar(content: Text('No schedules assigned to you.')));
      return;
    }

    Schedule? selectedSchedule = _instructorSchedules.first;
    DateTime selectedDate = DateTime.now();
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
        text: DateFormat('MM/dd/yyyy').format(selectedDate));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        bool isOffSchedule = false;
        if (selectedSchedule != null && selectedSchedule!.dayOfWeek != null) {
          isOffSchedule = selectedDate.weekday != selectedSchedule!.dayOfWeek;
        }

        final isReasonValid =
            !isOffSchedule || reasonController.text.trim().length >= 5;

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: dividerColor),
          ),
          child: Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: primaryBlue,
              colorScheme: ColorScheme.dark(primary: primaryBlue),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Session',
                        style: TextStyle(
                            color: headerTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subtitleTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: dividerColor),
                  SizedBox(height: 16),
                  _buildLabel('Schedule *'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedSchedule = val),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildLabel('Session Date *'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
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
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          hintStyle: TextStyle(color: Colors.white24),
                          suffixIcon: Icon(Icons.calendar_today,
                              size: 18, color: primaryBlue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: dividerColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: dividerColor)),
                        ),
                      ),
                    ),
                  ),
                  if (isOffSchedule) ...[
                    SizedBox(height: 16),
                    _buildLabel('Reason for Off-Schedule Session *'),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Required: Why this day?',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: dividerColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: dividerColor)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ],
                  SizedBox(height: 16),
                  _buildLabel('Description (Optional)'),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Notes...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: dividerColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: dividerColor)),
                    ),
                  ),
                  SizedBox(height: 24),
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
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Create Session',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: TextStyle(color: subtitleTextColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDark = ref.watch(appProvider).isDarkMode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? SkeletonSessionList()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: primaryBlue,
                  backgroundColor: surfaceColor,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabContainer(),
                          SizedBox(height: 24),
                          _buildTableContainer(),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateSession,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.black,
        elevation: 4,
        child: Icon(Icons.add, size: 28),
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
        margin: EdgeInsets.only(right: 20),
        padding: EdgeInsets.only(bottom: 8),
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
                color: active ? _titleColor : _subtitleColor,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active ? primaryBlue.withValues(alpha: 0.2) : _tabBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? primaryBlue : _subtitleColor,
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
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final s = _filteredSessions[index];
        return _buildSessionCard(s);
      },
    );
  }

  Widget _buildSessionCard(ClassSession s) {
    final status = s.status.toLowerCase();
    final actionButtons = _buildActionButtons(s, status);
    final hasActions = actionButtons is! SizedBox;

    return InkWell(
      onTap: () => _openDetails(s),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
          boxShadow: [_cardShadow],
        ),
        child: Column(
          children: [
            // Top Section: Info & Status
            Padding(
              padding: EdgeInsets.all(20),
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
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              s.subjectName,
                              style: TextStyle(
                                color: _titleColor,
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
                  SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoItem(
                            Icons.calendar_today,
                            DateFormat('MMM d')
                                .format(s.sessionDate ?? DateTime.now())),
                        SizedBox(width: 16),
                        _buildInfoItem(Icons.door_front_door_outlined,
                            s.actualRoomName ?? s.scheduledRoomName),
                        SizedBox(width: 16),
                        _buildInfoItem(
                            Icons.access_time,
                            s.actualStartTime != null
                                ? DateFormat('h:mm a')
                                    .format(s.actualStartTime!)
                                : _formatTime(s.scheduledTimeIn)),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Section: ${s.sectionName}',
                    style: TextStyle(color: _subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Bottom Section: Actions (only show if there are actions)
            if (hasActions)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Color(0xFF001F3F).withOpacity(0.02),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(top: BorderSide(color: _divider)),
                ),
                child: Row(
                  children: [
                    actionButtons,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _subtitleColor),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: _subtitleColor, fontSize: 13),
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCompactButton(
                icon: Icons.qr_code_rounded,
                label: 'QR',
                color: primaryBlue,
                onTap: () => _handleQRAction(s),
              ),
              SizedBox(width: 8),
              _buildCompactButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                color: Color(0xFF818CF8),
                onTap: () => _openDetails(s),
              ),
              SizedBox(width: 8),
              _buildCompactButton(
                icon: Icons.stop_circle_outlined,
                label: 'End',
                color: dangerRed,
                onTap: () => _confirmEndSession(s),
              ),
            ],
          ),
          _buildCompactButton(
            icon: Icons.location_on_outlined,
            label: '',
            color: primaryBlue,
            onTap: () => _showLocationDialog(s),
            iconOnly: true,
          ),
        ],
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
            SizedBox(width: 12),
            _buildIconButton(
                Icons.delete_outline, dangerRed, () => _confirmDelete(s)),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            if (!iconOnly) ...[
              SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _openDetails(ClassSession s) async {
    final status = s.status.toLowerCase();
    final isActive = status == 'active' || status == 'started';

    // For ended/cancelled sessions, navigate to the dedicated details screen
    if (!isActive) {
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailsScreen(session: s),
          ),
        );
        if (result == true) {
          _loadData();
        }
      }
      return;
    }

    // For active sessions, show the QR list / generate QR flow
    setState(() => _isLoading = true);
    try {
      final qrList = await _apiService.getQrCodesBySession(s.id);
      setState(() => _isLoading = false);

      if (mounted) {
        if (qrList.isNotEmpty) {
          _showQRListModal(s, qrList);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No active QR code found. Generate one first.'),
              backgroundColor: primaryBlue,
            ),
          );
          _showGenerateQRModal(s);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading session details: $e')),
        );
      }
    }
  }

  void _showQRListModal(ClassSession s, List<dynamic> qrCodes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: surfaceColor,
          insetPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QR Codes for Session',
                            style: TextStyle(
                                color: headerTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('${s.subjectName} - ${s.sectionName}',
                            style: TextStyle(
                                color: subtitleTextColor, fontSize: 13)),
                      ],
                    ),
                    IconButton(
                        icon: Icon(Icons.close, color: subtitleTextColor),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                SizedBox(height: 24),
                Text('${qrCodes.length} QR codes',
                    style: TextStyle(
                        color: subtitleTextColor, fontSize: 14)),
                SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: qrCodes.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final qr = qrCodes[index];
                      final hash = qr['qrHash'] ?? 'No Hash';
                      final createdAt = _parseDateTime(qr['createdAt']);
                      final expiresAt = _parseDateTime(qr['expiresAt']);
                      final scanned = qr['scannedCount'] ?? 0;
                      final limit = qr['usageLimit'];

                      final isExpired = expiresAt.isBefore(DateTime.now());
                      final diff = expiresAt.difference(DateTime.now());
                      final expirationText = isExpired
                          ? 'Expired'
                          : 'Expires in ${diff.inMinutes}m';
                      final statusColor = isExpired ? dangerRed : successGreen;
                      final statusLabel = isExpired ? 'EXPIRED' : 'ACTIVE';

                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                      'QR #${hash.length > 8 ? hash.substring(0, 8) : hash}...',
                                      style: TextStyle(
                                          color: headerTextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildQRListInfoRow(
                                Icons.history,
                                'Created:',
                                DateFormat('MMM d, y, hh:mm a')
                                    .format(createdAt)),
                            SizedBox(height: 6),
                            _buildQRListInfoRow(Icons.timer_outlined,
                                'Expiration:', expirationText),
                            SizedBox(height: 6),
                            _buildQRListInfoRow(Icons.people_outline, 'Usage:',
                                '$scanned / ${limit ?? 'Unlimited'}'),
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showSessionQRDetailsModal(s, qr);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isExpired
                                      ? Colors.white12
                                      : Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                    isExpired ? 'View Details' : 'View QR Code',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close',
                        style: TextStyle(
                            color: subtitleTextColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScanHistoryModal(String qrId) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: _apiService.getQrScanHistory(qrId),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: primaryBlue)),
              );
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              content = Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: Colors.white.withValues(alpha: 0.1)),
                    SizedBox(height: 16),
                    Text('No scans recorded yet',
                        style: TextStyle(color: subtitleTextColor)),
                  ],
                ),
              );
            } else {
              final scans = snapshot.data!;
              content = ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(20),
                  itemCount: scans.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: dividerColor, height: 24),
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    final student = scan['student'] ?? {};
                    final name = student['fullName'] ?? 'Unknown Student';
                    final studentId = student['studentNumber'] ?? 'N/A';
                    final scanTime = DateTime.parse(
                        scan['scannedAt'] ?? DateTime.now().toIso8601String());

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryBlue.withValues(alpha: 0.1),
                          child: Text(name.isNotEmpty ? name[0] : '?',
                              style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      color: headerTextColor,
                                      fontWeight: FontWeight.bold)),
                              Text('ID: $studentId',
                                  style: TextStyle(
                                      color: subtitleTextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(DateFormat('hh:mm a').format(scanTime),
                            style: TextStyle(
                                color: subtitleTextColor, fontSize: 12)),
                      ],
                    );
                  },
                ),
              );
            }

            return Dialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Scan History',
                            style: TextStyle(
                                color: headerTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: Icon(Icons.close,
                                color: subtitleTextColor),
                            onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  content,
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close',
                            style: TextStyle(color: subtitleTextColor))),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQRListInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: subtitleTextColor, size: 14),
        SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: subtitleTextColor, fontSize: 12)),
        SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: headerTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
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
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Session',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: headerTextColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subtitleTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: dividerColor),
                  SizedBox(height: 16),

                  // Session Details Info Box
                  _buildDetailRow(
                      'Course:', '${s.subjectCode} - ${s.subjectName}'),
                  _buildDetailRow(
                      'Date:',
                      DateFormat('EEEE, MMMM d, yyyy')
                          .format(s.sessionDate ?? DateTime.now())),
                  _buildDetailRow('Scheduled Time:',
                      '${_formatTime(s.scheduledTimeIn)} - ${_formatTime(s.scheduledTimeOut)}'),

                  SizedBox(height: 24),
                  Divider(color: dividerColor),
                  SizedBox(height: 24),

                  // Room Selection
                  Text('Actual Room (Optional)',
                      style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: dividerColor),
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRoomId,
                        isExpanded: true,
                        dropdownColor: surfaceColor,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: subtitleTextColor),
                        items: [
                          if (selectedRoomId != null)
                            DropdownMenuItem(
                                value: selectedRoomId,
                                child: Text(
                                    'Use scheduled room (${s.scheduledRoomName})',
                                    style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedRoomId = val),
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                      'Select if the session is being held in a different room',
                      style: TextStyle(color: subtitleTextColor, fontSize: 11)),

                  SizedBox(height: 24),

                  // Cutoff Input
                  Text('Attendance Cutoff (minutes)',
                      style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      suffixText: 'minutes',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixStyle: TextStyle(
                          color: subtitleTextColor, fontSize: 13),
                      hintText: '15',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dividerColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dividerColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryBlue)),
                    ),
                    onChanged: (val) =>
                        attendanceCutoff = int.tryParse(val) ?? 15,
                  ),
                  SizedBox(height: 6),
                  Text(
                      'Students can check in up to this many minutes after session start (0-120)',
                      style: TextStyle(color: subtitleTextColor, fontSize: 11)),

                  SizedBox(height: 32),

                  // Summary Notice
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: successGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
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

                  SizedBox(height: 32),

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
                                _showGenerateQRModal(s);
                              }
                            } catch (e) {
                              if (mounted) {
                                setDialogState(() => _isLoading = false);
                                String errorMsg = e.toString();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMsg)));

                                // Fix: If already started, close modal and refresh UI to stay in sync
                                if (errorMsg.contains('already been started')) {
                                  Navigator.pop(context);
                                  _loadData();
                                }
                              }
                            }
                          },
                          icon: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.play_arrow, size: 18),
                          label: Text(
                              _isLoading ? 'Starting...' : 'Start Session',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: headerTextColor,
                            side: BorderSide(color: dividerColor),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel',
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
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: subtitleTextColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: dividerColor),
        ),
        child: Theme(
          data: ThemeData.dark(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Cancel Session',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to cancel this session? This action cannot be undone.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 24),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: subtitleTextColor),
                  hintText: 'Please provide a reason...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryBlue),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          Text('Go Back', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
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
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Cancel Session',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEndSession(ClassSession s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('End Session', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to end this session now?',
            style: TextStyle(color: subtitleTextColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.endSession(s.id,
                    rowVersion: s.rowVersion ?? '');
                _loadData();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            child: Text('End Session',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(ClassSession s) async {
    String? selectedRoomId;
    List<Classroom> rooms = [];
    bool modalLoading = true;
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (rooms.isEmpty && modalLoading) {
            _apiService.getClassrooms().then((value) {
              if (mounted) {
                setModalState(() {
                  rooms = value;
                  modalLoading = false;
                });
              }
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header strip
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.swap_horiz_rounded,
                              color: primaryBlue, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Change Session Room',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3)),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 18),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meta info card
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Course',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.45),
                                          fontSize: 12)),
                                  Flexible(
                                    child: Text(
                                      '${s.subjectCode} · ${s.subjectName}',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 10),
                                child: Divider(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    height: 1),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Date',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.45),
                                          fontSize: 12)),
                                  Text(
                                      DateFormat('EEE, MMM d, y')
                                          .format(DateTime.now()),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 14),

                        // Current Room amber badge
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Color(0xFFF59E0B).withValues(alpha: 0.15),
                              Color(0xFFF59E0B).withValues(alpha: 0.06),
                            ]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color(0xFFF59E0B)
                                    .withValues(alpha: 0.28)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.meeting_room_rounded,
                                  color: Color(0xFFFBBF24), size: 15),
                              SizedBox(width: 8),
                              Text('Current Room',
                                  style: TextStyle(
                                      color: Color(0xFFFBBF24), fontSize: 12)),
                              Spacer(),
                              Text(s.actualRoomName ?? s.scheduledRoomName,
                                  style: TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ),

                        SizedBox(height: 18),

                        // New Room label
                        Row(
                          children: [
                            Text('New Room',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: dangerRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Required',
                                  style: TextStyle(
                                      color: dangerRed,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Dropdown
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                                color: selectedRoomId != null
                                    ? primaryBlue.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: modalLoading
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryBlue)),
                                      SizedBox(width: 10),
                                      Text('Loading rooms...',
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRoomId,
                                    isExpanded: true,
                                    hint: Text('Select a classroom',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 14)),
                                    dropdownColor: Color(0xFF1E293B),
                                    icon: Icon(Icons.keyboard_arrow_down,
                                        color: Colors.white38),
                                    items: rooms.map((r) {
                                      return DropdownMenuItem<String>(
                                        value: r.id,
                                        child: Text(r.name,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(
                                        () => selectedRoomId = val),
                                  ),
                                ),
                        ),
                        SizedBox(height: 6),
                        Text('Select the new room for this active session',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11)),

                        SizedBox(height: 16),

                        // Info callout
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              primaryBlue.withValues(alpha: 0.12),
                              primaryBlue.withValues(alpha: 0.05),
                            ]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Color(0xFF60A5FA), size: 15),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    'The room will update immediately. Students will see the new location in their app.',
                                    style: TextStyle(
                                        color: Color(0xFF93C5FD),
                                        fontSize: 12,
                                        height: 1.5)),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 22),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: (selectedRoomId == null ||
                                        isUpdating)
                                    ? null
                                    : () async {
                                        setModalState(() => isUpdating = true);
                                        try {
                                          await _apiService.updateSessionRoom(
                                              s.id,
                                              actualRoomId: selectedRoomId!,
                                              rowVersion: s.rowVersion ?? '');
                                          if (mounted) {
                                            Navigator.pop(context);
                                            _loadData();
                                          }
                                        } catch (e) {
                                          setModalState(
                                              () => isUpdating = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  disabledForegroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  elevation: 0,
                                  padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isUpdating
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.location_on_rounded,
                                              size: 16),
                                          SizedBox(width: 8),
                                          Text('Update Room',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.12)),
                                  padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      // If the string doesn't specify a timezone, assume it's UTC from the server
      String formattedStr = dateStr;
      if (!formattedStr.contains('Z') && !formattedStr.contains('+')) {
        formattedStr += 'Z';
      }
      return DateTime.parse(formattedStr).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: dangerRed, size: 48),
          SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred',
              style: TextStyle(color: headerTextColor)),
          TextButton(
              onPressed: _loadData,
              child: Text('Retry', style: TextStyle(color: primaryBlue))),
        ],
      ),
    );
  }

  // --- QR Code Management ---

  void _handleQRAction(ClassSession s) {
    _showGenerateQRModal(s);
  }

  void _showGenerateQRModal(ClassSession s) {
    int expirationMinutes = 30;
    int? maxUsage;
    String uniqueHash = Uuid().v4().substring(0, 8);
    final TextEditingController usageController = TextEditingController();
    final TextEditingController hashController =
        TextEditingController(text: uniqueHash);
    bool modalLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: surfaceColor,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Blue Header
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        color: Color(0xFF1E40AF),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text('Generate QR Code',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Generate a QR code for students to scan. They can use their mobile app to record attendance.',
                                style: TextStyle(
                                    color: subtitleTextColor, fontSize: 14)),
                            SizedBox(height: 24),

                            // Expiration Time
                            _buildModalLabel('Expiration Time',
                                isRequired: true),
                            SizedBox(height: 8),
                            Container(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                border: Border.all(color: dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: expirationMinutes,
                                  isExpanded: true,
                                  dropdownColor: surfaceColor,
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: subtitleTextColor),
                                  items: [15, 30, 60, 120]
                                      .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                              '$m Minutes ${m == 30 ? "(Default)" : ""}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14))))
                                      .toList(),
                                  onChanged: (val) => setModalState(
                                      () => expirationMinutes = val ?? 30),
                                ),
                              ),
                            ),
                            Text('How long the QR code remains valid.',
                                style: TextStyle(
                                    color: subtitleTextColor, fontSize: 11)),

                            SizedBox(height: 20),

                            // Max Usage
                            _buildModalLabel('Max Usage Limit',
                                isOptional: true),
                            SizedBox(height: 8),
                            TextField(
                              controller: usageController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration:
                                  _modalInputDecoration('Unlimited', Icons.tag),
                              onChanged: (val) => maxUsage = int.tryParse(val),
                            ),
                            Text(
                                'Limit the total number of scans allowed.',
                                style: TextStyle(
                                    color: subtitleTextColor, fontSize: 11)),

                            SizedBox(height: 20),

                            // Unique Hash
                            _buildModalLabel('Unique Identifier Hash',
                                isRequired: true),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: hashController,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'monospace'),
                                    decoration: _modalInputDecoration(
                                        '', Icons.fingerprint),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1E40AF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.refresh,
                                        color: Colors.white),
                                    onPressed: () => setModalState(() {
                                      uniqueHash =
                                          Uuid().v4().substring(0, 8);
                                      hashController.text = uniqueHash;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                                'Client-side signature identifier for this QR code.',
                                style: TextStyle(
                                    color: subtitleTextColor, fontSize: 11)),

                            SizedBox(height: 32),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: modalLoading
                                        ? null
                                        : () async {
                                            setModalState(
                                                () => modalLoading = true);
                                            try {
                                              final result = await _apiService
                                                  .generateQrCode(
                                                s.id,
                                                expirationMinutes:
                                                    expirationMinutes,
                                                maxUsage: maxUsage,
                                                qrHash: hashController.text,
                                              );
                                              if (mounted) {
                                                Navigator.pop(context);
                                                _showSessionQRDetailsModal(
                                                    s, result);
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                setModalState(
                                                    () => modalLoading = false);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            e.toString())));
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1E40AF),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: modalLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : Text('Generate QR Code',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: modalLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: headerTextColor,
                                      side:
                                          BorderSide(color: dividerColor),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (modalLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: Center(
                          child: CircularProgressIndicator(color: primaryBlue)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionQRDetailsModal(ClassSession s, Map<String, dynamic> qrData) {
    String qrHash = qrData['qrHash'] ?? '';
    DateTime expiresAt = _parseDateTime(qrData['expiresAt']);
    int scannedCount = qrData['scannedCount'] ?? 0;
    int? limit = qrData['usageLimit'];

    showDialog(
      context: context,
      builder: (context) {
        Timer? modalTimer;
        return StatefulBuilder(
          builder: (context, setModalState) {
            modalTimer ??= Timer.periodic(Duration(seconds: 1), (t) {
              if (mounted) setModalState(() {});
            });

            final now = DateTime.now();
            final diff = expiresAt.difference(now);
            final mins = diff.inMinutes.toString().padLeft(2, '0');
            final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
            final timeText = diff.isNegative ? "00:00" : "$mins:$secs";

            return Dialog(
              backgroundColor: surfaceColor,
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Session QR Code',
                            style: TextStyle(
                                color: headerTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: Icon(Icons.close,
                                color: subtitleTextColor),
                            onPressed: () {
                              modalTimer?.cancel();
                              Navigator.pop(context);
                            }),
                      ],
                    ),
                    SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: qrHash,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A)),
                        dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Countdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Color(0xFF38BDF8), size: 28),
                        SizedBox(width: 8),
                        Text(timeText,
                            style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 32,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    SizedBox(height: 24),

                    InkWell(
                      onTap: () => _showScanHistoryModal(qrData['id'] ?? ''),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: dividerColor),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_outlined,
                                  color: subtitleTextColor, size: 20),
                              SizedBox(width: 12),
                              Text('$scannedCount',
                                  style: TextStyle(
                                      color: headerTextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 6),
                              Text('SCANNED',
                                  style: TextStyle(
                                      color: subtitleTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                              SizedBox(width: 16),
                              VerticalDivider(
                                  color: Colors.white24,
                                  thickness: 1,
                                  width: 1),
                              SizedBox(width: 16),
                              Text(limit?.toString() ?? 'LIMIT',
                                  style: TextStyle(
                                      color: subtitleTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                    Text(
                        'Students should scan this code using the mobile app.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: subtitleTextColor, fontSize: 13)),

                    SizedBox(height: 32),

                    Row(
                      children: [
                        _buildQRActionButton(Icons.history, 'History',
                            () => _showScanHistoryModal(qrData['id'] ?? '')),
                        SizedBox(width: 8),
                        _buildQRActionButton(Icons.download, 'Download', () {}),
                        SizedBox(width: 8),
                        _buildQRActionButton(Icons.block, 'Revoke', () async {
                          try {
                            await _apiService.revokeQrCode(s.id);
                            modalTimer?.cancel();
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        }, isDanger: true),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQRActionButton(IconData icon, String label, VoidCallback onTap,
      {bool isDanger = false}) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
              color:
                  isDanger ? dangerRed.withValues(alpha: 0.2) : dividerColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: isDanger ? dangerRed : headerTextColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildModalLabel(String text,
      {bool isRequired = false, bool isOptional = false}) {
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                color: headerTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        if (isRequired) Text(' *', style: TextStyle(color: dangerRed)),
        if (isOptional)
          Text(' (Optional)',
              style: TextStyle(
                  color: subtitleTextColor.withValues(alpha: 0.7),
                  fontSize: 12)),
      ],
    );
  }

  InputDecoration _modalInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: subtitleTextColor, size: 20),
      hintStyle: TextStyle(color: subtitleTextColor, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Icon(Icons.inbox_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          SizedBox(height: 16),
          Text('No sessions found for this category',
              style: TextStyle(color: subtitleTextColor, fontSize: 16)),
        ],
      ),
    );
  }
}


