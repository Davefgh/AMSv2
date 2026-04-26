import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/student_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:async';
import '../../../widgets/skeleton_loader.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ApiService _apiService = ApiService();
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showDeleted = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students =
          await _apiService.getStudents(includeDeleted: _showDeleted);
      if (mounted) {
        setState(() {
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load students: $e');
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _fetchStudents();
        return;
      }

      setState(() {
        _searchQuery = query;
        _isLoading = true;
      });

      try {
        final results = await _apiService.searchStudentsByName(query);
        if (mounted) {
          setState(() {
            _filteredStudents = _showDeleted
                ? results
                : results.where((s) => !s.isDeleted).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _filteredStudents = [];
          });
        }
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleEdit(Student student) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentEditModal(student: student),
    );

    if (result == true) {
      _fetchStudents();
      _showSnackBar('Student updated successfully');
    }
  }

  Future<void> _handleSoftDelete(Student student) async {
    final confirm = await _showConfirmDialog(
      'Move to Trash?',
      'Are you sure you want to move ${student.fullName} to the trash?',
      'Move to Trash',
      Colors.orangeAccent,
    );

    if (confirm == true) {
      try {
        await _apiService.softDeleteStudent(student.id);
        _fetchStudents();
        _showSnackBar('${student.firstname} moved to trash');
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<void> _handleRestore(Student student) async {
    try {
      await _apiService.restoreStudent(student.id);
      _fetchStudents();
      _showSnackBar('${student.firstname} restored successfully');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _handlePermanentDelete(Student student) async {
    final confirm = await _showConfirmDialog(
      'Permanent Delete?',
      'This will permanently delete ${student.fullName}. This action cannot be undone.',
      'Delete Permanently',
      Colors.redAccent,
    );

    if (confirm == true) {
      try {
        await _apiService.deleteStudent(student.id);
        _fetchStudents();
        _showSnackBar('${student.firstname} deleted permanently');
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<bool?> _showConfirmDialog(
      String title, String message, String action, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              ),
            ),
          ),
          IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const SkeletonListView()
                      : _filteredStudents.isEmpty
                          ? _buildEmptyState()
                          : _buildStudentList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Students',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Directory',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _showDeleted = !_showDeleted;
                _isLoading = true;
              });
              _fetchStudents();
            },
            icon: Icon(
              _showDeleted
                  ? Icons.delete_sweep_rounded
                  : Icons.delete_outline_rounded,
              color: _showDeleted ? const Color(0xFFFACC15) : Colors.white60,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _showDeleted
                  ? const Color(0xFFFACC15).withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            tooltip: _showDeleted ? 'Showing All' : 'Show Trash',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search students...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.4)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildSlidableCard(student);
      },
    );
  }

  Widget _buildSlidableCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(student.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            if (!student.isDeleted) ...[
              SlidableAction(
                onPressed: (_) => _handleEdit(student),
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                icon: Icons.edit_rounded,
                label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              SlidableAction(
                onPressed: (_) => _handleSoftDelete(student),
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Trash',
              ),
            ] else ...[
              SlidableAction(
                onPressed: (_) => _handleRestore(student),
                backgroundColor: const Color(0xFF34D399),
                foregroundColor: Colors.white,
                icon: Icons.restore_rounded,
                label: 'Restore',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              SlidableAction(
                onPressed: (_) => _handlePermanentDelete(student),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete_forever_rounded,
                label: 'Delete',
              ),
            ],
          ],
        ),
        child: _buildStudentCard(student),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      decoration: BoxDecoration(
        color: student.isDeleted
            ? Colors.orangeAccent.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: student.isDeleted
                ? Colors.orangeAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF34D399)),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Section ${student.sectionId}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    student.isRegular ? 'Regular' : 'Irregular',
                    style: TextStyle(
                      color: student.isRegular
                          ? const Color(0xFF34D399)
                          : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 16),
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
          Icon(Icons.person_search_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No students found'
                : 'No results for "$_searchQuery"',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StudentEditModal extends StatefulWidget {
  final Student student;
  const _StudentEditModal({required this.student});

  @override
  State<_StudentEditModal> createState() => _StudentEditModalState();
}

class _StudentEditModalState extends State<_StudentEditModal> {
  final ApiService _apiService = ApiService();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late bool _isRegular;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.student.firstname);
    _lastNameController = TextEditingController(text: widget.student.lastname);
    _isRegular = widget.student.isRegular;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateStudent(widget.student.id, {
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
        'isRegular': _isRegular,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 32,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Student',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildTextField('First Name', _firstNameController),
          const SizedBox(height: 16),
          _buildTextField('Last Name', _lastNameController),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Regular Student',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Switch(
                value: _isRegular,
                onChanged: (v) => setState(() => _isRegular = v),
                activeThumbColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
