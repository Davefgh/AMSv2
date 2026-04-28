import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/instructor_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/notification_hub_service.dart';
import '../../../utils/constants.dart';
import '../../../config/routes/app_routes.dart';
import '../../../widgets/skeleton_loader.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<dynamic> _profileFuture;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _userRole = ref.read(appProvider).userRole;
    final isTeacher = _userRole == 'instructor' || _userRole == 'teacher';
    _profileFuture =
        isTeacher ? _apiService.getInstructorProfile() : _apiService.getMe();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(appProvider).isDarkMode;
    final bgColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<dynamic>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonProfile();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), isDark);
          } else if (!snapshot.hasData) {
            return _buildErrorState('No profile data found', isDark);
          }

          return _buildProfileContent(snapshot.data!, isDark);
        },
      ),
    );
  }

  void _reloadProfile() {
    final isTeacher = _userRole == 'instructor' || _userRole == 'teacher';
    setState(() {
      _profileFuture =
          isTeacher ? _apiService.getInstructorProfile() : _apiService.getMe();
    });
  }

  Future<void> _logout(bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF001F3F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : const Color(0xFF001F3F).withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF001F3F).withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await NotificationHubService().stop();
    ref.read(notificationProvider.notifier).clearNotifications();
    await StorageService.remove(AppConstants.storageKeyToken);
    await StorageService.remove(AppConstants.storageKeyRefreshToken);
    await StorageService.remove(AppConstants.storageKeyUser);
    await StorageService.remove(AppConstants.storageKeyRole);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildErrorState(String error, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF001F3F);
    final bodyColor = isDark
        ? Colors.white60
        : const Color(0xFF001F3F).withOpacity(0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: bodyColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reloadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(dynamic profile, bool isDark) {
    String username;
    String fullName;
    String email;
    String roleName;
    DateTime createdAt;
    bool isTeacher = false;

    if (profile is Instructor) {
      username = profile.fullName;
      fullName = profile.fullName;
      email = '';
      roleName = 'Instructor';
      createdAt = profile.createdAt;
      isTeacher = true;
    } else if (profile is UserProfile) {
      username = profile.username;
      fullName = profile.fullName;
      email = profile.email;
      roleName = profile.role.toUpperCase();
      createdAt = profile.createdAt;
      isTeacher = profile.role.toLowerCase() == 'instructor' ||
          profile.role.toLowerCase() == 'teacher';
    } else {
      username = 'Unknown User';
      fullName = 'Unknown User';
      email = '';
      roleName = 'N/A';
      createdAt = DateTime.now();
      isTeacher = false;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // ── Header ──────────────────────────────────────────────
        _buildHeader(fullName, username, roleName, isDark),

        // ── Body ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(profile, username, email, createdAt, isDark),
              const SizedBox(height: 16),
              if (isTeacher) ...[
                _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Reports & Analytics',
                  color: isDark ? Colors.white : const Color(0xFF001F3F),
                  isDark: isDark,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.teacherReports),
                ),
                const SizedBox(height: 12),
              ],
              _buildActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                color: const Color(0xFF38BDF8),
                isDark: isDark,
                onTap: () async {
                  final result =
                      await Navigator.pushNamed(context, '/edit-profile');
                  if (result == true) _reloadProfile();
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                color: Colors.redAccent,
                isDark: isDark,
                onTap: () => _logout(isDark),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      String fullName, String username, String roleName, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF38BDF8).withOpacity(0.2),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF001F3F),
                  Color(0xFF0D47A1),
                ],
              ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          // Avatar ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF38BDF8),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFF001F3F),
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName.isNotEmpty ? fullName : username)}&background=38BDF8&color=0F172A&size=150',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name — always white on the gradient header
          Text(
            fullName.isNotEmpty ? fullName : username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(0.6)),
            ),
            child: Text(
              roleName,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    dynamic profile,
    String username,
    String email,
    DateTime createdAt,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF001F3F).withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF001F3F).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        children: [
          if (profile is UserProfile) ...[
            _buildInfoTile(
                icon: Icons.person_outline,
                label: 'Username',
                value: username,
                isDark: isDark),
            if (email.isNotEmpty) ...[
              _buildDivider(isDark),
              _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  isDark: isDark),
            ],
            if (profile.studentProfile != null) ...[
              _buildDivider(isDark),
              _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Section',
                  value: profile.studentProfile!.sectionName,
                  isDark: isDark),
              _buildDivider(isDark),
              _buildInfoTile(
                  icon: Icons.book_outlined,
                  label: 'Course',
                  value: profile.studentProfile!.courseName,
                  isDark: isDark),
              _buildDivider(isDark),
              _buildInfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Type',
                  value: profile.studentProfile!.isRegular
                      ? 'Regular'
                      : 'Irregular',
                  isDark: isDark),
            ],
          ],
          _buildDivider(isDark),
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: DateFormat('MMMM dd, yyyy').format(createdAt),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final labelColor = isDark
        ? Colors.white.withOpacity(0.6)
        : const Color(0xFF001F3F).withOpacity(0.5);
    final valueColor = isDark ? Colors.white : const Color(0xFF001F3F);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: labelColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF001F3F).withOpacity(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF001F3F).withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : const Color(0xFF001F3F).withOpacity(0.06),
    );
  }
}
