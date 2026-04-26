import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/main_scaffold.dart';
import '../../providers/app_provider.dart';
import '../../utils/sizing_utils.dart';
import 'section_students_screen.dart';
import '../../widgets/skeleton_loader.dart';

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
  String _searchQuery = '';

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
      if (profile.instructorProfile == null) {
        throw Exception('Instructor profile not found.');
      }

      // 2. Get schedules
      final schedules = await _apiService.getMySchedules();

      // 4. Extract unique sections
      final Map<String, Map<String, dynamic>> sectionMap = {};
      for (var s in schedules) {
        final section = s.section;
        final sectionId = section?['id']?.toString() ?? s.sectionId;

        if (sectionId != null &&
            sectionId.isNotEmpty &&
            !sectionMap.containsKey(sectionId)) {
          sectionMap[sectionId] = section ??
              {
                'id': sectionId,
                'name': s.sectionName.isNotEmpty
                    ? s.sectionName
                    : 'Section $sectionId'
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

  List<Map<String, dynamic>> get _filteredSections {
    if (_searchQuery.isEmpty) {
      return _sections;
    }
    return _sections
        .where((section) =>
            (section['name'] as String?)
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sections',
      currentIndex: 4,
      isAdmin: false,
      body: _isLoading
          ? const SkeletonListView()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final isDark = appProvider.isDarkMode;
        final cardColor =
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final secondaryTextColor = isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.6);

        if (_sections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_clear_rounded,
                    size: 64, color: secondaryTextColor),
                SizedBox(height: Sizing.h(16)),
                Text(
                  'No sections found',
                  style: TextStyle(
                      color: textColor,
                      fontSize: Sizing.sp(18),
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: Sizing.h(8)),
                Text(
                  'You have no assigned class sections.',
                  style: TextStyle(
                      color: secondaryTextColor, fontSize: Sizing.sp(14)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF38BDF8),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.all(Sizing.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Stats
                _buildSummary(isDark, textColor, secondaryTextColor),
                SizedBox(height: Sizing.h(24)),

                // Search Bar
                _buildSearchBar(isDark, textColor, secondaryTextColor),
                SizedBox(height: Sizing.h(24)),

                // Sections List
                if (_filteredSections.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: Sizing.h(40)),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: secondaryTextColor),
                          SizedBox(height: Sizing.h(12)),
                          Text(
                            'No sections found',
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: Sizing.sp(14)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _filteredSections.map((section) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: Sizing.h(16)),
                        child: _buildSectionItem(section, isDark, cardColor,
                            textColor, secondaryTextColor),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(bool isDark, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(16)),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(Sizing.r(16)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.layers_rounded,
            label: 'Total Sections',
            value: '${_sections.length}',
            color: const Color(0xFF38BDF8),
            isDark: isDark,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Sizing.w(12)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: Sizing.sp(24)),
        ),
        SizedBox(height: Sizing.h(8)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: Sizing.sp(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Sizing.h(4)),
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: Sizing.sp(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(
      bool isDark, Color textColor, Color secondaryTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(Sizing.r(12)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: textColor, fontSize: Sizing.sp(14)),
        decoration: InputDecoration(
          hintText: 'Search sections...',
          hintStyle:
              TextStyle(color: secondaryTextColor, fontSize: Sizing.sp(14)),
          prefixIcon: Icon(Icons.search_rounded,
              color: secondaryTextColor, size: Sizing.sp(20)),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Icon(Icons.close_rounded,
                      color: secondaryTextColor, size: Sizing.sp(20)),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: Sizing.w(16), vertical: Sizing.h(12)),
        ),
      ),
    );
  }

  Widget _buildSectionItem(
    Map<String, dynamic> section,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final name = (section['name'] as String?)?.trim() ?? 'Unknown Section';

    return GestureDetector(
      onTap: () {
        final id = section['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SectionStudentsScreen(
                sectionId: id,
                sectionName: name,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(Sizing.w(16)),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(Sizing.r(16)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Sizing.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Sizing.r(12)),
                border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.people_alt_rounded,
                  color: const Color(0xFF38BDF8), size: Sizing.sp(24)),
            ),
            SizedBox(width: Sizing.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: Sizing.sp(16),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Sizing.h(4)),
                  Text(
                    'Tap to view students',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: Sizing.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: secondaryTextColor, size: Sizing.sp(16)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Sizing.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            SizedBox(height: Sizing.h(16)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            SizedBox(height: Sizing.h(24)),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
