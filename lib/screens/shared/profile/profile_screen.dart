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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FutureBuilder<dynamic>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonProfile();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return _buildErrorState('No profile data found');
          }

          final profileData = snapshot.data!;
          return _buildProfileContent(profileData);
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reloadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(dynamic profile) {
    String username;
    String fullName;
    String email;
    String roleName;
    DateTime createdAt;

    if (profile is Instructor) {
      username = profile.fullName;
      fullName = profile.fullName;
      email = '';
      roleName = 'Instructor';
      createdAt = profile.createdAt;
    } else if (profile is UserProfile) {
      username = profile.username;
      fullName = profile.fullName;
      email = profile.email;
      roleName = profile.role.toUpperCase();
      createdAt = profile.createdAt;
    } else {
      username = 'Unknown User';
      fullName = 'Unknown User';
      email = '';
      roleName = 'N/A';
      createdAt = DateTime.now();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Header with Avatar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF38BDF8).withValues(alpha: 0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
          child: Column(
            children: [
              // Avatar
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
                  backgroundColor: const Color(0xFF0F172A),
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName.isNotEmpty ? fullName : username)}&background=38BDF8&color=0F172A&size=150',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name
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
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
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
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Information Card
              _buildInfoCard(profile, username, email, createdAt),
              const SizedBox(height: 16),
              
              // Actions
              _buildActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                color: const Color(0xFF38BDF8),
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/edit-profile',
                  );
                  if (result == true) {
                    _reloadProfile();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                color: Colors.redAccent,
                onTap: _logout,
              ),
              const SizedBox(height: 80), // Extra padding for bottom nav
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    dynamic profile,
    String username,
    String email,
    DateTime createdAt,
  ) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          if (profile is UserProfile) ...[
            _buildInfoTile(
              icon: Icons.person_outline,
              label: 'Username',
              value: username,
            ),
            if (email.isNotEmpty) ...[
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
            ],
            if (profile.studentProfile != null) ...[
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.school_outlined,
                label: 'Section',
                value: profile.studentProfile!.sectionName,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.book_outlined,
                label: 'Course',
                value: profile.studentProfile!.courseName,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.verified_user_outlined,
                label: 'Type',
                value: profile.studentProfile!.isRegular ? 'Regular' : 'Irregular',
              ),
            ],
          ],
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: dateFormat.format(createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF38BDF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}
