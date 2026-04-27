import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/instructor_model.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../providers/app_provider.dart';
import '../../../utils/sizing_utils.dart';
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
    final isStudent = _userRole == 'student';

    // For students, this is part of the NavigationShell (no scaffold needed)
    // For teachers, this is a standalone screen (needs MainScaffold)
    final content = FutureBuilder<dynamic>(
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
    );

    // Students see this as a tab (no scaffold wrapper)
    if (isStudent) {
      return content;
    }

    // Teachers see this as a standalone screen (with scaffold)
    return MainScaffold(
      title: 'Profile',
      currentIndex: -1,
      showBackButton: true,
      isStudent: false,
      body: content,
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to log out of your account?',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        const Text('Log Out', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await StorageService.remove(AppConstants.storageKeyToken);
    await StorageService.remove(AppConstants.storageKeyRole);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Sizing.w(24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: Sizing.sp(64)),
            SizedBox(height: Sizing.h(16)),
            Text(
              'Failed to load profile',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: Sizing.sp(18),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Sizing.h(8)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: Sizing.sp(14)),
            ),
            SizedBox(height: Sizing.h(24)),
            ElevatedButton(
              onPressed: _reloadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.w(32), vertical: Sizing.h(12)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizing.r(12))),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(dynamic profile) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(24), vertical: Sizing.h(12)),
      children: [
        _buildUserCard(profile),
        SizedBox(height: Sizing.h(24)),
        _buildDetailSection(profile),
        SizedBox(height: Sizing.h(24)),
        _buildLogoutButton(),
        SizedBox(height: Sizing.h(16)),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(Sizing.r(24)),
          splashColor: Colors.redAccent.withValues(alpha: 0.1),
          highlightColor: Colors.redAccent.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Sizing.w(20),
              vertical: Sizing.h(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Sizing.w(10)),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Sizing.r(12)),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: Sizing.sp(20),
                  ),
                ),
                SizedBox(width: Sizing.w(16)),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: Sizing.sp(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  size: Sizing.sp(20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic profile) {
    String username;
    String roleName;

    if (profile is Instructor) {
      username = profile.fullName;
      roleName = 'Instructor';
    } else if (profile is UserProfile) {
      username = profile.username;
      roleName = profile.role.toUpperCase();
    } else {
      username = 'Unknown User';
      roleName = 'N/A';
    }

    return _GlassCard(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(4)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            ),
            child: CircleAvatar(
              radius: Sizing.r(50),
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: NetworkImage(profile is Instructor
                  ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.fullName)}&background=38BDF8&color=0F172A&size=150'
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent((profile as UserProfile).username)}&background=34D399&color=0F172A&size=150'),
            ),
          ),
          SizedBox(height: Sizing.h(16)),
          Text(
            username,
            style: TextStyle(
              fontSize: Sizing.sp(24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Sizing.h(4)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: Sizing.w(12), vertical: Sizing.h(4)),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Sizing.r(20)),
              border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Text(
              roleName,
              style: TextStyle(
                color: const Color(0xFF38BDF8),
                fontSize: Sizing.sp(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(dynamic profile) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (profile is Instructor) ...[
            _buildDetailTile(Icons.person_outline_rounded, 'Name',
                '${profile.firstname} ${profile.lastname}'),
            _buildDivider(),
            _buildDetailTile(Icons.calendar_month_outlined, 'Member Since',
                dateFormat.format(profile.createdAt)),
          ] else if (profile is UserProfile) ...[
            _buildDetailTile(
                Icons.email_outlined, 'Email Address', profile.email),
            _buildDivider(),
            _buildDetailTile(Icons.calendar_month_outlined, 'Member Since',
                dateFormat.format(profile.createdAt)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(20), vertical: Sizing.h(16)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(10)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Sizing.r(12)),
            ),
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.7),
                size: Sizing.sp(20)),
          ),
          SizedBox(width: Sizing.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: Sizing.sp(13)),
                ),
                SizedBox(height: Sizing.h(2)),
                Text(
                  value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: Sizing.sp(15),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.05));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizing.r(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Sizing.r(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
