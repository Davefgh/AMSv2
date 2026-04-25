import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/enrollment_model.dart';
import '../../../models/student_model.dart';
import '../../../models/section_model.dart';
import '../../../models/subject_model.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../utils/responsive.dart';
import '../../../config/routes/app_routes.dart';
import '../../../widgets/skeleton_loader.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final ApiService _apiService = ApiService();
  final int _selectedIndex = 1;
  String _searchQuery = '';
  List<Enrollment> _enrollments = [];
  List<Student> _students = [];
  List<Section> _sections = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getEnrollments(),
        _apiService.getStudents(),
        _apiService.getSections(),
        _apiService.getSubjects(),
      ]);

      if (mounted) {
        setState(() {
          _enrollments = results[0] as List<Enrollment>;
          _students = results[1] as List<Student>;
          _sections = results[2] as List<Section>;
          _subjects = results[3] as List<Subject>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading data: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDrop(Enrollment enrollment) async {
    try {
      await _apiService.dropEnrollment(enrollment.id);
      _fetchData();
      _showSnackBar('Student dropped successfully');
    } catch (e) {
      _showSnackBar('Error dropping student: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Enrollment',
      currentIndex: 1,
      actions: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
            onPressed: _showAddEnrollmentDialog,
          ),
        ),
      ],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const SkeletonListView()
                : _enrollments.isEmpty
                    ? _buildEmptyState()
                    : _buildEnrollmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search class code...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon:
                Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
            suffixIcon: Icon(Icons.filter_list,
                color: Colors.white.withValues(alpha: 0.5)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No enrollments found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to enroll a student',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentList() {
    final filtered = _enrollments
        .where((e) =>
            (e.studentName
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (e.sectionName
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();

    return ListView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final enrollment = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  ),
                ),
                child:
                    const Icon(Icons.school_rounded, color: Color(0xFF38BDF8)),
              ),
              title: Text(
                enrollment.studentName ?? 'Student #${enrollment.studentId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${enrollment.sectionName ?? "Section ID: ${enrollment.sectionId}"} • ${enrollment.subjectName ?? "Subject ID: ${enrollment.subjectId}"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${enrollment.academicYear} | ${enrollment.semester}',
                      style: TextStyle(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                icon: Icon(Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.6)),
                onSelected: (value) async {
                  if (value == 'drop') {
                    _handleDrop(enrollment);
                  } else if (value == 'reenroll') {
                    try {
                      await _apiService.reenrollStudent(enrollment.id);
                      _fetchData();
                      _showSnackBar('Student re-enrolled successfully');
                    } catch (e) {
                      _showSnackBar('Error: $e');
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reenroll',
                    child: Text('Re-enroll Student',
                        style: TextStyle(color: Color(0xFF34D399))),
                  ),
                  const PopupMenuItem(
                    value: 'drop',
                    child: Text('Drop Student',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddEnrollmentDialog() {
    Student? selectedStudent;
    Section? selectedSection;
    Subject? selectedSubject;

    final academicYears = ['2023-2024', '2024-2025'];
    final semesters = ['1st Semester', '2nd Semester', 'Summer'];
    String academicYear = academicYears[0];
    String semester = semesters[0];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return _GlassCard(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enroll Student',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogDropdown<Student>(
                      label: 'Student *',
                      hint: 'Select a student',
                      value: selectedStudent,
                      items: _students,
                      itemLabel: (s) => s.fullName,
                      onChanged: (value) =>
                          setStateDialog(() => selectedStudent = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown<Section>(
                      label: 'Section *',
                      hint: 'Select a section',
                      value: selectedSection,
                      items: _sections,
                      itemLabel: (s) => s.name,
                      onChanged: (value) =>
                          setStateDialog(() => selectedSection = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown<Subject>(
                      label: 'Subject *',
                      hint: 'Select a subject',
                      value: selectedSubject,
                      items: _subjects,
                      itemLabel: (s) => s.name,
                      onChanged: (value) =>
                          setStateDialog(() => selectedSubject = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSimpleDropdown(
                            label: 'A.Y.',
                            value: academicYear,
                            items: academicYears,
                            onChanged: (v) =>
                                setStateDialog(() => academicYear = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSimpleDropdown(
                            label: 'Semester',
                            value: semester,
                            items: semesters,
                            onChanged: (v) =>
                                setStateDialog(() => semester = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (selectedStudent == null ||
                                    selectedSection == null ||
                                    selectedSubject == null)
                                ? null
                                : () async {
                                    try {
                                      await _apiService.enrollStudent({
                                        'studentId': selectedStudent!.id,
                                        'sectionId': selectedSection!.id,
                                        'subjectId': selectedSubject!.id,
                                        'enrollmentType': 'Regular',
                                        'academicYear': academicYear,
                                        'semester': semester,
                                      });
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _fetchData();
                                        _showSnackBar('Enrollment successful');
                                      }
                                    } catch (e) {
                                      _showSnackBar('Enrollment failed: $e');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Enroll',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildDialogDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
              hint: Text(hint,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              value: items.contains(value) ? value : null,
              items: items
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(itemLabel(item),
                          style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              value: items.contains(value) ? value : items.first,
              items: items
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
