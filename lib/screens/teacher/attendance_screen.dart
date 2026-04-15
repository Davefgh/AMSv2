import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/attendance_model.dart';
import 'dart:ui';
import '../../widgets/main_scaffold.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<AttendanceRecord> _attendances = [];

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
      final response = await _apiService.getAttendances();
      setState(() {
        _attendances = response.items;
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
      title: 'Attendance Records',
      currentIndex: 1,
      isAdmin: false,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF1E293B),
                  onRefresh: _loadData,
                  child: _attendances.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          itemCount: _attendances.length,
                          itemBuilder: (context, index) {
                            final record = _attendances[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Student ID: ${record.studentId}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Session: ${record.sessionId}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(record.status)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: _getStatusColor(record.status)
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        record.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(record.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
                size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No attendance records found.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.greenAccent;
      case 'absent':
        return Colors.redAccent;
      case 'late':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
