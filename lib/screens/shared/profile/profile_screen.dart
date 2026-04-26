import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/instructor_model.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../providers/app_provider.dart';
import '../../../utils/sizing_utils.dart';
import '../../../utils/constants.dart';
import '../../../widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<dynamic> _profileFuture;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _userRole = context.read<AppProvider>().userRole;
    final isTeacher = _userRole == 'instructor' || _userRole == 'teacher';
    _profileFuture = isTeacher ? _apiService.getInstructorProfile() : _apiService.getMe();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole == 'admin';
    final isStudent = _userRole == 'student';

    return MainScaffold(
      title: 'Profile',
      currentIndex: isStudent ? 2 : -1,
      showBackButton: true,
      isAdmin: isAdmin,
      isStudent: isStudent,
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
      _profileFuture = isTeacher ? _apiService.getInstructorProfile() : _apiService.getMe();
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
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: Sizing.sp(64)),
            SizedBox(height: Sizing.h(16)),
            Text(
              'Failed to load profile',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: Sizing.sp(18), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Sizing.h(8)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: Sizing.sp(14)),
            ),
            SizedBox(height: Sizing.h(24)),
            ElevatedButton(
              onPressed: _reloadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: Sizing.w(32), vertical: Sizing.h(12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizing.r(12))),
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
      padding: EdgeInsets.symmetric(horizontal: Sizing.w(24), vertical: Sizing.h(12)),
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
              backgroundImage: NetworkImage(
                profile is Instructor 
                  ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.fullName)}&background=38BDF8&color=0F172A&size=150' 
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent((profile as UserProfile).username)}&background=34D399&color=0F172A&size=150'
              ),
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
            padding: EdgeInsets.symmetric(horizontal: Sizing.w(12), vertical: Sizing.h(4)),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Sizing.r(20)),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
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
            _buildDetailTile(Icons.perm_identity_rounded, 'Instructor ID', profile.id.toString()),
            _buildDivider(),
            _buildDetailTile(Icons.person_outline_rounded, 'First Name', profile.firstname),
            _buildDivider(),
            _buildDetailTile(Icons.person_outline_rounded, 'Last Name', profile.lastname),
            _buildDivider(),
            _buildDetailTile(Icons.calendar_month_outlined, 'Member Since', dateFormat.format(profile.createdAt)),
            _buildDivider(),
            _buildDetailTile(Icons.update_rounded, 'Last Updated', dateFormat.format(profile.updatedAt)),
          ] else if (profile is UserProfile) ...[
            _buildDetailTile(Icons.perm_identity_rounded, 'User ID', profile.userId),
            _buildDivider(),
            _buildDetailTile(Icons.email_outlined, 'Email Address', profile.email),
            _buildDivider(),
            _buildDetailTile(Icons.calendar_month_outlined, 'Member Since', dateFormat.format(profile.createdAt)),
            _buildDivider(),
            _buildDetailTile(Icons.update_rounded, 'Last Updated', dateFormat.format(profile.updatedAt)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sizing.w(20), vertical: Sizing.h(16)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(10)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Sizing.r(12)),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: Sizing.sp(20)),
          ),
          SizedBox(width: Sizing.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: Sizing.sp(13)),
                ),
                SizedBox(height: Sizing.h(2)),
                Text(
                  value,
                  style: TextStyle(color: Colors.white, fontSize: Sizing.sp(15), fontWeight: FontWeight.w500),
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
