import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/session_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../widgets/skeleton_loader.dart';

class RecordAttendanceScreen extends StatefulWidget {
  final ClassSession session;
  const RecordAttendanceScreen({super.key, required this.session});

  @override
  State<RecordAttendanceScreen> createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends State<RecordAttendanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  Map<int, AttendanceRecord?> _existingRecords = {};
  Map<int, String> _modifiedStatuses = {}; // studentId -> status

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterStudents);
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
      // 1. Fetch the Schedule to get the sectionId
      final schedule = await _apiService.getSchedule(widget.session.scheduleId);
      final sectionId = schedule.sectionId;

      if (sectionId == null) {
        throw Exception('This session has no associated section.');
      }

      // 2. Fetch Students for the section
      final students = await _apiService.getStudentsBySection(sectionId);
      
      // 3. Fetch Attendance Records for the session
      final records = await _apiService.getAttendanceBySession(widget.session.id);
      
      final recordsMap = {for (var r in records) r.studentId: r};
      
      setState(() {
        _students = students;
        _filteredStudents = students;
        _existingRecords = recordsMap;
        // Initialize modified statuses with existing or default
        _modifiedStatuses = {
          for (var s in students) 
            s.id: recordsMap[s.id]?.status ?? 'absent'
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((s) => 
        s.fullName.toLowerCase().contains(query) || 
        s.id.toString().contains(query)
      ).toList();
    });
  }

  void _updateStatus(int studentId, String status) {
    setState(() {
      _modifiedStatuses[studentId] = status;
    });
  }

  void _markAll(String status) {
    setState(() {
      for (var s in _students) {
        _modifiedStatuses[s.id] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      for (var studentId in _modifiedStatuses.keys) {
        final newStatus = _modifiedStatuses[studentId]!;
        final existing = _existingRecords[studentId];
        
        if (existing == null) {
          // Create new record
          await _apiService.createAttendance({
            'sessionId': widget.session.id,
            'studentId': studentId,
            'status': newStatus,
          });
        } else if (existing.status != newStatus) {
          // Update existing
          await _apiService.updateAttendance(existing.id, {
            'status': newStatus,
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Color(0xFF34D399)),
        );
      }
      await _loadData(); // Refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int present = _modifiedStatuses.values.where((v) => v == 'present').length;
    int absent = _modifiedStatuses.values.where((v) => v == 'absent').length;
    int late = _modifiedStatuses.values.where((v) => v == 'late').length;
    int excused = _modifiedStatuses.values.where((v) => v == 'excused').length;
    double rate = _students.isEmpty ? 0 : (present + late) / _students.length * 100;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSessionHeader(),
                _buildStatsRow(present, absent, late, excused, rate),
                _buildControls(),
                Expanded(
                  child: _isLoading
                      ? const SkeletonListView()
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _buildStudentList(),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Record Attendance',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Sessions', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.session.subjectCode,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.session.sectionName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.session.subjectName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(widget.session.sessionDate ?? DateTime.now()),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 6),
                Text(
                  '${_students.length} Students',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int p, int a, int l, int e, double rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(p.toString(), 'Present', const Color(0xFF34D399)),
            _buildStatCard(a.toString(), 'Absent', Colors.redAccent),
            _buildStatCard(l.toString(), 'Late', const Color(0xFFFBBF24)),
            _buildStatCard(e.toString(), 'Excused', const Color(0xFF38BDF8)),
            _buildStatCard('${rate.toStringAsFixed(0)}%', 'Rate', Colors.indigoAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallButton(
                  onPressed: () => _markAll('present'),
                  label: 'Mark All Present',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallButton(
                  onPressed: () => _markAll('absent'),
                  label: 'Mark All Absent',
                  icon: Icons.highlight_off_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818CF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.save_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({required VoidCallback onPressed, required String label, required IconData icon, required Color color}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final s = _filteredStudents[index];
        final status = _modifiedStatuses[s.id] ?? 'absent';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                child: Text(
                  s.firstname[0],
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'ID: ${s.id}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildStatusPicker(s.id, status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPicker(int studentId, String currentStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white24),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          items: ['present', 'absent', 'late', 'excused'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.toUpperCase(),
                style: TextStyle(color: _getStatusColor(value)),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) _updateStatus(studentId, newValue);
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF34D399);
      case 'late': return const Color(0xFFFBBF24);
      case 'excused': return const Color(0xFF38BDF8);
      case 'absent': return Colors.redAccent;
      default: return Colors.white54;
    }
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
