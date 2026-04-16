import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/schedule_model.dart';
import '../../models/user_profile.dart';
import '../../models/instructor_model.dart';
import '../../widgets/main_scaffold.dart';

class TeacherSectionsScreen extends StatefulWidget {
  const TeacherSectionsScreen({super.key});

  @override
  State<TeacherSectionsScreen> createState() => _TeacherSectionsScreenState();
}

class _TeacherSectionsScreenState extends State<TeacherSectionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _sections = [];

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
      // 1. Get profile
      final profile = await _apiService.getMe();
      
      // 2. Get instructor
      final instructors = await _apiService.getInstructors();
      final instructor = instructors.firstWhere(
        (i) => i.userId == profile.userId,
        orElse: () => throw Exception('Instructor profile not found.'),
      );

      // 3. Get schedules
      final schedules = await _apiService.getSchedulesByInstructorAll(instructor.id);

      // 4. Extract unique sections
      final Map<int, Map<String, dynamic>> sectionMap = {};
      for (var s in schedules) {
        final section = s.section;
        final sectionId = (section?['id'] as num?)?.toInt() ?? s.sectionId;
        
        if (sectionId != null && !sectionMap.containsKey(sectionId)) {
          sectionMap[sectionId] = section ?? {
            'id': sectionId, 
            'name': s.sectionName.isNotEmpty ? s.sectionName : 'Section $sectionId'
          };
        }
      }

      if (mounted) {
        setState(() {
          _sections = sectionMap.values.toList();
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sections',
      currentIndex: 3,
      isAdmin: false,
      body: Stack(
        children: [
          _buildBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              'No sections found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no assigned class sections.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          return _buildSectionItem(section);
        },
      ),
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> section) {
    final name = (section['name'] as String?)?.trim() ?? 'Unknown Section';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFF38BDF8), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assigned Class Section',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
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
