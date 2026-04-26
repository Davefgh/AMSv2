import 'package:flutter/material.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../services/api_service.dart';
import '../../../models/fingerprint_model.dart';
import '../../../models/student_model.dart';
import '../../../utils/sizing_utils.dart';

class FingerprintEnrollmentScreen extends StatefulWidget {
  const FingerprintEnrollmentScreen({super.key});

  @override
  State<FingerprintEnrollmentScreen> createState() =>
      _FingerprintEnrollmentScreenState();
}

class _FingerprintEnrollmentScreenState
    extends State<FingerprintEnrollmentScreen> {
  final ApiService _api = ApiService();
  final _deviceIdCtrl = TextEditingController();
  final _studentSearchCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<Student> _searchResults = [];
  Student? _selectedStudent;
  EnrollmentSession? _activeSession;

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _studentSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _api.searchStudentsByName(query.trim());
      setState(() => _searchResults = results);
    } catch (e) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startEnrollment() async {
    final deviceId = _deviceIdCtrl.text.trim();
    if (deviceId.isEmpty) {
      setState(() => _error = 'Please enter a Device ID.');
      return;
    }
    if (_selectedStudent == null) {
      setState(() => _error = 'Please select a student.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _activeSession = null;
    });
    try {
      final session = await _api.createFingerprintEnrollmentSession(
        studentId: _selectedStudent!.id,
        deviceId: deviceId,
      );
      setState(() => _activeSession = session);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkDeviceSession() async {
    final deviceId = _deviceIdCtrl.text.trim();
    if (deviceId.isEmpty) {
      setState(() => _error = 'Please enter a Device ID first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final session = await _api.getDeviceEnrollmentSession(deviceId);
      setState(() => _activeSession = session);
      if (session == null) {
        _showSnack('No active session found for this device.', isError: true);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _activeSession = null;
      _selectedStudent = null;
      _searchResults = [];
      _error = null;
      _studentSearchCtrl.clear();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Fingerprint Enrollment',
      currentIndex: -1,
      isAdmin: true,
      showBackButton: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: Sizing.w(24), vertical: Sizing.h(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Device'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _deviceIdCtrl,
              hint: 'Enter Device ID',
              icon: Icons.devices_rounded,
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Student'),
            const SizedBox(height: 8),
            _buildStudentSearch(),
            if (_selectedStudent != null) ...[
              const SizedBox(height: 12),
              _buildSelectedStudentChip(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_error!),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(),
            if (_activeSession != null) ...[
              const SizedBox(height: 28),
              _buildSessionCard(_activeSession!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: Sizing.sp(13),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStudentSearch() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _studentSearchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: _searchStudents,
            decoration: InputDecoration(
              hintText: 'Search student by name…',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF38BDF8))),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: Colors.white.withOpacity(0.07)),
              itemBuilder: (context, i) {
                final s = _searchResults[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF38BDF8).withOpacity(0.15),
                    child: Text(
                      s.firstname.isNotEmpty ? s.firstname[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(s.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('ID: ${s.id}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12)),
                  onTap: () {
                    setState(() {
                      _selectedStudent = s;
                      _searchResults = [];
                      _studentSearchCtrl.clear();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedStudentChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedStudent!.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('Student ID: ${_selectedStudent!.id}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedStudent = null),
            child: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.4), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _startEnrollment,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF0F172A)))
                : const Icon(Icons.fingerprint_rounded),
            label: Text(_isLoading ? 'Creating Session…' : 'Start Enrollment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _checkDeviceSession,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check Device Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.clear_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionCard(EnrollmentSession session) {
    final isSuccess = session.success == true;
    final color = isSuccess ? Colors.greenAccent : const Color(0xFF38BDF8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.fingerprint_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isSuccess ? 'Session Created' : 'Enrollment Session',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSessionRow(
              'Session ID', session.enrollmentSessionId ?? '—'),
          _buildSessionRow('Student ID', session.studentId?.toString() ?? '—'),
          if (session.studentName != null)
            _buildSessionRow('Student', session.studentName!),
          if (session.deviceId != null)
            _buildSessionRow('Device', session.deviceId!),
          if (session.assignedSensorFingerprintId != null)
          _buildSessionRow('Sensor Slot', session.assignedSensorFingerprintId?.toString() ?? '—'),
          if (session.status != null)
            _buildSessionRow('Status', session.status!),
          if (session.expiresAt != null)
            _buildSessionRow(
                'Expires At',
                session.expiresAt!.toLocal().toString().substring(0, 19)),
          if (session.message != null && session.message!.isNotEmpty)
            _buildSessionRow('Message', session.message!),
        ],
      ),
    );
  }

  Widget _buildSessionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
