import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/subject_model.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  int _selectedIndex = 2;
  String _selectedTab = 'Classroom';
  final List<Map<String, dynamic>> _classrooms = [
    {'name': 'Room 101', 'id': '1', 'selected': false},
    {'name': 'Room 102', 'id': '2', 'selected': false},
    {'name': 'Room 103', 'id': '3', 'selected': false},
    {'name': 'Room 104', 'id': '4', 'selected': false},
  ];
  final List<Map<String, dynamic>> _courses = [
    {
      'name': 'Introduction to Computer Science',
      'code': 'CS101',
      'selected': false
    },
    {'name': 'Data Structures', 'code': 'CS201', 'selected': false},
    {'name': 'Web Development', 'code': 'CS301', 'selected': false},
  ];
  final List<Map<String, dynamic>> _sections = [
    {'name': 'CS31A', 'capacity': '40', 'selected': false},
    {'name': 'CS31B', 'capacity': '35', 'selected': false},
    {'name': 'CS32A', 'capacity': '38', 'selected': false},
  ];
  final ApiService _apiService = ApiService();
  List<Subject> _subjectsList = [];
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final subjects = await _apiService.getSubjects();
      setState(() {
        _subjectsList = subjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching subjects: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddEditSubjectDialog({Subject? subject}) {
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final isEditing = subject != null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? 'Edit Subject' : 'Add Subject',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Subject Name',
                      hint: 'e.g. Computing Fundamentals',
                      icon: Icons.subject,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: codeController,
                      label: 'Subject Code',
                      hint: 'e.g. IT1008',
                      icon: Icons.tag,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final code = codeController.text.trim();
                                if (name.isEmpty || code.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill in all fields.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSaving = true);
                                try {
                                  if (isEditing) {
                                    await _updateSubject(subject.id, name, code);
                                  } else {
                                    await _createSubject(name, code);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Add Subject',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createSubject(String name, String code) async {
    try {
      await _apiService.createSubject({'name': name, 'code': code});
      await _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject created successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating subject: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateSubject(int id, String name, String code) async {
    try {
      await _apiService.updateSubject(id, {'name': name, 'code': code});
      await _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject updated successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating subject: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteSubject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this subject? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteSubject(id);
      await _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject deleted.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting subject: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
  final List<Map<String, dynamic>> _schedules = [
    {
      'day': 'Monday',
      'time': '08:00 AM - 10:00 AM',
      'room': 'Room 101',
      'selected': false
    },
    {
      'day': 'Wednesday',
      'time': '10:00 AM - 12:00 PM',
      'room': 'Room 102',
      'selected': false
    },
    {
      'day': 'Friday',
      'time': '02:00 PM - 04:00 PM',
      'room': 'Room 103',
      'selected': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Stack(
        children: [
          // Background Glowing Orbs for ambiance
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(0xFF38BDF8).withValues(alpha: 0.3), // Sky Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      blurRadius: 100,
                      spreadRadius: 50)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(0xFF1E3A8A).withValues(alpha: 0.5), // Navy Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                      blurRadius: 120,
                      spreadRadius: 60)
                ],
              ),
            ),
          ),
          // Backdrop blur for the glowing orbs
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    children: [
                      if (_selectedTab == 'Classroom') ...[
                        _buildClassroomsOverview(),
                        const SizedBox(height: 32),
                        _buildClassroomsList(),
                      ] else if (_selectedTab == 'Courses') ...[
                        _buildCoursesOverview(),
                        const SizedBox(height: 32),
                        _buildCoursesList(),
                      ] else if (_selectedTab == 'Sections') ...[
                        _buildSectionsOverview(),
                        const SizedBox(height: 32),
                        _buildSectionsList(),
                      ] else if (_selectedTab == 'Subjects') ...[
                        _buildSubjectsOverview(),
                        const SizedBox(height: 32),
                        _buildSubjectsList(),
                      ] else if (_selectedTab == 'Schedule') ...[
                        _buildScheduleOverview(),
                        const SizedBox(height: 32),
                        _buildScheduleList(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/aclc_logo.png',
                height: 48,
                width: 48,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              const Text(
                'Classes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
              onPressed: () {
                if (_selectedTab == 'Subjects') {
                  _showAddEditSubjectDialog();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Classroom', 'Courses', 'Sections', 'Subjects', 'Schedule'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = _selectedTab == tab;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = tab);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color:
                                const Color(0xFF38BDF8).withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int percentage,
  ) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classrooms Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard('Total Classrooms', '27',
                  Icons.meeting_room, const Color(0xFF60A5FA), 100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard('Active Classrooms', '27',
                  Icons.check_circle, const Color(0xFF34D399), 100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoursesOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard('Total Courses', '${_courses.length}',
                  Icons.book, const Color(0xFFA78BFA), 100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard('Active Courses', '${_courses.length}',
                  Icons.check_circle, const Color(0xFF34D399), 100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sections Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard('Total Sections', '${_sections.length}',
                  Icons.layers, const Color(0xFFFBBF24), 100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Sections',
                  '${_sections.length}',
                  Icons.check_circle,
                  const Color(0xFF34D399),
                  100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subjects Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                  'Total Subjects',
                  '${_subjectsList.length}',
                  Icons.subject,
                  const Color(0xFFF87171),
                  100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Subjects',
                  '${_subjectsList.length}',
                  Icons.check_circle,
                  const Color(0xFF34D399),
                  100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                  'Total Schedules',
                  '${_schedules.length}',
                  Icons.schedule,
                  const Color(0xFF14B8A6),
                  100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Schedules',
                  '${_schedules.length}',
                  Icons.check_circle,
                  const Color(0xFF34D399),
                  100),
            ),
          ],
        ),
      ],
    );
  }

  // --- List Builders ---

  Widget _buildListHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        _buildListPopupMenu(),
      ],
    );
  }

  Widget _buildListPopupMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.6)),
      color: const Color(0xFF1E293B), // Dark slate
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'select_all',
          child: Row(
            children: [
              Icon(Icons.select_all, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Select All', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Classrooms List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_classrooms.length, (index) {
            final classroom = _classrooms[index];
            return _buildGlassListItem(
              icon: Icons.meeting_room,
              iconColor: const Color(0xFF60A5FA),
              title: classroom['name'] ?? '',
              subtitle: 'ID: ${classroom['id']}',
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCoursesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Courses List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_courses.length, (index) {
            final course = _courses[index];
            return _buildGlassListItem(
              icon: Icons.book,
              iconColor: const Color(0xFFA78BFA),
              title: course['name'] ?? '',
              subtitle: 'Code: ${course['code']}',
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSectionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Sections List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_sections.length, (index) {
            final section = _sections[index];
            return _buildGlassListItem(
              icon: Icons.layers,
              iconColor: const Color(0xFFFBBF24),
              title: section['name'] ?? '',
              subtitle: 'Capacity: ${section['capacity']}',
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubjectsList() {
    if (_isLoadingSubjects) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (_subjectsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.subject_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'No subjects found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showAddEditSubjectDialog(),
                icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
                label: const Text(
                  'Add Subject',
                  style: TextStyle(color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Subjects List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_subjectsList.length, (index) {
            final subject = _subjectsList[index];
            return _buildSubjectListItem(subject);
          }),
        ),
      ],
    );
  }

  Widget _buildSubjectListItem(Subject subject) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF87171).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF87171).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.subject,
                color: Color(0xFFF87171),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${subject.code}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.5)),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditSubjectDialog(subject: subject);
                } else if (value == 'delete') {
                  _deleteSubject(subject.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 12),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Delete',
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Schedule List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_schedules.length, (index) {
            final schedule = _schedules[index];
            return _buildGlassListItem(
              icon: Icons.schedule,
              iconColor: const Color(0xFF14B8A6),
              title: schedule['day'] ?? '',
              subtitle: '${schedule['time']} • ${schedule['room']}',
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded), label: 'Enrollment'),
          BottomNavigationBarItem(
              icon: Icon(Icons.class_rounded), label: 'Classes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Users'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/enrollment');
          } else if (index == 2) {
            // Already on classes
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/users');
          }
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.height,
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
