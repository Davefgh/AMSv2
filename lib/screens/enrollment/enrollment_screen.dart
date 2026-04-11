import 'dart:ui';
import 'package:flutter/material.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({Key? key}) : super(key: key);

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  int _selectedIndex = 1;
  String _searchQuery = '';
  final List<Map<String, String>> _enrollments = [];

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
                color: const Color(0xFF38BDF8).withOpacity(0.3), // Sky Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.3),
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
                color: const Color(0xFF1E3A8A).withOpacity(0.5), // Navy Blue
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.5),
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
                _buildSearchBar(),
                Expanded(
                  child: _enrollments.isEmpty
                      ? _buildEmptyState()
                      : _buildEnrollmentList(),
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
                'aclc_logo.png',
                height: 48,
                width: 48,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              const Text(
                'Enrollment',
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
              color: const Color(0xFF38BDF8).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
              onPressed: _showAddEnrollmentDialog,
            ),
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
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
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
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon:
                Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon:
                Icon(Icons.filter_list, color: Colors.white.withOpacity(0.5)),
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
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No enrollments found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to enroll a student',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentList() {
    return ListView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(24),
      itemCount: _enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = _enrollments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.3),
                  ),
                ),
                child: const Icon(Icons.person, color: Color(0xFF38BDF8)),
              ),
              title: Text(
                enrollment['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${enrollment['classCode']} • ${enrollment['subject']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: PopupMenuButton(
                color: const Color(0xFF1E293B), // Dark slate
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                icon:
                    Icon(Icons.more_vert, color: Colors.white.withOpacity(0.6)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    child: Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    child: Text('Delete',
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
    String? selectedStudent;
    String? selectedSection = 'CS31A';
    String? selectedSubject;

    final students = [
      'John Doe',
      'Jane Smith',
      'Mike Johnson',
      'Sarah Williams'
    ];
    final sections = ['CS31A', 'CS31B', 'CS32A', 'CS32B'];
    final subjects = [
      'Computer Science',
      'Mathematics',
      'Physics',
      'Chemistry'
    ];

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
                    _buildDialogDropdown(
                      label: 'Student *',
                      hint: 'Select a student',
                      value: selectedStudent,
                      items: students,
                      onChanged: (value) =>
                          setStateDialog(() => selectedStudent = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown(
                      label: 'Section *',
                      hint: 'Select a section',
                      value: selectedSection,
                      items: sections,
                      onChanged: (value) =>
                          setStateDialog(() => selectedSection = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogDropdown(
                      label: 'Subject *',
                      hint: 'Select a subject',
                      value: selectedSubject,
                      items: subjects,
                      onChanged: (value) =>
                          setStateDialog(() => selectedSubject = value),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedStudent != null &&
                                  selectedSection != null &&
                                  selectedSubject != null) {
                                setState(() {
                                  _enrollments.add({
                                    'name': selectedStudent!,
                                    'classCode': selectedSection!,
                                    'subject': selectedSubject!,
                                  });
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF38BDF8), // Sky Blue
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Enroll',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildDialogDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B), // Dark slate
              icon: Icon(Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.6), size: 28),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  hint,
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
              value: value,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        Text(item, style: const TextStyle(color: Colors.white)),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
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
            color: Colors.white.withOpacity(0.1),
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
        unselectedItemColor: Colors.white.withOpacity(0.4),
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
            // Already on enrollment
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/classes');
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
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
