import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/health_status.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  String? _error;
  HealthStatusResponse? _ready;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ready = await _apiService.getHealthReady();
      if (!mounted) return;
      setState(() {
        _ready = ready;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.45),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.45),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF38BDF8),
                    onRefresh: _loadAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      children: [
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          )
                        else if (_error != null)
                          _GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded,
                                        color: Color(0xFFFBBF24), size: 22),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Health status unavailable',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadAll,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          _buildSectionTitle('Readiness'),
                          const SizedBox(height: 12),
                          _buildHealthCard(
                            health: _ready!,
                            showIntegrityDetails: true,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.health_and_safety_outlined,
                    color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 14),
              const Text(
                'Health',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.6), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHealthCard({
    required HealthStatusResponse health,
    bool showIntegrityDetails = false,
  }) {
    final ok = health.overallHealthy;
    final chipColor = ok ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health status',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  health.status.toUpperCase(),
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (health.timestamp != null) ...[
            const SizedBox(height: 10),
            Text(
              'timestamp: ${health.timestamp}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
          if (health.database != null) ...[
            const SizedBox(height: 14),
            _row(
              Icons.storage_rounded,
              'Database',
              health.database!.connected
                  ? 'Connected · ${health.database!.status}'
                  : 'Not connected',
              health.database!.connected
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
            ),
          ],
          if (health.dataIntegrity != null) ...[
            const SizedBox(height: 10),
            _row(
              Icons.fact_check_outlined,
              'Data integrity',
              '${health.dataIntegrity!.status} · orphaned users: ${health.dataIntegrity!.orphanedUserCount}',
              health.dataIntegrity!.isHealthy
                  ? const Color(0xFF34D399)
                  : const Color(0xFFFBBF24),
            ),
            if (showIntegrityDetails) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  'Soft-delete issues: students ${health.dataIntegrity!.softDeleteInconsistencies.students}, '
                  'instructors ${health.dataIntegrity!.softDeleteInconsistencies.instructors}, '
                  'admins ${health.dataIntegrity!.softDeleteInconsistencies.admins}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label · ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

