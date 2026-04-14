import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/subject_model.dart';
import '../../models/section_model.dart';
import '../../models/schedule_model.dart';
import '../../models/course_model.dart';
import '../../models/classroom_model.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final int _selectedIndex = 2;
  String _selectedTab = 'Classroom';
  final ApiService _apiService = ApiService();
  List<Classroom> _classroomsList = [];
  bool _isLoadingClassrooms = false;
  List<Course> _coursesList = [];
  bool _isLoadingCourses = false;
  List<Subject> _subjectsList = [];
  bool _isLoadingSubjects = false;
  List<Section> _sectionsList = [];
  bool _isLoadingSections = false;
  List<Schedule> _schedulesList = [];
  bool _isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchSections();
    _fetchSchedules();
    _fetchCourses();
    _fetchClassrooms();
  }

  Future<void> _fetchClassrooms() async {
    setState(() => _isLoadingClassrooms = true);
    try {
      final list = await _apiService.getClassrooms();
      setState(() {
        _classroomsList = list;
        _isLoadingClassrooms = false;
      });
    } catch (e) {
      setState(() => _isLoadingClassrooms = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching classrooms: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _apiService.getCourses();
      setState(() {
        _coursesList = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching courses: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  Future<void> _fetchSections() async {
    setState(() => _isLoadingSections = true);
    try {
      final sections = await _apiService.getSections();
      setState(() {
        _sectionsList = sections;
        _isLoadingSections = false;
      });
    } catch (e) {
      setState(() => _isLoadingSections = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching sections: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      final schedules = await _apiService.getSchedules();
      setState(() {
        _schedulesList = schedules;
        _isLoadingSchedules = false;
      });
    } catch (e) {
      setState(() => _isLoadingSchedules = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching schedules: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddEditSectionDialog({Section? section}) {
    final nameController = TextEditingController(text: section?.name ?? '');
    final courseIdController = TextEditingController(
        text: section?.courseId != null ? '${section!.courseId}' : '');
    final isEditing = section != null;
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      isEditing ? 'Edit Section' : 'Add Section',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Section Name',
                      hint: 'e.g. CS31A',
                      icon: Icons.layers,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: courseIdController,
                      label: 'Course ID',
                      hint: 'e.g. 1',
                      icon: Icons.book_outlined,
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
                                final courseIdText =
                                    courseIdController.text.trim();
                                final courseId = int.tryParse(courseIdText);
                                if (name.isEmpty || courseIdText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please fill in all fields.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (courseId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Course ID must be a valid number.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSaving = true);
                                try {
                                  if (isEditing) {
                                    await _updateSection(
                                        section.id, name, courseId);
                                  } else {
                                    await _createSection(name, courseId);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBBF24),
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
                                isEditing ? 'Save Changes' : 'Add Section',
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

  Future<void> _createSection(String name, int courseId) async {
    try {
      await _apiService.createSection({'name': name, 'courseId': courseId});
      await _fetchSections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section created successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating section: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateSection(int id, String name, int courseId) async {
    try {
      await _apiService
          .updateSection(id, {'name': name, 'courseId': courseId});
      await _fetchSections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section updated successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating section: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteSection(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Section',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this section? This action cannot be undone.',
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
      await _apiService.deleteSection(id);
      await _fetchSections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section deleted.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting section: $e'),
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

  void _showAddEditCourseDialog({Course? course}) {
    final nameController = TextEditingController(text: course?.name ?? '');
    final isEditing = course != null;
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      isEditing ? 'Edit Course' : 'Add Course',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Course Name',
                      hint: 'e.g. Bachelor of Science in Computer Science',
                      icon: Icons.book_outlined,
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
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a course name.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSaving = true);
                                try {
                                  if (isEditing) {
                                    await _updateCourse(course.id, name);
                                  } else {
                                    await _createCourse(name);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA78BFA),
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
                                isEditing ? 'Save Changes' : 'Add Course',
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

  Future<void> _createCourse(String name) async {
    try {
      await _apiService.createCourse({'name': name});
      await _fetchCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating course: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateCourse(int id, String name) async {
    try {
      await _apiService.updateCourse(id, {'name': name});
      await _fetchCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course updated successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating course: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteCourse(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Course',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this course? Sections referencing this course may be affected.',
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
      await _apiService.deleteCourse(id);
      await _fetchCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddEditClassroomDialog({Classroom? classroom}) {
    final nameController = TextEditingController(text: classroom?.name ?? '');
    final isEditing = classroom != null;
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      isEditing ? 'Edit Classroom' : 'Add Classroom',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogTextField(
                      controller: nameController,
                      label: 'Classroom Name',
                      hint: 'e.g. Software Laboratory 1',
                      icon: Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2–100 characters (required by server).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                if (name.length < 2 || name.length > 100) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Name must be between 2 and 100 characters.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSaving = true);
                                try {
                                  if (isEditing) {
                                    await _updateClassroom(classroom.id, name);
                                  } else {
                                    await _createClassroom(name);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60A5FA),
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
                                isEditing ? 'Save Changes' : 'Add Classroom',
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

  Future<void> _createClassroom(String name) async {
    try {
      await _apiService.createClassroom({'name': name});
      await _fetchClassrooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom created successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating classroom: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateClassroom(int id, String name) async {
    try {
      await _apiService.updateClassroom(id, {'name': name});
      await _fetchClassrooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom updated successfully!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating classroom: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteClassroom(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Classroom',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this classroom? Schedules that use it may need to be updated.',
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
      await _apiService.deleteClassroom(id);
      await _fetchClassrooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom deleted.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting classroom: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddEditScheduleDialog({Schedule? schedule}) {
    final isEditing = schedule != null;
    bool isSaving = false;

    String? initialDayOfWeek;
    if (schedule?.dayOfWeek != null) {
      initialDayOfWeek = '${schedule!.dayOfWeek}';
    } else if (schedule?.dayName != null && schedule!.dayName!.isNotEmpty) {
      initialDayOfWeek = schedule.dayName;
    }

    final timeInController =
        TextEditingController(text: schedule?.timeIn ?? '');
    final timeOutController =
        TextEditingController(text: schedule?.timeOut ?? '');
    final dayOfWeekController =
        TextEditingController(text: initialDayOfWeek ?? '');
    final subjectIdController = TextEditingController(
        text: schedule?.subjectId != null ? '${schedule!.subjectId}' : '');
    final classroomIdController = TextEditingController(
        text: schedule?.classroomId != null ? '${schedule!.classroomId}' : '');
    final sectionIdController = TextEditingController(
        text: schedule?.sectionId != null ? '${schedule!.sectionId}' : '');
    final instructorIdController = TextEditingController(
        text:
            schedule?.instructorId != null ? '${schedule!.instructorId}' : '');

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: SingleChildScrollView(
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
                        isEditing ? 'Edit Schedule' : 'Add Schedule',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDialogTextField(
                        controller: timeInController,
                        label: 'Time In',
                        hint: 'e.g. 08:00:00',
                        icon: Icons.login,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: timeOutController,
                        label: 'Time Out',
                        hint: 'e.g. 09:00:00',
                        icon: Icons.logout,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: dayOfWeekController,
                        label: 'Day of Week',
                        hint: '1-7 or Monday',
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: subjectIdController,
                        label: 'Subject ID',
                        hint: 'e.g. 1',
                        icon: Icons.subject,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: classroomIdController,
                        label: 'Classroom ID',
                        hint: 'e.g. 1',
                        icon: Icons.meeting_room,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: sectionIdController,
                        label: 'Section ID',
                        hint: 'e.g. 1',
                        icon: Icons.layers,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: instructorIdController,
                        label: 'Instructor ID',
                        hint: 'e.g. 1',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final timeIn =
                                      timeInController.text.trim();
                                  final timeOut =
                                      timeOutController.text.trim();
                                  if (timeIn.isEmpty || timeOut.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Time In and Time Out are required.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  Map<String, dynamic> payload = {
                                    'timeIn': timeIn,
                                    'timeOut': timeOut,
                                    'dayOfWeek':
                                        dayOfWeekController.text.trim().isEmpty
                                            ? null
                                            : (int.tryParse(
                                                    dayOfWeekController.text
                                                        .trim()) ??
                                                dayOfWeekController.text.trim()),
                                    'subjectId': subjectIdController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : int.tryParse(
                                            subjectIdController.text.trim()),
                                    'classroomId': classroomIdController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : int.tryParse(classroomIdController.text
                                            .trim()),
                                    'sectionId': sectionIdController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : int.tryParse(
                                            sectionIdController.text.trim()),
                                    'instructorId': instructorIdController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : int.tryParse(instructorIdController.text
                                            .trim()),
                                  };

                                  setModalState(() => isSaving = true);
                                  try {
                                    if (isEditing) {
                                      await _apiService.updateSchedule(
                                          schedule.id, payload);
                                    } else {
                                      await _apiService.createSchedule(payload);
                                    }
                                    await _fetchSchedules();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error saving schedule: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
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
                                  isEditing ? 'Save Changes' : 'Add Schedule',
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this schedule? This action cannot be undone.',
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
      await _apiService.deleteSchedule(id);
      await _fetchSchedules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

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
                if (_selectedTab == 'Classroom') {
                  _showAddEditClassroomDialog();
                } else if (_selectedTab == 'Subjects') {
                  _showAddEditSubjectDialog();
                } else if (_selectedTab == 'Courses') {
                  _showAddEditCourseDialog();
                } else if (_selectedTab == 'Sections') {
                  _showAddEditSectionDialog();
                } else if (_selectedTab == 'Schedule') {
                  _showAddEditScheduleDialog();
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
              child: _buildOverviewCard(
                  'Total Classrooms',
                  '${_classroomsList.length}',
                  Icons.meeting_room,
                  const Color(0xFF60A5FA),
                  100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Classrooms',
                  '${_classroomsList.length}',
                  Icons.check_circle,
                  const Color(0xFF34D399),
                  100),
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
              child: _buildOverviewCard('Total Courses', '${_coursesList.length}',
                  Icons.book, const Color(0xFFA78BFA), 100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard('Active Courses', '${_coursesList.length}',
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
              child: _buildOverviewCard('Total Sections', '${_sectionsList.length}',
                  Icons.layers, const Color(0xFFFBBF24), 100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Sections',
                  '${_sectionsList.length}',
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
                  '${_schedulesList.length}',
                  Icons.schedule,
                  const Color(0xFF14B8A6),
                  100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Schedules',
                  '${_schedulesList.length}',
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

  Widget _buildClassroomsList() {
    if (_isLoadingClassrooms) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF60A5FA)),
        ),
      );
    }

    if (_classroomsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.meeting_room_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'No classrooms found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showAddEditClassroomDialog(),
                icon: const Icon(Icons.add, color: Color(0xFF60A5FA)),
                label: const Text(
                  'Add Classroom',
                  style: TextStyle(color: Color(0xFF60A5FA)),
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
        _buildListHeader('Classrooms List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_classroomsList.length, (index) {
            final classroom = _classroomsList[index];
            return _buildClassroomListItem(classroom);
          }),
        ),
      ],
    );
  }

  Widget _buildClassroomListItem(Classroom classroom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.meeting_room,
                color: Color(0xFF60A5FA),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${classroom.id}',
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
                  _showAddEditClassroomDialog(classroom: classroom);
                } else if (value == 'delete') {
                  _deleteClassroom(classroom.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF60A5FA), size: 20),
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

  Widget _buildCoursesList() {
    if (_isLoadingCourses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFA78BFA)),
        ),
      );
    }

    if (_coursesList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.book_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'No courses found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showAddEditCourseDialog(),
                icon: const Icon(Icons.add, color: Color(0xFFA78BFA)),
                label: const Text(
                  'Add Course',
                  style: TextStyle(color: Color(0xFFA78BFA)),
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
        _buildListHeader('Courses List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_coursesList.length, (index) {
            final course = _coursesList[index];
            return _buildCourseListItem(course);
          }),
        ),
      ],
    );
  }

  Widget _buildCourseListItem(Course course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.book,
                color: Color(0xFFA78BFA),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${course.id}',
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
                  _showAddEditCourseDialog(course: course);
                } else if (value == 'delete') {
                  _deleteCourse(course.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFFA78BFA), size: 20),
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

  Widget _buildSectionsList() {
    if (_isLoadingSections) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
        ),
      );
    }

    if (_sectionsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.layers_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'No sections found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showAddEditSectionDialog(),
                icon: const Icon(Icons.add, color: Color(0xFFFBBF24)),
                label: const Text(
                  'Add Section',
                  style: TextStyle(color: Color(0xFFFBBF24)),
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
        _buildListHeader('Sections List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_sectionsList.length, (index) {
            final section = _sectionsList[index];
            return _buildSectionListItem(section);
          }),
        ),
      ],
    );
  }

  Widget _buildSectionListItem(Section section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.layers,
                color: Color(0xFFFBBF24),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.courseId != null
                        ? 'Course ID: ${section.courseId}'
                        : 'ID: ${section.id}',
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
                  _showAddEditSectionDialog(section: section);
                } else if (value == 'delete') {
                  _deleteSection(section.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFFFBBF24), size: 20),
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
    if (_isLoadingSchedules) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
        ),
      );
    }

    if (_schedulesList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text(
                'No schedules found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader('Schedule List'),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_schedulesList.length, (index) {
            final schedule = _schedulesList[index];
            return _buildScheduleListItem(schedule);
          }),
        ),
      ],
    );
  }

  Widget _buildScheduleListItem(Schedule schedule) {
    final subject = schedule.subjectName.isNotEmpty
        ? schedule.subjectName
        : (schedule.subjectId != null ? 'Subject #${schedule.subjectId}' : '');
    final section = schedule.sectionName.isNotEmpty
        ? schedule.sectionName
        : (schedule.sectionId != null ? 'Section #${schedule.sectionId}' : '');
    final classroom = schedule.classroomName.isNotEmpty
        ? schedule.classroomName
        : (schedule.classroomId != null
            ? 'Classroom #${schedule.classroomId}'
            : '');
    final line2Parts = <String>[
      if (subject.isNotEmpty) subject,
      if (section.isNotEmpty) section,
      if (classroom.isNotEmpty) classroom,
    ];
    final line2 = line2Parts.join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF14B8A6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.displayDay.isNotEmpty
                        ? schedule.displayDay
                        : 'Schedule',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (schedule.timeIn.isNotEmpty ||
                          schedule.timeOut.isNotEmpty)
                        '${schedule.timeIn} - ${schedule.timeOut}',
                      if (line2.isNotEmpty) line2,
                    ].join('\n'),
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
                  _showAddEditScheduleDialog(schedule: schedule);
                } else if (value == 'delete') {
                  _deleteSchedule(schedule.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF14B8A6), size: 20),
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
