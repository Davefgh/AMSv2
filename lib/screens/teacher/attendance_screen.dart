import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/session_model.dart';
import 'dart:ui';
import '../../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';
import 'record_attendance_screen.dart';
import '../../widgets/skeleton_loader.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<ClassSession> _sessions = [];
  List<ClassSession> _filteredSessions = [];

  Map<String, int> _stats = {
    'active': 0,
    'pending': 0,
    'ended': 0,
  };

  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sessions = await _apiService.getMySessions();

      // Calculate stats
      int active = 0;
      int pending = 0;
      int ended = 0;

      for (var s in sessions) {
        final status = s.status.toLowerCase();
        if (status == 'active' || status == 'started') {
          active++;
        } else if (status == 'ended' || status == 'completed') {
          ended++;
        } else {
          pending++;
        }
      }

      setState(() {
        _sessions = sessions;
        _stats = {
          'active': active,
          'pending': pending,
          'ended': ended,
        };
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSessions = _sessions.where((s) {
        // Search
        final matchesSearch = s.subjectName.toLowerCase().contains(query) ||
            s.subjectCode.toLowerCase().contains(query) ||
            s.sectionName.toLowerCase().contains(query);

        // Status filter
        bool matchesStatus = true;
        if (_statusFilter == 'Active') {
          matchesStatus = s.status.toLowerCase() == 'active' ||
              s.status.toLowerCase() == 'started';
        } else if (_statusFilter == 'Ended') {
          matchesStatus = s.status.toLowerCase() == 'ended' ||
              s.status.toLowerCase() == 'completed';
        } else if (_statusFilter == 'Pending') {
          matchesStatus = s.status.toLowerCase() != 'active' &&
              s.status.toLowerCase() != 'started' &&
              s.status.toLowerCase() != 'ended' &&
              s.status.toLowerCase() != 'completed';
        }

        // Date filter (Simplified for now - can be expanded)
        bool matchesDate = true;
        if (s.sessionDate != null) {
          matchesDate = s.sessionDate!.day == _selectedDate.day &&
              s.sessionDate!.month == _selectedDate.month &&
              s.sessionDate!.year == _selectedDate.year;
        }

        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Attendance Management',
      currentIndex: 1,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const SkeletonSessionList()
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        color: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1E293B),
                        onRefresh: _loadData,
                        child: _filteredSessions.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                itemCount: _filteredSessions.length,
                                itemBuilder: (context, index) =>
                                    _buildSessionCard(_filteredSessions[index]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a session to record or view attendance',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              _buildStatChip(
                  '${_stats['active']} Active', const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _buildStatChip(
                  '${_stats['pending']} Pending', const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _buildStatChip('${_stats['ended']} Ended', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Row
          Row(
            children: [
              Expanded(
                child: _buildSearchField(),
              ),
              const SizedBox(width: 12),
              _buildDatePicker(),
              const SizedBox(width: 12),
              _buildStatusDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(Icons.search,
              color: Colors.white.withOpacity(0.3), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF38BDF8),
                onPrimary: Color(0xFF0F172A),
                surface: Color(0xFF1E293B),
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          _applyFilters();
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                color: Colors.white.withOpacity(0.3), size: 18),
            const SizedBox(width: 8),
            Text(
              DateFormat('MM/dd/yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          dropdownColor: const Color(0xFF1E293B),
          icon: Icon(Icons.filter_list,
              color: Colors.white.withOpacity(0.3), size: 18),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          items: ['All', 'Active', 'Pending', 'Ended'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _statusFilter = newValue!);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildSessionCard(ClassSession session) {
    final status = session.status.toLowerCase();
    final isActive = status == 'active' || status == 'started';
    final isEnded = status == 'ended' || status == 'completed';

    final statusColor = isActive
        ? const Color(0xFF34D399)
        : (isEnded ? Colors.redAccent : const Color(0xFFFBBF24));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordAttendanceScreen(session: session),
            ),
          );
        },
        child: _GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subjectCode,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        session.sectionName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  _buildStatChip(session.status.toUpperCase(), statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.subjectName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              _buildCardInfoRow(
                  Icons.calendar_today_rounded,
                  DateFormat('EEE, MMM d')
                      .format(session.sessionDate ?? DateTime.now())),
              if (session.actualStartTime != null)
                _buildCardInfoRow(Icons.access_time_rounded,
                    'Started: ${DateFormat('HH:mm').format(session.actualStartTime!)}'),
              if (session.attendanceCutOff != null)
                _buildCardInfoRow(Icons.timer_off_rounded,
                    'Cut-off: ${DateFormat('HH:mm').format(session.attendanceCutOff!)}'),
              _buildCardInfoRow(Icons.location_on_rounded,
                  session.actualRoomName ?? session.scheduledRoomName),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    session.startedByName ?? 'Unknown Instructor',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.3)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
          const SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('No sessions found for this filters.',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard(
      {required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
