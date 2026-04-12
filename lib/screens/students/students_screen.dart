import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ApiService _apiService = ApiService();
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await _apiService.getStudents();
      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents = _allStudents
          .where((s) => s.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
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
                'Students',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Directory',
                style: TextStyle(fontSize: 14, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
              ),
            ],
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
          onChanged: _filterStudents,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search students...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF34D399)),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Section ${student.sectionId}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    student.isRegular ? 'Regular' : 'Irregular',
                    style: TextStyle(
                      color: student.isRegular ? const Color(0xFF34D399) : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.2), size: 16),
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
          Icon(Icons.person_search_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No students found' : 'No results for "$_searchQuery"',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
