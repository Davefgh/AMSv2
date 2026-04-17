import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../widgets/main_scaffold.dart';
import '../../services/api_service.dart';
import '../../models/student_model.dart';

enum _ScanState { idle, scanning, processing, success, error }

class StudentScanScreen extends StatefulWidget {
  const StudentScanScreen({super.key});

  @override
  State<StudentScanScreen> createState() => _StudentScanScreenState();
}

class _StudentScanScreenState extends State<StudentScanScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  _ScanState _scanState = _ScanState.idle;
  String _statusMessage = 'Point your camera at a QR code';
  String? _errorDetail;
  bool _torchOn = false;
  Student? _studentProfile;

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;
  late final AnimationController _resultCtrl;
  late final Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _resultAnim = CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut);

    _loadStudentProfile();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _scanLineCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final profile = await _apiService.getStudentProfile();
      if (mounted) setState(() => _studentProfile = profile);
    } catch (_) {
      // non-fatal — we just won't have the student ID pre-loaded
    }
  }

  // ── QR detected ─────────────────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanState == _ScanState.processing ||
        _scanState == _ScanState.success) {
      return;
    }

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    await _cameraController.stop();
    setState(() {
      _scanState = _ScanState.processing;
      _statusMessage = 'Verifying attendance…';
    });

    try {
      // Ensure we have the student profile
      _studentProfile ??= await _apiService.getStudentProfile();

      await _apiService.scanQrCode(
        qrHash: rawValue,
        studentId: _studentProfile!.id,
      );

      if (!mounted) return;
      setState(() {
        _scanState = _ScanState.success;
        _statusMessage = 'Attendance recorded!';
        _errorDetail = null;
      });
      _resultCtrl.forward(from: 0);
      _autoReset();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanState = _ScanState.error;
        _statusMessage = 'Check-in failed';
        _errorDetail = e.message;
      });
      _resultCtrl.forward(from: 0);
      _autoReset();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanState = _ScanState.error;
        _statusMessage = 'Something went wrong';
        _errorDetail = e.toString();
      });
      _resultCtrl.forward(from: 0);
      _autoReset();
    }
  }

  void _autoReset({Duration delay = const Duration(seconds: 3)}) {
    Timer(delay, () {
      if (!mounted) return;
      _resultCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _scanState = _ScanState.idle;
          _statusMessage = 'Point your camera at a QR code';
          _errorDetail = null;
        });
        _cameraController.start();
      });
    });
  }

  void _toggleTorch() {
    _cameraController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Scan QR Code',
      currentIndex: 1,
      isAdmin: false,
      isStudent: true,
      body: Stack(
        children: [
          _buildScannerView(),
          _buildOverlay(),
          if (_scanState == _ScanState.success || _scanState == _ScanState.error)
            _buildResultOverlay(),
        ],
      ),
    );
  }

  // ── Camera preview ───────────────────────────────────────────────────────────
  Widget _buildScannerView() {
    if (_scanState == _ScanState.idle || _scanState == _ScanState.scanning ||
        _scanState == _ScanState.processing) {
      return MobileScanner(
        controller: _cameraController,
        onDetect: _onDetect,
        errorBuilder: (context, error, child) => _buildCameraError(error),
      );
    }
    // Keep showing last frame (frozen) during result display
    return MobileScanner(
      controller: _cameraController,
      onDetect: (_) {},
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'Camera unavailable\n${error.errorDetails?.message ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dark vignette + frame + controls ────────────────────────────────────────
  Widget _buildOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final side = constraints.maxWidth * 0.68;
      final frameTop = (constraints.maxHeight - side) / 2.2;

      return Stack(
        children: [
          // ── Vignette cutout ──
          CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _VignettePainter(
              frameRect: Rect.fromLTWH(
                (constraints.maxWidth - side) / 2,
                frameTop,
                side,
                side,
              ),
            ),
          ),

          // ── Animated scan line ──
          Positioned(
            left: (constraints.maxWidth - side) / 2 + 2,
            top: frameTop,
            width: side - 4,
            height: side,
            child: AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => Stack(
                children: [
                  Positioned(
                    top: (side - 4) * _scanLineAnim.value,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFF38BDF8).withValues(alpha: 0.9),
                          Colors.transparent,
                        ]),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Corner brackets (frame) ──
          Positioned(
            left: (constraints.maxWidth - side) / 2,
            top: frameTop,
            child: _CornerBrackets(size: side),
          ),

          // ── Status bar at bottom ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStatusBar(frameTop, side, constraints.maxHeight),
          ),

          // ── Torch & flip buttons at top ──
          Positioned(
            top: 12,
            right: 16,
            child: _buildTopControls(),
          ),
        ],
      );
    });
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        _iconBtn(
          icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          tooltip: 'Torch',
          onTap: _toggleTorch,
          active: _torchOn,
        ),
        const SizedBox(width: 8),
        _iconBtn(
          icon: Icons.flip_camera_ios_rounded,
          tooltip: 'Flip camera',
          onTap: () => _cameraController.switchCamera(),
        ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon,
              color: active ? const Color(0xFF38BDF8) : Colors.white70,
              size: 22),
        ),
      ),
    );
  }

  Widget _buildStatusBar(double frameTop, double frameSide, double screenH) {
    final isProcessing = _scanState == _ScanState.processing;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Color(0xFF38BDF8),
                strokeWidth: 2.5,
              ),
            )
          else
            Icon(
              _scanState == _ScanState.idle
                  ? Icons.qr_code_scanner_rounded
                  : Icons.check_circle_outline_rounded,
              color: const Color(0xFF38BDF8),
              size: 26,
            ),
          const SizedBox(height: 10),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          if (_studentProfile != null) ...[
            const SizedBox(height: 6),
            Text(
              'Logged in as ${_studentProfile!.fullName}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Success / Error result card ──────────────────────────────────────────────
  Widget _buildResultOverlay() {
    final isSuccess = _scanState == _ScanState.success;
    final color = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final icon =
        isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isSuccess ? 'Attendance Recorded!' : 'Check-in Failed';

    return Center(
      child: ScaleTransition(
        scale: _resultAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 52),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (_errorDetail != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorDetail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Resuming scanner in 3s…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Corner brackets painter ──────────────────────────────────────────────────
class _CornerBrackets extends StatelessWidget {
  final double size;
  const _CornerBrackets({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    const r = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len + r)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len + r, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - r, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
        ..lineTo(size.width, len + r),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len - r)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
        ..lineTo(len + r, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - r, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r))
        ..lineTo(size.width, size.height - len - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Dark vignette with transparent cutout ────────────────────────────────────
class _VignettePainter extends CustomPainter {
  final Rect frameRect;
  const _VignettePainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    const rrectRadius = Radius.circular(16);
    final rrect = RRect.fromRectAndRadius(frameRect, rrectRadius);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _VignettePainter old) =>
      old.frameRect != frameRect;
}
