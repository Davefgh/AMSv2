import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/skeleton_loader.dart';

class SectionStudentsScreen extends StatefulWidget {
  final int sectionId;
  final String sectionName;

  const SectionStudentsScreen({
    super.key,
    required this.sectionId,
    required this.sectionName,
  });

  @override
  State<SectionStudentsScreen> createState() => _SectionStudentsScreenState();
}

class _SectionStudentsScreenState extends State<SectionStudentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Student> _students = [];
  String _selectedStatus = 'All'; // Filter state

  final List<String> _statusOptions = ['All', 'Regular', 'Irregular'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _apiService.getStudentsBySection(widget.sectionId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
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

  List<Student> get _filteredStudents {
    if (_selectedStatus == 'All') {
      return _students;
    } else if (_selectedStatus == 'Regular') {
      return _students.where((s) => s.isRegular).toList();
    } else {
      return _students.where((s) => !s.isRegular).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '${widget.sectionName} Students',
      currentIndex: -1,
      isAdmin: false,
      showBackButton: true,
      body: Stack(
        children: [
          _buildBackground(),
          _isLoading
              ? const SkeletonListView()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              'No students enrolled',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no students in this section yet.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final filteredStudents = _filteredStudents;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: const Color(0xFF38BDF8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected 
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Student list
            if (filteredStudents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'No $_selectedStatus students',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentItem(student);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(Student student) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  student.firstname.isNotEmpty ? student.firstname[0] : '?',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.isRegular 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: student.isRegular 
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          student.isRegular ? 'Regular' : 'Irregular',
                          style: TextStyle(
                            color: student.isRegular ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${student.id}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline_rounded, color: Colors.white12, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          bottom: -100,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),
      ],
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
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
