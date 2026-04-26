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
        // Split username as fallback for first/last if needed or leave empty for user to fill
        _isFetching = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updateData = {
        'firstname': _firstNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'sectionId': _sectionIdController.text.trim(),
        'isRegular': _isRegular,
      };

      // Add passwords only if provided
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
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
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
                color: const Color(0xFF38BDF8).withOpacity(0.15),
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
              backgroundColor: Colors.white.withOpacity(0.05),
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
              label: 'First Name', controller: _firstNameController),
          const SizedBox(height: 20),
          CustomTextField(label: 'Last Name', controller: _lastNameController),
          const SizedBox(height: 20),
          CustomTextField(
              label: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          CustomTextField(
              label: 'Section ID', controller: _sectionIdController),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Regular Student',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Switch.adaptive(
                value: _isRegular,
                onChanged: (v) => setState(() => _isRegular = v),
                activeTrackColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFields() {
    return _GlassCard(
      child: Column(
        children: [
          CustomTextField(
              label: 'Current Password',
              controller: _currentPasswordController,
              obscureText: true),
          const SizedBox(height: 20),
          CustomTextField(
              label: 'New Password',
              controller: _newPasswordController,
              obscureText: true),
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
              color: const Color(0xFF38BDF8).withOpacity(0.3),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
