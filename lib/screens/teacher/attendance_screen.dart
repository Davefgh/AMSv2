import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/session_model.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'record_attendance_screen.dart';
import '../../widgets/skeleton_loader.dart';
import '../../providers/app_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sessions = await _apiService.getMySessions();

      int active = 0, pending = 0, ended = 0;
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

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _stats = {'active': active, 'pending': pending, 'ended': ended};
          _isLoading = false;
          _applyFilters();
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSessions = _sessions.where((s) {
        final matchesSearch = s.subjectName.toLowerCase().contains(query) ||
            s.subjectCode.toLowerCase().contains(query) ||
            s.sectionName.toLowerCase().contains(query);

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
    final isDark = ref.watch(appProvider).isDarkMode;
    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: _isLoading
              ? const SkeletonSessionList()
              : _errorMessage != null
                  ? _buildErrorState(isDark)
                  : RefreshIndicator(
                      color: const Color(0xFF38BDF8),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      onRefresh: _loadData,
                      child: _filteredSessions.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              itemCount: _filteredSessions.length,
                              itemBuilder: (context, index) =>
                                  _buildSessionCard(
                                      _filteredSessions[index], isDark),
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final subtitleColor =
        isDark ? Colors.white54 : const Color(0xFF001F3F).withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a session to record or view attendance',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 200, maxWidth: 300),
                  child: _buildSearchField(isDark),
                ),
                const SizedBox(width: 12),
                _buildDatePicker(isDark),
                const SizedBox(width: 12),
                _buildStatusDropdown(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF001F3F).withOpacity(0.15);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF001F3F).withOpacity(0.35);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: const Color(0xFF001F3F).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF001F3F).withOpacity(0.15);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF001F3F);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF001F3F).withOpacity(0.4);

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF38BDF8),
                      onPrimary: Color(0xFF0F172A),
                      surface: Color(0xFF1E293B),
                    )
                  : const ColorScheme.light(
                      primary: Color(0xFF001F3F),
                      onPrimary: Colors.white,
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
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: const Color(0xFF001F3F).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              DateFormat('MM/dd/yyyy').format(_selectedDate),
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF001F3F).withOpacity(0.15);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF001F3F);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF001F3F).withOpacity(0.4);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: const Color(0xFF001F3F).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.filter_list, color: iconColor, size: 18),
          style: TextStyle(color: textColor, fontSize: 13),
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

  Widget _buildSessionCard(ClassSession session, bool isDark) {
    final status = session.status.toLowerCase();
    final isActive = status == 'active' || status == 'started';
    final isEnded = status == 'ended' || status == 'completed';

    final statusColor = isActive
        ? const Color(0xFF34D399)
        : (isEnded ? Colors.redAccent : const Color(0xFFFBBF24));

    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final subColor = isDark
        ? Colors.white70
        : const Color(0xFF001F3F).withOpacity(0.55);
    final infoColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF001F3F).withOpacity(0.45);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF001F3F).withOpacity(0.3);
    final dividerColor = isDark
        ? Colors.white10
        : const Color(0xFF001F3F).withOpacity(0.08);
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xFF001F3F).withOpacity(0.2);

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
        child: _ThemedCard(
          isDark: isDark,
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
                        style: TextStyle(color: subColor, fontSize: 11),
                      ),
                    ],
                  ),
                  _buildStatChip(session.status.toUpperCase(), statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.subjectName,
                style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.calendar_today_rounded,
                  DateFormat('EEE, MMM d')
                      .format(session.sessionDate ?? DateTime.now()),
                  infoColor, iconColor),
              if (session.actualStartTime != null)
                _buildInfoRow(Icons.access_time_rounded,
                    'Started: ${DateFormat('HH:mm').format(session.actualStartTime!)}',
                    infoColor, iconColor),
              if (session.attendanceCutOff != null)
                _buildInfoRow(Icons.timer_off_rounded,
                    'Cut-off: ${DateFormat('HH:mm').format(session.attendanceCutOff!)}',
                    infoColor, iconColor),
              _buildInfoRow(Icons.location_on_rounded,
                  session.actualRoomName ?? session.scheduledRoomName,
                  infoColor, iconColor),
              const SizedBox(height: 16),
              Divider(color: dividerColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    session.startedByName ?? 'Unknown Instructor',
                    style: TextStyle(
                        color: subColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: chevronColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, Color textColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    final textColor =
        isDark ? Colors.white70 : const Color(0xFF001F3F).withOpacity(0.6);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF001F3F).withOpacity(0.4);
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF001F3F).withOpacity(0.15);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text('No sessions found for this filters.',
                style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _ThemedCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _ThemedCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: child,
          ),
        ),
      );
    }
    // Light mode: clean white card with navy shadow
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF001F3F).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
