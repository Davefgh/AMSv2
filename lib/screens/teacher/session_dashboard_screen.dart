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

  void _onCreateSession() {
    if (_instructorSchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No schedules assigned to you.')));
      return;
    }
    
    // Quick Pick: Nearest or just open first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SessionDetailsScreen(schedule: _instructorSchedules.first)),
    ).then((_) => _loadData());
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Management',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              Text(
                'Manage your class sessions and tracking',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _onCreateSession,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF818CF8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final isCancelled = status == 'cancelled' || status == 'deleted';
    final isEnded = status == 'ended' || status == 'completed';

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
                        ? '${DateFormat('h:mm a').format(s.actualStartTime!)} - ${s.actualEndTime != null ? DateFormat('h:mm a').format(s.actualEndTime!) : 'TBD'}'
                        : 'Time TBD',
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
