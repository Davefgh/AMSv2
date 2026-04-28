import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/skeleton_loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _sectionIdController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegular = true;
  bool _isLoading = false;
  bool _isFetching = true;
  bool _isStudent = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _sectionIdController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getMe();
      setState(() {
        _emailController.text = profile.email;
        
        // Load student profile data if available
        if (profile.studentProfile != null) {
          _isStudent = true;
          _firstNameController.text = profile.studentProfile!.firstname ?? '';
          _lastNameController.text = profile.studentProfile!.lastname ?? '';
          _sectionIdController.text = profile.studentProfile!.sectionId;
          _isRegular = profile.studentProfile!.isRegular;
        }
        // Load instructor profile data if available
        else if (profile.instructorProfile != null) {
          _isStudent = false;
          _firstNameController.text = profile.instructorProfile!.firstname ?? '';
          _lastNameController.text = profile.instructorProfile!.lastname ?? '';
        }
        
        _isFetching = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updateData = {};

      // Add basic fields only if they have values
      if (_firstNameController.text.trim().isNotEmpty) {
        updateData['firstname'] = _firstNameController.text.trim();
      }
      if (_lastNameController.text.trim().isNotEmpty) {
        updateData['lastname'] = _lastNameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }
      if (_sectionIdController.text.trim().isNotEmpty) {
        updateData['sectionId'] = _sectionIdController.text.trim();
      }
      
      // isRegular is a student-only field
      if (_isStudent) {
        updateData['isRegular'] = _isRegular;
      }

      // Add passwords only if current password is provided
      if (_currentPasswordController.text.isNotEmpty) {
        updateData['currentPassword'] = _currentPasswordController.text;
        
        if (_newPasswordController.text.isNotEmpty) {
          updateData['newPassword'] = _newPasswordController.text;
          updateData['confirmNewPassword'] = _confirmPasswordController.text;
        }
      }

      await _apiService.updateProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update profile: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Ambiance Orbs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              ),
            ),
          ),
          IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isFetching
                      ? const SkeletonProfile()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Personal Information'),
                                const SizedBox(height: 20),
                                _buildPersonalFields(),
                                const SizedBox(height: 32),
                                _buildSectionTitle('Security Settings'),
                                const SizedBox(height: 20),
                                _buildSecurityFields(),
                                const SizedBox(height: 48),
                                _buildSubmitButton(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
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
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 20),
          const Text(
            'Edit Profile',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.1),
    );
  }

  Widget _buildPersonalFields() {
    return _GlassCard(
      child: Column(
        children: [
          CustomTextField(
            label: 'First Name',
            controller: _firstNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'First name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Last Name',
            controller: _lastNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email is required';
              }
              if (!v.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          // Student-specific fields
          if (_isStudent) ...[
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Section ID',
              controller: _sectionIdController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Section ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Regular Student',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Switch.adaptive(
                  value: _isRegular,
                  onChanged: (v) => setState(() => _isRegular = v),
                  activeTrackColor: const Color(0xFF38BDF8),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityFields() {
    return _GlassCard(
      child: Column(
        children: [
          const Text(
            'Leave password fields empty if you don\'t want to change your password',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Current Password',
            controller: _currentPasswordController,
            obscureText: true,
            validator: (v) {
              // If new password is provided, current password is required
              if (_newPasswordController.text.isNotEmpty && 
                  (v == null || v.isEmpty)) {
                return 'Current password is required to set a new password';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'New Password',
            controller: _newPasswordController,
            obscureText: true,
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            obscureText: true,
            validator: (v) {
              if (_newPasswordController.text.isNotEmpty &&
                  v != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text('Save Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
