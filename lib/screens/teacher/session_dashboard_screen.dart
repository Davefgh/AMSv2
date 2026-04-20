import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import 'session_details_screen.dart';
import 'dart:ui';
import '../../widgets/main_scaffold.dart';

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
  int _activeTabIndex = 0; // 0: All, 1: Not Started, 2: Active, 3: Completed, 4: Cancelled

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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_activeTabIndex) {
        case 1: // Not Started
          _filteredSessions = _allSessions.where((s) => s.status.toLowerCase() == 'pending' || s.status.toLowerCase() == 'not_started').toList();
          break;
        case 2: // Active
          _filteredSessions = _allSessions.where((s) => s.status.toLowerCase() == 'active' || s.status.toLowerCase() == 'started').toList();
          break;
        case 3: // Completed
          _filteredSessions = _allSessions.where((s) => s.status.toLowerCase() == 'ended' || s.status.toLowerCase() == 'completed').toList();
          break;
        case 4: // Cancelled
          _filteredSessions = _allSessions.where((s) => s.status.toLowerCase() == 'cancelled' || s.status.toLowerCase() == 'deleted').toList();
          break;
        default:
          _filteredSessions = _allSessions;
      }
    });
  }

  int _getCount(int index) {
    switch (index) {
      case 1: return _allSessions.where((s) => s.status.toLowerCase() == 'pending' || s.status.toLowerCase() == 'not_started').length;
      case 2: return _allSessions.where((s) => s.status.toLowerCase() == 'active' || s.status.toLowerCase() == 'started').length;
      case 3: return _allSessions.where((s) => s.status.toLowerCase() == 'ended' || s.status.toLowerCase() == 'completed').length;
      case 4: return _allSessions.where((s) => s.status.toLowerCase() == 'cancelled' || s.status.toLowerCase() == 'deleted').length;
      default: return _allSessions.length;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No schedules assigned to you.')));
      return;
    }

    Schedule? selectedSchedule = _instructorSchedules.first;
    DateTime selectedDate = DateTime.now();
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController dateController = TextEditingController(text: DateFormat('MM/dd/yyyy').format(selectedDate));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Off-schedule detection
          final isOffSchedule = selectedSchedule != null && selectedDate.weekday != selectedSchedule!.dayOfWeek;
          final isReasonValid = !isOffSchedule || reasonController.text.trim().length >= 5;

          return _GlassModal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Session',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Schedule Input
                const Text('Schedule *', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Schedule>(
                      value: selectedSchedule,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                      items: _instructorSchedules.map((Schedule s) {
                        return DropdownMenuItem<Schedule>(
                          value: s,
                          child: Text(
                            'Section ${s.sectionName} - ${s.classroomName} - ${s.dayName} ${_formatTime(s.timeIn)} - ${_formatTime(s.timeOut)}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedSchedule = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Input
                const Text('Session Date *', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(minutes: 1)), // Allow today
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF38BDF8),
                              onPrimary: Colors.black,
                              surface: Color(0xFF1E293B),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        selectedDate = picked;
                        dateController.text = DateFormat('MM/dd/yyyy').format(picked);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        hintText: 'mm/dd/yyyy',
                        hintStyle: const TextStyle(color: Colors.white24),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Off-Schedule Reason Input
                if (isOffSchedule) ...[
                  const Text('Reason for Off-Schedule Session *', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    onChanged: (val) => setModalState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      hintText: 'Explain why this class is being held on a different day',
                      hintStyle: const TextStyle(color: Colors.white24),
                      errorText: (reasonController.text.isEmpty) ? null : (reasonController.text.length < 5 ? 'Minimum 5 characters required' : null),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: Colors.white38),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'This session date does not match the schedule day. A reason is required.',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Notes Input
                const Text('Description (Optional)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    hintText: 'Enter session description or notes...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    counterStyle: const TextStyle(color: Colors.white24, fontSize: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: !isReasonValid ? null : () async {
                          if (selectedSchedule == null) return;
                          try {
                            Navigator.pop(context); // Close modal
                            setState(() => _isLoading = true);
                            await _apiService.createSession({
                              'scheduleId': selectedSchedule!.id,
                              'sessionDate': selectedDate.toIso8601String(),
                              'description': notesController.text,
                              if (isOffSchedule) 'offScheduleReason': reasonController.text,
                            });
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created successfully!'), backgroundColor: Color(0xFF34D399)));
                          } catch (e) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Create Session', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sessions',
      currentIndex: 2, // Sessions tab
      isAdmin: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF38BDF8),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabs(),
                  Expanded(
                    child: _filteredSessions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) => _buildSessionCard(_filteredSessions[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Management',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  'Manage your class sessions...',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _onCreateSession,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
          _applyFilter();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: active ? const Color(0xFF38BDF8) : Colors.white38, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF38BDF8) : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(color: active ? Colors.black : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(ClassSession s) {
    final status = s.status.toLowerCase();
    final isActive = status == 'active' || status == 'started';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateBadge(s.sessionDate),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.subjectCode} - ${s.subjectName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(s.actualRoomName ?? s.scheduledRoomName, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusPill(status),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  Text(
                    s.actualStartTime != null 
                        ? '${DateFormat('h:mm a').format(s.actualStartTime!)} - ${s.actualEndTime != null ? DateFormat('h:mm a').format(s.actualEndTime!) : 'Progress'}'
                        : '${_formatTime(s.scheduledTimeIn)} - ${_formatTime(s.scheduledTimeOut)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
              isActive 
                ? _buildActiveActions(s)
                : TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s))),
                    child: const Text('View Only', style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w900)),
          Text(DateFormat('dd').format(date), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    String label = status.toUpperCase();
    
    if (status == 'active' || status == 'started') {
      color = const Color(0xFF34D399);
      label = 'ACTIVE';
    } else if (status == 'cancelled' || status == 'deleted') {
      color = Colors.redAccent;
      label = 'CANCELLED';
    } else if (status == 'ended' || status == 'completed') {
      color = Colors.white24;
      label = 'ENDED';
    } else {
      color = const Color(0xFF38BDF8);
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildActiveActions(ClassSession s) {
    return Row(
      children: [
        _buildSmallAction(Icons.qr_code_rounded, 'QR', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s)))),
        const SizedBox(width: 8),
        _buildSmallAction(Icons.visibility_outlined, 'View', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s)))),
        const SizedBox(width: 8),
        _buildSmallAction(Icons.stop_circle_outlined, 'End', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionDetailsScreen(session: s))), color: Colors.redAccent.withValues(alpha: 0.2), iconColor: Colors.redAccent),
      ],
    );
  }

  Widget _buildSmallAction(IconData icon, String label, VoidCallback onTap, {Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor ?? Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: iconColor ?? Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No sessions found in this category', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _GlassModal extends StatelessWidget {
  final Widget child;
  const _GlassModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: child,
    );
  }
}
