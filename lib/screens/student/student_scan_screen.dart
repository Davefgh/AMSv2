import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';

class StudentScanScreen extends StatefulWidget {
  const StudentScanScreen({super.key});

  @override
  State<StudentScanScreen> createState() => _StudentScanScreenState();
}

class _StudentScanScreenState extends State<StudentScanScreen> {
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Scan QR Code',
      currentIndex: 1,
      isAdmin: false,
      isStudent: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative corners or animation placeholder
                    Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 80,
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      ),
                    ),
                    // Scanning line animation placeholder could go here
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Ready to Scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Position the QR code within the frame to automatically check in for your session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scanner implementation coming soon!')),
                  );
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Allow Camera Access'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
