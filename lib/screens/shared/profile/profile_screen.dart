import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/instructor_model.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../providers/app_provider.dart';

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
      currentIndex: -1,
      showBackButton: true,
      isAdmin: isAdmin,
      isStudent: isStudent,
      body: FutureBuilder<dynamic>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            );
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


  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reloadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        _buildUserCard(profile),
        const SizedBox(height: 24),
        _buildDetailSection(profile),
        const SizedBox(height: 8),
      ],
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: NetworkImage(
                profile is Instructor 
                  ? 'https://i.pravatar.cc/150?u=${profile.id}' 
                  : 'https://i.pravatar.cc/150?u=${(profile as UserProfile).userId}'
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Text(
              roleName,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
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
