import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/session_model.dart';
import '../../models/schedule_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class SessionDetailsScreen extends StatefulWidget {
  final ClassSession session;
  const SessionDetailsScreen({super.key, required this.session});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final ApiService _apiService = ApiService();
  late ClassSession _session;
  Schedule? _schedule;
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isInitialLoading = true);
    try {
      final schedule = await _apiService.getSchedule(_session.scheduleId);
      setState(() {
        _schedule = schedule;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    }
  }

  Future<void> _refreshSession() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _apiService.getSessionById(_session.id);
      setState(() => _session = updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing session: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartSession({String? actualRoom, String? cutoff}) async {
    setState(() => _isLoading = true);
    try {
      // 1. If room is provided, update it first
      if (actualRoom != null && actualRoom.isNotEmpty) {
        await _apiService.updateSessionRoom(_session.id, actualRoom);
      }
      
      // 2. Start session
      await _apiService.startSession(_session.id);
      await _refreshSession();
      
      if (mounted) {
        Navigator.pop(context); // Close modal
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting session: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEndSession() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.endSession(_session.id);
      await _refreshSession();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending session: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStartModal() {
    String? selectedRoom = _session.scheduledRoomName;
    final TextEditingController cutoffController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GlassModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Confirm session details before starting.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildModalLabel('Actual Room (Optional)'),
            const SizedBox(height: 8),
            _buildModalDropdown(
              value: selectedRoom,
              items: [_session.scheduledRoomName, 'Short Course Laboratory', 'Room 302'],
              onChanged: (val) => selectedRoom = val,
            ),
            const SizedBox(height: 24),
            _buildModalLabel('Attendance Cutoff (Optional)'),
            const SizedBox(height: 8),
            _buildModalTextField(
              controller: cutoffController,
              hint: 'e.g., 15 minutes',
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleStartSession(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Skip & Start', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStartSession(
                      actualRoom: selectedRoom,
                      cutoff: cutoffController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Confirm & Start', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    bool isActive = _session.status == 'active';
    bool isEnded = _session.status == 'ended';

    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          _session.sectionName.isNotEmpty 
                              ? '${_session.sectionName} - ${_session.subjectName}'
                              : 'CS31A - Software Engineering 1',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Glass Container for Details
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.access_time_filled_rounded, 
                                title: _schedule != null 
                                    ? '${_formatTime(_schedule!.timeIn)} - ${_formatTime(_schedule!.timeOut)}'
                                    : '10:30 AM - 12:30 PM', 
                                subtitle: _getDurationText(_schedule),
                                iconColor: const Color(0xFF38BDF8),
                              ),
                              _buildDivider(),
                              _buildInfoRow(
                                icon: Icons.location_on_rounded, 
                                title: _session.actualRoom ?? _session.scheduledRoomName,
                                subtitle: 'Classroom Location',
                                badge: _hasRoomChanged ? 'Updated' : null,
                                iconColor: const Color(0xFF38BDF8),
                              ),
                              _buildDivider(),
                              _buildInfoRow(
                                icon: isActive ? Icons.play_circle_fill_rounded : (isEnded ? Icons.stop_circle_rounded : Icons.hourglass_full_rounded),
                                title: isActive ? 'Session Active' : (isEnded ? 'Session Ended' : 'Session Not Started'),
                                subtitle: 'Current Status',
                                iconColor: isActive ? const Color(0xFF34D399) : (isEnded ? Colors.redAccent : const Color(0xFFFBBF24)),
                              ),
                              _buildDivider(),
                              if (_session.cutoff != null && _session.cutoff!.isNotEmpty) ...[
                                _buildInfoRow(
                                  icon: Icons.timer_rounded, 
                                  title: _session.cutoff!, 
                                  subtitle: 'Attendance Cutoff',
                                  iconColor: const Color(0xFF38BDF8),
                                ),
                                _buildDivider(),
                              ],
                              _buildInfoRow(
                                icon: Icons.person_rounded, 
                                title: 'Jovelyn Comaingking', 
                                subtitle: 'Subject Instructor',
                                iconColor: const Color(0xFF38BDF8),
                                isInstructor: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(isActive, isEnded),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
            ),
        ],
      ),
    );
  }

  String _getDurationText(Schedule? s) {
    if (s == null) return '90 minutes';
    try {
      final t1 = s.timeIn.split(':').map((e) => int.parse(e)).toList();
      final t2 = s.timeOut.split(':').map((e) => int.parse(e)).toList();
      final start = DateTime(2000, 1, 1, t1[0], t1[1]);
      final end = DateTime(2000, 1, 1, t2[0], t2[1]);
      final diff = end.difference(start).inMinutes;
      return '$diff minutes';
    } catch (_) {
      return '90 minutes';
    }
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Top Right Orb
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
            ),
          ),
        ),
        // Middle Left Orb
        Positioned(
          top: 300,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
            ),
          ),
        ),
        // Bottom Right Orb
        Positioned(
          bottom: -50,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const Text(
            'Session Details',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Color? iconColor, 
    String? badge,
    bool isInstructor = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.white).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (iconColor ?? Colors.white).withValues(alpha: 0.1)),
            ),
            child: isInstructor 
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: NetworkImage('https://ui-avatars.com/api/?name=Jovelyn+Comaingking&background=38BDF8&color=0F172A'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Icon(icon, color: iconColor ?? Colors.white70, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3), 
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
    );
  }

  Widget _buildBottomActions(bool isActive, bool isEnded) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isActive && !isEnded)
            _buildActionButton(
              onPressed: _showStartModal,
              icon: Icons.play_arrow_rounded,
              label: 'Start Session',
              color: const Color(0xFF38BDF8),
              textColor: const Color(0xFF0F172A),
            ),
          if (isActive) ...[
            _buildActionButton(
              onPressed: _showQRCodeDialog,
              icon: Icons.qr_code_rounded,
              label: 'QR Code',
              color: const Color(0xFF38BDF8),
              textColor: const Color(0xFF0F172A),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              onPressed: _handleEndSession,
              icon: Icons.stop_rounded,
              label: 'End Session',
              color: Colors.redAccent.withValues(alpha: 0.1),
              textColor: Colors.redAccent,
              isOutlined: true,
            ),
          ],
          if (isEnded)
            _buildActionButton(
              onPressed: () => Navigator.pop(context),
              icon: Icons.check_rounded,
              label: 'Done',
              color: Colors.white.withValues(alpha: 0.05),
              textColor: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isOutlined ? [] : [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isOutlined ? BorderSide(color: color.withValues(alpha: 0.3)) : BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  bool get _hasRoomChanged {
    if (_session.actualRoom == null || _schedule == null) return false;
    return _session.actualRoom != _schedule!.classroomName;
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '--:--';
    try {
      final parts = raw.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final suffix = h >= 12 ? 'PM' : 'AM';
      h = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

  void _showQRCodeDialog() {
    // We encode the sessionId as the data for the student to scan.
    final String qrData = 'session:${_session.id}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Session QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${_session.sectionName} - ${_session.subjectName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Students can scan this to record attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildModalDropdown({required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModalTextField({required TextEditingController controller, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _GlassModal extends StatelessWidget {
  final Widget child;
  const _GlassModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: child,
    );
  }
}
