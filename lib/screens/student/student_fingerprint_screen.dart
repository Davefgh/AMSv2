import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';
import '../../services/api_service.dart';
import '../../models/fingerprint_model.dart';
import '../../utils/sizing_utils.dart';
import '../../widgets/skeleton_loader.dart';

class StudentFingerprintScreen extends StatefulWidget {
  const StudentFingerprintScreen({super.key});

  @override
  State<StudentFingerprintScreen> createState() =>
      _StudentFingerprintScreenState();
}

class _StudentFingerprintScreenState extends State<StudentFingerprintScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  List<FingerprintInfo> _fingerprints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _api.getStudentProfile();
      final fingerprints = await _api.getFingerprintsByStudent(profile.id);
      setState(() {
        _fingerprints = fingerprints;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'My Fingerprints',
      currentIndex: -1,
      isStudent: true,
      showBackButton: true,
      body: _isLoading
          ? const SkeletonListView()
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF38BDF8),
                  child: _fingerprints.isEmpty
                      ? _buildEmptyState()
                      : _buildFingerprintList(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(24), vertical: Sizing.h(40)),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Fingerprints Enrolled',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your administrator to enroll your fingerprint.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFingerprintList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(24), vertical: Sizing.h(20)),
      itemCount: _fingerprints.length,
      itemBuilder: (context, index) {
        final fp = _fingerprints[index];
        return _buildFingerprintCard(fp);
      },
    );
  }

  Widget _buildFingerprintCard(FingerprintInfo fp) {
    final statusColor = fp.status?.toLowerCase() == 'active'
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      margin: EdgeInsets.only(bottom: Sizing.h(16)),
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Sizing.r(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Sizing.w(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Sizing.r(12)),
                ),
                child: Icon(Icons.fingerprint_rounded,
                    color: const Color(0xFF38BDF8), size: Sizing.sp(24)),
              ),
              SizedBox(width: Sizing.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fingerprint #${fp.id ?? '—'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Sizing.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fp.deviceId != null)
                      Text(
                        'Device: ${fp.deviceId}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: Sizing.sp(12),
                        ),
                      ),
                  ],
                ),
              ),
              if (fp.status != null)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.w(10), vertical: Sizing.h(4)),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Sizing.r(8)),
                  ),
                  child: Text(
                    fp.status!,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: Sizing.sp(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (fp.createdAt != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: Sizing.sp(14),
                    color: Colors.white.withValues(alpha: 0.4)),
                SizedBox(width: Sizing.w(6)),
                Text(
                  'Enrolled: ${fp.createdAt!.toLocal().toString().substring(0, 16)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: Sizing.sp(12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
