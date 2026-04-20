import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/main_scaffold.dart';
import '../../providers/app_provider.dart';
import '../../config/routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../utils/sizing_utils.dart';
import '../../models/student_subject_detail.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentSubjectDetail> _subjects = [];

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
      final subjects = await _apiService.getStudentSubjects();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Student Dashboard',
      currentIndex: 0,
      isAdmin: false,
      isStudent: true,
      actions: [
        IconButton(
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          icon: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          splashRadius: 20,
        ),
        const SizedBox(width: 12),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF38BDF8),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: EdgeInsets.symmetric(horizontal: Sizing.w(24), vertical: Sizing.h(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeHeader(),
                          SizedBox(height: Sizing.h(32)),
                          _buildAttendanceStats(),
                          SizedBox(height: Sizing.h(32)),
                          _buildUpcomingSessions(),
                        ],
                      ),
                    ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: Sizing.sp(16),
          ),
        ),
        Text(
          'Ready to Learn?',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(28),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: Sizing.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_subjects.length} Subjects',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: Sizing.sp(13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_subjects.isEmpty)
          _buildEmptySessions()
        else
          ..._subjects.map((s) => _buildSubjectCard(s)),
      ],
    );
  }

  Widget _buildSubjectCard(StudentSubjectDetail detail) {
    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(16)),
      width: double.infinity,
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Sizing.w(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Sizing.r(12)),
                ),
                child: Icon(Icons.book_rounded, color: const Color(0xFF38BDF8), size: Sizing.sp(20)),
              ),
              SizedBox(width: Sizing.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.subject.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Sizing.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      detail.subject.code,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: Sizing.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Sizing.w(10), vertical: Sizing.h(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Sizing.r(8)),
                ),
                child: Text(
                  detail.schedule.displayDay,
                  style: TextStyle(
                    color: const Color(0xFF38BDF8),
                    fontSize: Sizing.sp(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time_rounded,
                '${detail.schedule.timeIn.substring(0, 5)} - ${detail.schedule.timeOut.substring(0, 5)}',
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _buildInfoChip(
                  Icons.room_rounded,
                  detail.classroom.name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, size: 14, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Instructor: ${detail.instructor.fullName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sizing.w(10), vertical: Sizing.h(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Sizing.sp(14), color: Colors.white.withValues(alpha: 0.4)),
          SizedBox(width: Sizing.w(6)),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: Sizing.sp(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sessions scheduled',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your upcoming classes will appear here.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: Sizing.sp(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(16)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Present',
                '0',
                Colors.greenAccent,
                Icons.check_circle_outline_rounded,
              ),
            ),
            SizedBox(width: Sizing.w(16)),
            Expanded(
              child: _buildStatCard(
                'Absent',
                '0',
                Colors.redAccent,
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Sizing.sp(20)),
          ),
          SizedBox(height: Sizing.h(16)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: Sizing.sp(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: Sizing.sp(13),
            ),
          ),
        ],
      ),
    );
  }
}
