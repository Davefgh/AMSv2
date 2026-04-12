import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/api_service.dart';
import '../../models/instructor_model.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({super.key});

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  final ApiService _apiService = ApiService();
  List<Instructor> _allInstructors = [];
  List<Instructor> _filteredInstructors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showDeleted = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchInstructors();
  }

  Future<void> _fetchInstructors() async {
    try {
      final instructors = await _apiService.getInstructors(includeDeleted: _showDeleted);
      if (mounted) {
        setState(() {
          _allInstructors = instructors;
          _filteredInstructors = instructors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load instructors: $e');
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _fetchInstructors();
        return;
      }

      setState(() {
        _searchQuery = query;
        _isLoading = true;
      });

      try {
        final results = await _apiService.searchInstructorsByName(query);
        if (mounted) {
          setState(() {
            _filteredInstructors = _showDeleted ? results : results.where((i) => !i.isDeleted).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _filteredInstructors = [];
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

  Future<void> _handleEdit(Instructor instructor) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InstructorEditModal(instructor: instructor),
    );

    if (result == true) {
      _fetchInstructors();
      _showSnackBar('Instructor updated successfully');
    }
  }

  Future<void> _handleSoftDelete(Instructor instructor) async {
    final confirm = await _showConfirmDialog(
      'Move to Trash?',
      'Are you sure you want to move ${instructor.fullName} to the trash?',
      'Move to Trash',
      Colors.orangeAccent,
    );

    if (confirm == true) {
      try {
        await _apiService.softDeleteInstructor(instructor.id);
        _fetchInstructors();
        _showSnackBar('${instructor.firstname} moved to trash');
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<void> _handleRestore(Instructor instructor) async {
    try {
      await _apiService.restoreInstructor(instructor.id);
      _fetchInstructors();
      _showSnackBar('${instructor.firstname} restored successfully');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _handlePermanentDelete(Instructor instructor) async {
    final confirm = await _showConfirmDialog(
      'Permanent Delete?',
      'This will permanently delete ${instructor.fullName}. This action cannot be undone.',
      'Delete Permanently',
      Colors.redAccent,
    );

    if (confirm == true) {
      try {
        await _apiService.deleteInstructor(instructor.id);
        _fetchInstructors();
        _showSnackBar('${instructor.firstname} deleted permanently');
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message, String action, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
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
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)))
                      : _filteredInstructors.isEmpty
                          ? _buildEmptyState()
                          : _buildInstructorList(),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instructors',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Directory',
                style: TextStyle(fontSize: 14, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
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
              _fetchInstructors();
            },
            icon: Icon(
              _showDeleted ? Icons.delete_sweep_rounded : Icons.delete_outline_rounded,
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
            hintText: 'Search instructors...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _filteredInstructors.length,
      itemBuilder: (context, index) {
        return _buildSlidableCard(_filteredInstructors[index]);
      },
    );
  }

  Widget _buildSlidableCard(Instructor instructor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(instructor.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            if (!instructor.isDeleted) ...[
              SlidableAction(
                onPressed: (_) => _handleEdit(instructor),
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
                icon: Icons.edit_rounded,
                label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              SlidableAction(
                onPressed: (_) => _handleSoftDelete(instructor),
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Trash',
              ),
            ] else ...[
              SlidableAction(
                onPressed: (_) => _handleRestore(instructor),
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
                onPressed: (_) => _handlePermanentDelete(instructor),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete_forever_rounded,
                label: 'Delete',
              ),
            ],
          ],
        ),
        child: _buildInstructorCard(instructor),
      ),
    );
  }

  Widget _buildInstructorCard(Instructor instructor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: instructor.isDeleted 
          ? Colors.orangeAccent.withValues(alpha: 0.05) 
          : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: instructor.isDeleted
            ? Colors.orangeAccent.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.08)
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.person_pin_rounded, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instructor ID: ${instructor.id}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No instructors found' : 'No results for "$_searchQuery"',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _InstructorEditModal extends StatefulWidget {
  final Instructor instructor;
  const _InstructorEditModal({required this.instructor});

  @override
  State<_InstructorEditModal> createState() => _InstructorEditModalState();
}

class _InstructorEditModalState extends State<_InstructorEditModal> {
  final ApiService _apiService = ApiService();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.instructor.firstname);
    _lastNameController = TextEditingController(text: widget.instructor.lastname);
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
      await _apiService.updateInstructor(widget.instructor.id, {
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            'Edit Instructor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildTextField('First Name', _firstNameController),
          const SizedBox(height: 16),
          _buildTextField('Last Name', _lastNameController),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
