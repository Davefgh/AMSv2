import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/subject_model.dart';
import '../../../models/section_model.dart';
import '../../../models/schedule_model.dart';
import '../../../models/course_model.dart';
import '../../../models/classroom_model.dart';
import '../../../models/instructor_model.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../widgets/skeleton_loader.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
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
  List<Instructor> _instructorsList = [];
  bool _isLoadingInstructors = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchSections();
    _fetchSchedules();
    _fetchCourses();
    _fetchClassrooms();
    _fetchInstructors();
  }

  Future<void> _fetchInstructors() async {
    setState(() => _isLoadingInstructors = true);
    try {
      final instructors = await _apiService.getInstructors();
      setState(() {
        _instructorsList = instructors;
        _isLoadingInstructors = false;
      });
    } catch (e) {
      setState(() => _isLoadingInstructors = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching instructors: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
    Map<String, List<String>> fieldErrors = {};

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
                      errorText: fieldErrors['name']?.first ??
                          fieldErrors['Name']?.first,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdownField<String>(
                      label: 'Course',
                      hint: 'Select a course',
                      icon: Icons.book_outlined,
                      value: courseIdController.text.isNotEmpty
                          ? courseIdController.text
                          : null,
                      items: _coursesList
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          courseIdController.text = val;
                        }
                      },
                      errorText: fieldErrors['courseId']?.first ??
                          fieldErrors['CourseId']?.first,
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
                                final courseId = courseIdController.text.trim();
                                if (name.isEmpty || courseId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please fill in all fields.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() {
                                  isSaving = true;
                                  fieldErrors = {};
                                });
                                try {
                                  if (isEditing) {
                                    await _updateSection(
                                        section.id, name, courseId);
                                  } else {
                                    await _createSection(name, courseId);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } on ApiException catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    fieldErrors = e.fieldErrors.map((k, v) =>
                                        MapEntry(k.replaceAll('\$.', ''), v));
                                  });
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

  Future<void> _createSection(String name, String courseId) async {
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

  Future<void> _updateSection(String id, String name, String courseId) async {
    try {
      await _apiService.updateSection(id, {'name': name, 'courseId': courseId});
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

  Future<void> _deleteSection(String id) async {
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
    Map<String, List<String>> fieldErrors = {};

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
                      errorText: fieldErrors['name']?.first ??
                          fieldErrors['Name']?.first,
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                      controller: codeController,
                      label: 'Subject Code',
                      hint: 'e.g. IT1008',
                      icon: Icons.tag,
                      errorText: fieldErrors['code']?.first ??
                          fieldErrors['Code']?.first,
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
                                      content:
                                          Text('Please fill in all fields.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() {
                                  isSaving = true;
                                  fieldErrors = {};
                                });
                                try {
                                  if (isEditing) {
                                    await _updateSubject(
                                        subject.id, name, code);
                                  } else {
                                    await _createSubject(name, code);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } on ApiException catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    fieldErrors = e.fieldErrors.map((k, v) =>
                                        MapEntry(k.replaceAll('\$.', ''), v));
                                  });
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
    String? errorText,
    bool readOnly = false,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            errorText: errorText,
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _buildDialogDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required IconData icon,
    String hint = 'Select an option',
    String? errorText,
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
        DropdownButtonFormField<T>(
          initialValue: items.any((item) => item.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            errorText: errorText,
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _buildDialogTimePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return _buildDialogTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      errorText: errorText,
      readOnly: true,
      onTap: () =>
          _showScrollableTimePicker(context: context, controller: controller),
    );
  }

  Future<void> _showScrollableTimePicker({
    required BuildContext context,
    required TextEditingController controller,
  }) async {
    // Parse existing value
    int selectedHour = 6;
    int selectedMinute = 0;
    bool isAM = true;

    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        final h = int.parse(parts[0]);
        selectedMinute = int.parse(parts[1]);
        isAM = h < 12;
        selectedHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      } catch (_) {}
    }

    final hourCtrl = FixedExtentScrollController(initialItem: selectedHour - 1);
    final minCtrl = FixedExtentScrollController(initialItem: selectedMinute);
    final amPmCtrl = FixedExtentScrollController(initialItem: isAM ? 0 : 1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setS) {
          Widget wheel({
            required FixedExtentScrollController ctrl,
            required int count,
            required String Function(int) label,
            required int selectedIndex,
            required void Function(int) onChanged,
            double width = 90,
          }) {
            return SizedBox(
              width: width,
              child: ListWheelScrollView.useDelegate(
                controller: ctrl,
                itemExtent: 70,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.002,
                diameterRatio: 1.5,
                onSelectedItemChanged: (i) => setS(() => onChanged(i)),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (_, index) {
                    final isSel = index == selectedIndex;
                    return Center(
                      child: Text(
                        label(index),
                        style: TextStyle(
                          color: isSel
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                          fontSize: isSel ? 46 : 30,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w300,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF080808),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Selection indicator lines
                      Positioned(
                        child: Container(
                          height: 70,
                          decoration: const BoxDecoration(
                            border: Border.symmetric(
                              horizontal:
                                  BorderSide(color: Colors.white12, width: 1),
                            ),
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hours
                          wheel(
                            ctrl: hourCtrl,
                            count: 12,
                            label: (i) => '${i + 1}',
                            selectedIndex: selectedHour - 1,
                            onChanged: (i) => selectedHour = i + 1,
                          ),

                          // Colon separator
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Minutes
                          wheel(
                            ctrl: minCtrl,
                            count: 60,
                            label: (i) => i.toString().padLeft(2, '0'),
                            selectedIndex: selectedMinute,
                            onChanged: (i) => selectedMinute = i,
                          ),

                          const SizedBox(width: 8),

                          // AM / PM
                          wheel(
                            ctrl: amPmCtrl,
                            count: 2,
                            label: (i) => i == 0 ? 'AM' : 'PM',
                            selectedIndex: isAM ? 0 : 1,
                            onChanged: (i) => isAM = i == 0,
                            width: 72,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      int h = selectedHour;
                      if (!isAM && h != 12) h += 12;
                      if (isAM && h == 12) h = 0;
                      controller.text =
                          '${h.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}:00';
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Set Time',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
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

  Future<void> _updateSubject(String id, String name, String code) async {
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

  Future<void> _deleteSubject(String id) async {
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
    Map<String, List<String>> fieldErrors = {};

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
                      errorText: fieldErrors['name']?.first ??
                          fieldErrors['Name']?.first,
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
                                      content:
                                          Text('Please enter a course name.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() {
                                  isSaving = true;
                                  fieldErrors = {};
                                });
                                try {
                                  if (isEditing) {
                                    await _updateCourse(course.id, name);
                                  } else {
                                    await _createCourse(name);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } on ApiException catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    fieldErrors = e.fieldErrors.map((k, v) =>
                                        MapEntry(k.replaceAll('\$.', ''), v));
                                  });
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

  Future<void> _updateCourse(String id, String name) async {
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

  Future<void> _deleteCourse(String id) async {
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
    Map<String, List<String>> fieldErrors = {};

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
                      errorText: fieldErrors['name']?.first ??
                          fieldErrors['Name']?.first,
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
                                setModalState(() {
                                  isSaving = true;
                                  fieldErrors = {};
                                });
                                try {
                                  if (isEditing) {
                                    await _updateClassroom(classroom.id, name);
                                  } else {
                                    await _createClassroom(name);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } on ApiException catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    fieldErrors = e.fieldErrors.map((k, v) =>
                                        MapEntry(k.replaceAll('\$.', ''), v));
                                  });
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

  Future<void> _updateClassroom(String id, String name) async {
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

  Future<void> _deleteClassroom(String id) async {
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
    Map<String, List<String>> fieldErrors = {};

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
                      _buildDialogTimePickerField(
                        context: context,
                        controller: timeInController,
                        label: 'Time In',
                        hint: 'e.g. 08:00:00',
                        icon: Icons.login,
                        errorText: fieldErrors['timeIn']?.first ??
                            fieldErrors['TimeIn']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTimePickerField(
                        context: context,
                        controller: timeOutController,
                        label: 'Time Out',
                        hint: 'e.g. 09:00:00',
                        icon: Icons.logout,
                        errorText: fieldErrors['timeOut']?.first ??
                            fieldErrors['TimeOut']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField<String>(
                        label: 'Day of Week',
                        hint: 'Select day',
                        icon: Icons.calendar_today,
                        value: dayOfWeekController.text.isEmpty
                            ? null
                            : dayOfWeekController.text,
                        items: const [
                          DropdownMenuItem(
                              value: 'Monday', child: Text('Monday')),
                          DropdownMenuItem(
                              value: 'Tuesday', child: Text('Tuesday')),
                          DropdownMenuItem(
                              value: 'Wednesday', child: Text('Wednesday')),
                          DropdownMenuItem(
                              value: 'Thursday', child: Text('Thursday')),
                          DropdownMenuItem(
                              value: 'Friday', child: Text('Friday')),
                          DropdownMenuItem(
                              value: 'Saturday', child: Text('Saturday')),
                          DropdownMenuItem(
                              value: 'Sunday', child: Text('Sunday')),
                        ],
                        onChanged: (val) {
                          if (val != null) dayOfWeekController.text = val;
                        },
                        errorText: fieldErrors['dayOfWeek']?.first ??
                            fieldErrors['DayOfWeek']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField<String>(
                        label: 'Subject',
                        hint: 'Select a subject',
                        icon: Icons.subject,
                        value: subjectIdController.text.isNotEmpty
                            ? subjectIdController.text
                            : null,
                        items: _subjectsList
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            subjectIdController.text = val;
                          }
                        },
                        errorText: fieldErrors['subjectId']?.first ??
                            fieldErrors['SubjectId']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField<String>(
                        label: 'Classroom',
                        hint: 'Select a classroom',
                        icon: Icons.meeting_room,
                        value: classroomIdController.text.isNotEmpty
                            ? classroomIdController.text
                            : null,
                        items: _classroomsList
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            classroomIdController.text = val;
                          }
                        },
                        errorText: fieldErrors['classroomId']?.first ??
                            fieldErrors['ClassroomId']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField<String>(
                        label: 'Section',
                        hint: 'Select a section',
                        icon: Icons.layers,
                        value: sectionIdController.text.isNotEmpty
                            ? sectionIdController.text
                            : null,
                        items: _sectionsList
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            sectionIdController.text = val;
                          }
                        },
                        errorText: fieldErrors['sectionId']?.first ??
                            fieldErrors['SectionId']?.first,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField<String>(
                        label: 'Instructor',
                        hint: 'Select an instructor',
                        icon: Icons.person,
                        value: instructorIdController.text.isNotEmpty
                            ? instructorIdController.text
                            : null,
                        items: _instructorsList
                            .map((i) => DropdownMenuItem(
                                  value: i.id,
                                  child: Text('${i.firstname} ${i.lastname}',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            instructorIdController.text = val;
                          }
                        },
                        errorText: fieldErrors['instructorId']?.first ??
                            fieldErrors['InstructorId']?.first,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final timeIn = timeInController.text.trim();
                                  final timeOut = timeOutController.text.trim();
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
                                            : dayOfWeekController.text.trim(),
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
                                        : int.tryParse(
                                            classroomIdController.text.trim()),
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
                                        : int.tryParse(
                                            instructorIdController.text.trim()),
                                  };

                                  setModalState(() {
                                    isSaving = true;
                                    fieldErrors = {};
                                  });
                                  try {
                                    if (isEditing) {
                                      await _apiService.updateSchedule(
                                          schedule.id, payload);
                                    } else {
                                      await _apiService.createSchedule(payload);
                                    }
                                    await _fetchSchedules();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } on ApiException catch (e) {
                                    setModalState(() {
                                      isSaving = false;
                                      fieldErrors = e.fieldErrors.map((k, v) =>
                                          MapEntry(k.replaceAll('\$.', ''), v));
                                    });
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error saving schedule: $e'),
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

  Future<void> _deleteSchedule(String id) async {
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
    return MainScaffold(
      title: 'Classes',
      currentIndex: 2,
      actions: [
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
      body: Column(
        children: [
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              child: _buildOverviewCard(
                  'Total Courses',
                  '${_coursesList.length}',
                  Icons.book,
                  const Color(0xFFA78BFA),
                  100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                  'Active Courses',
                  '${_coursesList.length}',
                  Icons.check_circle,
                  const Color(0xFF34D399),
                  100),
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
              child: _buildOverviewCard(
                  'Total Sections',
                  '${_sectionsList.length}',
                  Icons.layers,
                  const Color(0xFFFBBF24),
                  100),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildClassroomsList() {
    if (_isLoadingClassrooms) {
      return const SkeletonListView(itemCount: 4, padding: EdgeInsets.all(16));
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
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
      return const SkeletonListView(itemCount: 4, padding: EdgeInsets.all(16));
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
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
      return const SkeletonListView(itemCount: 4, padding: EdgeInsets.all(16));
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
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
      return const SkeletonListView(itemCount: 4, padding: EdgeInsets.all(16));
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
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
      return const SkeletonListView(itemCount: 4, padding: EdgeInsets.all(16));
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
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
