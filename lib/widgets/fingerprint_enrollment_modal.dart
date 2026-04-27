import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';
import '../utils/sizing_utils.dart';

class FingerprintEnrollmentModal extends StatefulWidget {
  final Student student;
  final VoidCallback? onEnrollmentComplete;

  const FingerprintEnrollmentModal({
    super.key,
    required this.student,
    this.onEnrollmentComplete,
  });

  @override
  State<FingerprintEnrollmentModal> createState() =>
      _FingerprintEnrollmentModalState();
}

class _FingerprintEnrollmentModalState
    extends State<FingerprintEnrollmentModal> {
  final ApiService _apiService = ApiService();
  
  List<FingerprintDevice> _devices = [];
  FingerprintDevice? _selectedDevice;
  bool _isLoadingDevices = true;
  bool _isEnrolling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoadingDevices = true;
      _errorMessage = null;
    });

    try {
      final devices = await _apiService.getFingerprintDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load devices: $e';
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _startEnrollment() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device')),
      );
      return;
    }

    setState(() {
      _isEnrolling = true;
      _errorMessage = null;
    });

    try {
      final session = await _apiService.createFingerprintEnrollmentSession(
        studentId: widget.student.id,
        deviceId: _selectedDevice!.id,
      );

      if (mounted) {
        if (session.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(session.message ?? 'Enrollment session created'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onEnrollmentComplete?.call();
        } else {
          setState(() {
            _errorMessage = session.message ?? 'Failed to create enrollment session';
            _isEnrolling = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isEnrolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Sizing.w(500),
          maxHeight: Sizing.h(450),
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizing.w(24),
                vertical: Sizing.h(20),
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Sizing.w(8)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      color: const Color(0xFF6366F1),
                      size: Sizing.sp(24),
                    ),
                  ),
                  SizedBox(width: Sizing.w(12)),
                  Expanded(
                    child: Text(
                      'Fingerprint Enrollment',
                      style: TextStyle(
                        color: textColor,
                        fontSize: Sizing.sp(18),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: subtitleColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: Sizing.sp(24),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Sizing.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Info Card
                    Container(
                      padding: EdgeInsets.all(Sizing.w(16)),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: Sizing.w(48),
                            height: Sizing.w(48),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                widget.student.firstname.isNotEmpty
                                    ? widget.student.firstname[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: const Color(0xFF6366F1),
                                  fontSize: Sizing.sp(20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: Sizing.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.student.fullName,
                                  style: TextStyle(
                                    fontSize: Sizing.sp(15),
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: Sizing.h(2)),
                                Text(
                                  'ID: ${widget.student.displayId}',
                                  style: TextStyle(
                                    fontSize: Sizing.sp(12),
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Sizing.h(24)),

                    // Device Selection Label
                    Text(
                      'Select Fingerprint Device',
                      style: TextStyle(
                        fontSize: Sizing.sp(13),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: Sizing.h(8)),

                    if (_isLoadingDevices)
                      Container(
                        padding: EdgeInsets.all(Sizing.w(32)),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: const Color(0xFF6366F1),
                              strokeWidth: 2.5,
                            ),
                            SizedBox(height: Sizing.h(12)),
                            Text(
                              'Loading devices...',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: Sizing.sp(13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_devices.isEmpty)
                      Container(
                        padding: EdgeInsets.all(Sizing.w(20)),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: Sizing.sp(24),
                            ),
                            SizedBox(width: Sizing.w(16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Devices Available',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: Sizing.sp(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: Sizing.h(4)),
                                  Text(
                                    'Please ensure a fingerprint device is connected and online.',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: Sizing.sp(12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FingerprintDevice>(
                            isExpanded: true,
                            value: _selectedDevice,
                            padding: EdgeInsets.symmetric(horizontal: Sizing.w(16)),
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: backgroundColor,
                            hint: Text(
                              'Choose a device...',
                              style: TextStyle(
                                fontSize: Sizing.sp(14),
                                color: subtitleColor,
                              ),
                            ),
                            items: _devices.map((device) {
                              return DropdownMenuItem<FingerprintDevice>(
                                value: device,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: Sizing.h(8)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(Sizing.w(8)),
                                        decoration: BoxDecoration(
                                          color: device.isOnline
                                              ? Colors.green.withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.devices_rounded,
                                          size: Sizing.sp(20),
                                          color: device.isOnline
                                              ? Colors.green.shade600
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                      SizedBox(width: Sizing.w(12)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              device.name,
                                              style: TextStyle(
                                                fontSize: Sizing.sp(14),
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                            if (device.location != null) ...[
                                              SizedBox(height: Sizing.h(2)),
                                              Text(
                                                device.location!,
                                                style: TextStyle(
                                                  fontSize: Sizing.sp(12),
                                                  color: subtitleColor,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (device.isOnline)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Sizing.w(10),
                                            vertical: Sizing.h(4),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: Sizing.w(6),
                                                height: Sizing.w(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade500,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: Sizing.w(6)),
                                              Text(
                                                'Online',
                                                style: TextStyle(
                                                  fontSize: Sizing.sp(11),
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (device) {
                              setState(() {
                                _selectedDevice = device;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ),

                    if (_errorMessage != null) ...[
                      SizedBox(height: Sizing.h(16)),
                      Container(
                        padding: EdgeInsets.all(Sizing.w(16)),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: Sizing.sp(20),
                            ),
                            SizedBox(width: Sizing.w(12)),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: Sizing.sp(13),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: EdgeInsets.all(Sizing.w(24)),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isEnrolling ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: borderColor),
                        padding: EdgeInsets.symmetric(vertical: Sizing.h(14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: Sizing.sp(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Sizing.w(12)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isEnrolling || _selectedDevice == null
                          ? null
                          : _startEnrollment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: EdgeInsets.symmetric(vertical: Sizing.h(14)),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isEnrolling
                          ? SizedBox(
                              width: Sizing.w(20),
                              height: Sizing.w(20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: Sizing.sp(20)),
                                SizedBox(width: Sizing.w(8)),
                                Text(
                                  'Start Enrollment',
                                  style: TextStyle(
                                    fontSize: Sizing.sp(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
