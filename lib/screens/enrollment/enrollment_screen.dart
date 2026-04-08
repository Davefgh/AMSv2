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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
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
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'aclc_logo.png',
                height: isMobile ? 32 : 40,
                width: isMobile ? 32 : 40,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isMobile ? 32 : 40,
                    width: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: Colors.white),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Enrollment',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: _showAddEnrollmentDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search class code...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: Icon(Icons.filter_list, color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            color: Colors.white.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = _enrollments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
            ),
            title: Text(
              enrollment['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(enrollment['classCode'] ?? ''),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  child: Text('Delete'),
                ),
              ],
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

    final students = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Williams'];
    final sections = ['CS31A', 'CS31B', 'CS32A', 'CS32B'];
    final subjects = ['Computer Science', 'Mathematics', 'Physics', 'Chemistry'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF3B82F6),
                Color(0xFF60A5FA),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                // Student Dropdown
                const Text(
                  'Student *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A), size: 28),
                    ),
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Select a student'),
                    ),
                    value: selectedStudent,
                    items: students.map((student) {
                      return DropdownMenuItem(
                        value: student,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(student),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStudent = value;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Section Dropdown
                const Text(
                  'Section *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A), size: 28),
                    ),
                    value: selectedSection,
                    items: sections.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(section),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSection = value;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Subject Dropdown
                const Text(
                  'Subject *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A), size: 28),
                    ),
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Select a subject'),
                    ),
                    value: selectedSubject,
                    items: subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(subject),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSubject = value;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enroll',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E3A8A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Enrollment'),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/enrollment');
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
