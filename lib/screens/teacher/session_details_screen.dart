import 'package:flutter/material.dart';
import '../../models/classroom_model.dart';
import '../../services/api_service.dart';
import '../../models/session_model.dart';
import '../../models/schedule_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../widgets/skeleton_loader.dart';

class SessionDetailsScreen extends StatefulWidget {
  final ClassSession? session;
  final Schedule? schedule;
  const SessionDetailsScreen({super.key, this.session, this.schedule});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final ApiService _apiService = ApiService();
  ClassSession? _session;
  Schedule? _schedule;
  List<Classroom> _classrooms = [];
  List<dynamic> _qrCodes = [];
  String _selectedCategory = 'All';
  Classroom? _tempSelectedClassroom;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  Timer? _countdownTimer;
  String _timeRemainingText = '';

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _schedule = widget.schedule;
    _loadAllData().then((_) => _startCountdownTimer());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _session?.attendanceCutOff == null) {
        if (_timeRemainingText.isNotEmpty) {
          setState(() => _timeRemainingText = '');
        }
        return;
      }

      final now = DateTime.now();
      final difference = _session!.attendanceCutOff!.difference(now);

      if (difference.isNegative) {
        if (_timeRemainingText != 'EXPIRED') {
          setState(() => _timeRemainingText = 'EXPIRED');
        }
      } else {
        final m = difference.inMinutes;
        final s = difference.inSeconds % 60;
        final newText = '${m}m ${s}s left';
        if (_timeRemainingText != newText) {
          setState(() => _timeRemainingText = newText);
        }
      }
    });
  }

  Future<void> _loadAllData() async {
    try {
      // Fetch classrooms
      final classrooms = await _apiService.getClassrooms();

      if (_session != null && _schedule == null) {
        final results = await Future.wait([
          _apiService.getSchedule(_session!.scheduleId),
          _apiService.getQrCodesBySession(_session!.id),
        ]);
        if (mounted) {
          setState(() {
            _schedule = results[0] as Schedule;
            _qrCodes = results[1] as List<dynamic>;
            _classrooms = classrooms;
            _isInitialLoading = false;
          });
        }
      } else if (_session != null) {
        final qrCodes = await _apiService.getQrCodesBySession(_session!.id);
        if (mounted) {
          setState(() {
            _qrCodes = qrCodes;
            _classrooms = classrooms;
            _isInitialLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _classrooms = classrooms;
            _isInitialLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading session details: $e')),
        );
      }
    }
  }

  Future<void> _refreshSession() async {
    if (_session == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = await _apiService.getSessionById(_session!.id);
      setState(() => _session = updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing session: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartSession(Classroom? classroom, String? cutoff) async {
    if (_schedule == null) return;

    setState(() => _isLoading = true);
    try {
      final int? initialCutoffMinutes = cutoff != null && cutoff.isNotEmpty
          ? int.tryParse(cutoff.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;

      // 1. If session doesn't exist yet, create it now
      if (_session == null) {
        final date = _getValidSessionDate(_schedule!);
        final newSession = await _apiService.createSession({
          'scheduleId': _schedule!.id,
          'sessionDate': date.toIso8601String(),
          if (classroom != null) 'actualRoom': classroom.name,
          if (initialCutoffMinutes != null)
            'attendanceCutoffMinutes': initialCutoffMinutes,
        });

        setState(() => _session = newSession);
      } else {
        // 2. If it already exists, update the room if changed
        if (classroom != null && classroom.name != _session!.actualRoomName) {
          if (_session!.rowVersion == null) {
            throw Exception('Session rowVersion is missing. Please refresh.');
          }
          await _apiService.updateSessionRoom(_session!.id,
              actualRoomId: classroom.id, rowVersion: _session!.rowVersion!);
          // Refresh to get new rowVersion
          final intermediate = await _apiService.getSessionById(_session!.id);
          setState(() => _session = intermediate);
        }
      }

      // 3. Proceed to start the session (PATCH status)
      // Parse cutoff to minutes if possible
      int? cutoffMinutes;
      if (cutoff != null) {
        cutoffMinutes = int.tryParse(cutoff.replaceAll(RegExp(r'[^0-9]'), ''));
      }

      // Fallback to schedule's cutoff if still null and not provided
      cutoffMinutes ??= _schedule?.attendanceCutoffMinutes;

      if (_session!.rowVersion == null) {
        throw Exception('Session rowVersion is missing. Please refresh.');
      }

      await _apiService.startSession(_session!.id,
          actualRoomId: classroom?.id,
          attendanceCutoffMinutes: cutoffMinutes,
          rowVersion: _session!.rowVersion!);

      final updatedSession = await _apiService.getSessionById(_session!.id);
      setState(() {
        _session = updatedSession;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session started successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting session: $e')),
        );
      }
    }
  }

  DateTime _getValidSessionDate(Schedule schedule) {
    final now = DateTime.now();
    int? targetWeekday = schedule.dayOfWeek;

    if (targetWeekday == null && schedule.dayName != null) {
      final days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      final idx = days.indexOf(schedule.dayName!.toLowerCase());
      if (idx != -1) targetWeekday = idx + 1;
    }

    if (targetWeekday == null) return now;

    int diff = targetWeekday - now.weekday;
    if (diff < 0) diff += 7;
    return now.add(Duration(days: diff));
  }

  Future<void> _handleEndSession() async {
    if (_session == null) return;

    final TextEditingController descriptionController = TextEditingController();
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildInputBottomSheet(
        title: 'End Session',
        label: 'Session Description',
        hint: 'e.g., Covered chapters 1 to 3',
        controller: descriptionController,
        confirmLabel: 'End Session',
        confirmColor: Colors.redAccent,
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (_session!.rowVersion == null) {
        throw Exception('Session rowVersion is missing.');
      }
      await _apiService.endSession(_session!.id,
          description: descriptionController.text,
          rowVersion: _session!.rowVersion!);
      await _refreshSession();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending session: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteSession() async {
    if (_session == null) return;

    final TextEditingController reasonController = TextEditingController();
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildInputBottomSheet(
        title: 'Delete Session',
        label: 'Reason for deletion',
        hint: 'e.g., Instructor unavailable',
        controller: reasonController,
        confirmLabel: 'Delete',
        confirmColor: Colors.redAccent,
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (_session!.rowVersion == null) {
        throw Exception('Session rowVersion is missing.');
      }
      await _apiService.deleteSession(_session!.id,
          reason: reasonController.text, rowVersion: _session!.rowVersion!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting session: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInputBottomSheet({
    required String title,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
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
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          _buildModalTextField(
              controller: controller,
              hint: hint,
              icon: Icons.edit_note_rounded),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(confirmLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Classroom> get _filteredClassrooms {
    if (_selectedCategory == 'All') return _classrooms;
    if (_selectedCategory == 'Labs') {
      return _classrooms
          .where((c) =>
              c.name.toLowerCase().contains('lab') ||
              c.name.toLowerCase().contains('laboratory'))
          .toList();
    }
    if (_selectedCategory == 'Rooms') {
      return _classrooms
          .where((c) =>
              c.name.toLowerCase().contains('room') ||
              RegExp(r'\d+').hasMatch(c.name))
          .where((c) => !c.name.toLowerCase().contains('lab'))
          .toList();
    }
    return _classrooms;
  }

  void _showStartModal() {
    final String initialRoomName =
        _session?.scheduledRoomName ?? _schedule?.classroomName ?? '';
    _tempSelectedClassroom = _classrooms.firstWhere(
      (c) => c.name == initialRoomName,
    );
    final String initialCutoff =
        (_schedule?.attendanceCutoffMinutes ?? '').toString();
    final TextEditingController cutoffController =
        TextEditingController(text: initialCutoff);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _GlassModal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Session Configuration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your classroom category and location.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Labs', 'Rooms'].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedCategory = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white10),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Rooms Grid
              Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filteredClassrooms.length,
                  itemBuilder: (context, index) {
                    final room = _filteredClassrooms[index];
                    final isSelected = _tempSelectedClassroom?.id == room.id;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _tempSelectedClassroom = room);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          room.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white70,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              _buildModalLabel('Attendance Cutoff'),
              const SizedBox(height: 12),
              _buildModalTextField(
                controller: cutoffController,
                hint: 'e.g., 15 minutes',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: _buildModalButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleStartSession(null, null);
                      },
                      label: 'Skip',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModalButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleStartSession(
                            _tempSelectedClassroom, cutoffController.text);
                      },
                      label: 'Start Session',
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalButton({
    required VoidCallback onPressed,
    required String label,
    Color color = Colors.white10,
    bool isOutlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isOutlined
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? Colors.white : const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isOutlined
                ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: SkeletonSessionList(),
      );
    }

    final isActive =
        _session?.status == 'active' || _session?.status == 'started';
    final isEnded =
        _session?.status == 'ended' || _session?.status == 'completed';
    final isCancelled = _session?.status == 'cancelled';

    // Room name logic
    String roomName = 'Room';
    if (_session != null) {
      roomName = _session!.actualRoomName ?? _session!.scheduledRoomName;
    } else if (_schedule != null) {
      roomName = _schedule!.classroomName;
    }

    // Status chip
    String statusLabel;
    Color statusColor;
    if (isActive) {
      statusLabel = 'ACTIVE';
      statusColor = const Color(0xFF34D399);
    } else if (isEnded) {
      statusLabel = 'ENDED';
      statusColor = const Color(0xFF94A3B8);
    } else if (isCancelled) {
      statusLabel = 'CANCELLED';
      statusColor = const Color(0xFFEF4444);
    } else {
      statusLabel = 'NOT STARTED';
      statusColor = const Color(0xFFFBBF24);
    }

    // Header text
    String subjectLine = 'Session Details';
    String sectionLine = '';
    if (_session != null && _session!.sectionName.isNotEmpty) {
      subjectLine = _session!.subjectName;
      sectionLine = _session!.sectionName;
    } else if (_schedule != null) {
      subjectLine = _schedule!.subjectName;
      sectionLine = _schedule!.sectionName;
    }

    bool hasRoomChanged = _session?.actualRoomName != null &&
        _session?.actualRoomName != _session?.scheduledRoomName;

    // Status row values
    final Color statusRowColor = isActive
        ? const Color(0xFF34D399)
        : (isEnded ? const Color(0xFF94A3B8) : const Color(0xFFFBBF24));
    final IconData statusIcon = isActive
        ? Icons.play_circle_fill_rounded
        : (isEnded ? Icons.stop_circle_rounded : Icons.hourglass_full_rounded);
    final String statusTitle = isActive
        ? 'Session Active'
        : (isEnded ? 'Session Ended' : 'Session Not Started');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(statusLabel, statusColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject + section header
                        if (sectionLine.isNotEmpty)
                          Text(
                            sectionLine,
                            style: TextStyle(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        if (sectionLine.isNotEmpty) const SizedBox(height: 3),
                        Text(
                          subjectLine,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Compact info card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          child: Column(
                            children: [
                              _buildCompactRow(
                                icon: Icons.access_time_rounded,
                                iconColor: const Color(0xFF38BDF8),
                                label: _schedule != null
                                    ? '${_formatTime(_schedule!.timeIn)} – ${_formatTime(_schedule!.timeOut)}'
                                    : '—',
                                detail: _getDurationText(_schedule),
                              ),
                              _buildThinDivider(),
                              _buildCompactRow(
                                icon: Icons.meeting_room_rounded,
                                iconColor: const Color(0xFF38BDF8),
                                label: roomName,
                                detail: hasRoomChanged
                                    ? 'Room updated'
                                    : 'Classroom',
                                detailColor: hasRoomChanged
                                    ? const Color(0xFFFBBF24)
                                    : null,
                              ),
                              _buildThinDivider(),
                              _buildCompactRow(
                                icon: statusIcon,
                                iconColor: statusRowColor,
                                label: statusTitle,
                                detail: 'Current Status',
                              ),
                              _buildThinDivider(),
                              _buildCompactRow(
                                icon: Icons.timer_rounded,
                                iconColor: _timeRemainingText == 'EXPIRED'
                                    ? Colors.redAccent
                                    : const Color(0xFF38BDF8),
                                label: _session?.attendanceCutOff != null
                                    ? DateFormat('h:mm a')
                                        .format(_session!.attendanceCutOff!)
                                    : (_schedule?.attendanceCutoffMinutes !=
                                            null
                                        ? '${_schedule!.attendanceCutoffMinutes} min'
                                        : 'Not Set'),
                                detail: _timeRemainingText.isNotEmpty
                                    ? _timeRemainingText
                                    : 'Attendance Cutoff',
                                detailColor: _timeRemainingText.isNotEmpty &&
                                        _timeRemainingText != 'EXPIRED'
                                    ? const Color(0xFF38BDF8)
                                    : null,
                                trailing: isActive
                                    ? GestureDetector(
                                        onTap: _showCutoffSelection,
                                        child: const Icon(Icons.edit_rounded,
                                            size: 14, color: Color(0xFF38BDF8)),
                                      )
                                    : null,
                              ),
                              _buildThinDivider(),
                              _buildCompactRow(
                                icon: Icons.person_rounded,
                                iconColor: const Color(0xFF38BDF8),
                                label: 'Jovelyn Comaingking',
                                detail: 'Subject Instructor',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Codes section
                        _buildQrSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(isActive, isEnded),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF38BDF8), strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.qr_code_2_rounded,
                size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              'QR CODES',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            if (_qrCodes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_qrCodes.length}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_qrCodes.isEmpty)
          // Empty state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  style: BorderStyle.solid),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_rounded,
                    size: 28, color: Colors.white.withValues(alpha: 0.12)),
                const SizedBox(height: 8),
                Text(
                  'No QR codes for this session',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          // QR list
          Column(
            children: _qrCodes.asMap().entries.map((entry) {
              final i = entry.key;
              final qr = entry.value as Map<String, dynamic>;
              final hash = (qr['qrHash'] ?? '') as String;
              final shortHash = hash.length > 8
                  ? hash.substring(0, 8).toUpperCase()
                  : hash.toUpperCase();
              final createdAt = _parseQrDate(qr['createdAt']);
              final expiresAt = _parseQrDate(qr['expiresAt']);
              final scanned = qr['scannedCount'] ?? 0;
              final limit = qr['usageLimit'];
              final isExpired = expiresAt?.isBefore(DateTime.now()) ?? false;
              final statusColor =
                  isExpired ? const Color(0xFFEF4444) : const Color(0xFF34D399);
              final statusLabel = isExpired ? 'EXPIRED' : 'ACTIVE';
              final isLast = i == _qrCodes.length - 1;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        // QR icon with status color
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.qr_code_rounded,
                              color: statusColor, size: 15),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$shortHash…',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (createdAt != null)
                                    Text(
                                      DateFormat('MMM d, h:mm a')
                                          .format(createdAt),
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.32),
                                        fontSize: 10,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$scanned / ${limit ?? '∞'} scans',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.32),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  DateTime? _parseQrDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Widget _buildCompactRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? detail,
    Color? detailColor,
    bool isLast = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: TextStyle(
                      color:
                          detailColor ?? Colors.white.withValues(alpha: 0.32),
                      fontSize: 11,
                      fontWeight: detailColor != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildThinDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 0,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  String _getDurationText(Schedule? s) {
    if (s == null) return '90 minutes';
    try {
      final t1 = s.timeIn.split(':').map((e) => int.parse(e)).toList();
      final t2 = s.timeOut.split(':').map((e) => int.parse(e)).toList();
      final start = DateTime(2000, 1, 1, t1[0], t1[1]);
      final end = DateTime(2000, 1, 1, t2[0], t2[1]);
      final diff = end.difference(start).inMinutes;
      return '$diff minutes';
    } catch (_) {
      return '90 minutes';
    }
  }

  Widget _buildAppBar(String statusLabel, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
          const Expanded(
            child: Text(
              'Session Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.22)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCutoffSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Attendance Cutoff',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'After the cutoff, new scans will be rejected.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildChoiceChip('15 Mins', 15)),
                const SizedBox(width: 12),
                Expanded(child: _buildChoiceChip('30 Mins', 30)),
                const SizedBox(width: 12),
                Expanded(child: _buildChoiceChip('None', 0)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, int minutes) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (_session == null || _session!.rowVersion == null) return;

        setState(() => _isLoading = true);
        try {
          await _apiService.startSession(_session!.id,
              attendanceCutoffMinutes: minutes == 0 ? null : minutes,
              rowVersion: _session!.rowVersion!);
          await _refreshSession();
          _startCountdownTimer();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating cutoff: $e')));
        } finally {
          setState(() => _isLoading = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isActive, bool isEnded) {
    final bool hasSession = _session != null;
    final bool isNotStarted = !isActive && !isEnded;
    final bool isCancelled = _session?.status == 'cancelled';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          // ── NOT STARTED: [Start Session ──────] [🗑]
          if (isNotStarted && !isCancelled) ...[
            Expanded(
              child: _buildPillButton(
                onPressed: _showStartModal,
                icon: Icons.play_arrow_rounded,
                label: 'Start Session',
                bgColor: const Color(0xFF38BDF8),
                fgColor: const Color(0xFF0F172A),
              ),
            ),
            if (hasSession) ...[
              const SizedBox(width: 10),
              _buildSquareButton(
                onPressed: _handleDeleteSession,
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
            ],
          ],

          // ── ACTIVE: [⬛ End] [QR Code ──────────]
          if (isActive) ...[
            _buildSquareButton(
              onPressed: _handleEndSession,
              icon: Icons.stop_rounded,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPillButton(
                onPressed: _showQRCodeDialog,
                icon: Icons.qr_code_rounded,
                label: 'Generate QR Code',
                bgColor: const Color(0xFF38BDF8),
                fgColor: const Color(0xFF0F172A),
              ),
            ),
          ],

          // ── CANCELLED (not ended): [🗑] [✓ Done ────]
          if (isCancelled) ...[
            if (hasSession) ...[
              _buildSquareButton(
                onPressed: _handleDeleteSession,
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _buildPillButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.check_rounded,
                label: 'Done',
                bgColor: Colors.white.withValues(alpha: 0.07),
                fgColor: Colors.white,
              ),
            ),
          ],

          // ── ENDED: [✓ Done ─────────────────────]
          if (isEnded)
            Expanded(
              child: _buildPillButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.check_rounded,
                label: 'Done',
                bgColor: Colors.white.withValues(alpha: 0.07),
                fgColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              bgColor == Colors.transparent || (bgColor.a * 255.0).round() < 30
                  ? []
                  : [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
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

  void _showQRCodeDialog() async {
    if (_session == null) return;

    setState(() => _isLoading = true);

    try {
      final qrResponse = await _apiService.generateQrCode(_session!.id);
      final String qrHash = qrResponse['qrHash'] ?? '';

      setState(() => _isLoading = false);

      if (!mounted) return;

      _displayQRCodeModal(qrHash);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating QR code: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _displayQRCodeModal(String qrHash) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrHash,
                version: QrVersions.auto,
                size: 240.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${_session?.sectionName ?? _schedule?.sectionName ?? ""} - ${_session?.subjectName ?? _schedule?.subjectName ?? ""}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students can scan this to record attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
          border: InputBorder.none,
          suffixIcon:
              icon != null ? Icon(icon, color: Colors.white24, size: 20) : null,
        ),
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
        top: 16,
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
