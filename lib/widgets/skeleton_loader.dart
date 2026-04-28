import 'package:flutter/material.dart';

/// A single shimmer block — the base building block.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 10,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.18 + _anim.value * 0.1),
              Colors.white.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Pre-built skeleton layouts ──────────────────────────────────────────────

/// Card with an icon + two lines of text (used in list screens)
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14),
                const SizedBox(height: 8),
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.4, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column stat card grid (admin/teacher dashboard)
class SkeletonStatGrid extends StatelessWidget {
  final int count;
  const SkeletonStatGrid({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: List.generate(count, (_) => _SkeletonStatCard()),
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(width: 40, height: 40, radius: 12),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 28, radius: 8),
          SizedBox(height: 6),
          SkeletonBox(height: 11),
          SizedBox(height: 8),
          SkeletonBox(height: 6, radius: 4),
        ],
      ),
    );
  }
}

/// Full-page list skeleton (wraps N SkeletonListItems)
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SkeletonListView({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonListItem(),
    );
  }
}

/// Dashboard skeleton: stat grid + a wide card below
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 14),
          const SizedBox(height: 16),
          const SkeletonStatGrid(),
          const SizedBox(height: 28),
          const SkeletonBox(width: 140, height: 14),
          const SizedBox(height: 16),
          _SkeletonWideCard(),
          const SizedBox(height: 28),
          const SkeletonBox(width: 160, height: 14),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const SkeletonListItem()),
        ],
      ),
    );
  }
}

class _SkeletonWideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 80, height: 32, radius: 8),
              SkeletonBox(width: 120, height: 28, radius: 14),
            ],
          ),
          SizedBox(height: 24),
          SkeletonBox(height: 100, radius: 12),
        ],
      ),
    );
  }
}

/// Profile skeleton
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Avatar card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Column(
              children: [
                SkeletonBox(width: 100, height: 100, radius: 50),
                SizedBox(height: 16),
                SkeletonBox(width: 160, height: 20, radius: 8),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 14, radius: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Detail rows
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: List.generate(
                  4,
                  (i) => const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            SkeletonBox(width: 40, height: 40, radius: 12),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonBox(width: 80, height: 11),
                                  SizedBox(height: 6),
                                  SkeletonBox(height: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

/// Session/attendance card skeleton
class SkeletonSessionList extends StatelessWidget {
  final int itemCount;
  const SkeletonSessionList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 80, height: 11),
                SkeletonBox(width: 60, height: 22, radius: 20),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 18),
            SizedBox(height: 16),
            SkeletonBox(height: 11),
            SizedBox(height: 6),
            SkeletonBox(width: 160, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Skeleton that mirrors the redesigned SessionDetailsScreen layout.
class SkeletonSessionDetails extends StatelessWidget {
  const SkeletonSessionDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  // Back button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  const SkeletonBox(width: 110, height: 13, radius: 6),
                  const Spacer(),
                  // Status pill
                  const SkeletonBox(width: 56, height: 20, radius: 8),
                ],
              ),
            ),

            // ── Scrollable body
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    const SkeletonBox(width: 80, height: 10, radius: 4),
                    const SizedBox(height: 6),
                    // Subject name
                    const SkeletonBox(width: 220, height: 19, radius: 6),
                    const SizedBox(height: 18),

                    // ── Info card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Column(
                        children: [
                          _skeletonInfoRow(),
                          _skeletonDivider(),
                          _skeletonInfoRow(labelWidth: 140),
                          _skeletonDivider(),
                          _skeletonInfoRow(labelWidth: 100),
                          _skeletonDivider(),
                          _skeletonInfoRow(labelWidth: 80),
                          _skeletonDivider(),
                          _skeletonInfoRow(labelWidth: 160),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── QR section header
                    Row(
                      children: [
                        const SkeletonBox(width: 60, height: 10, radius: 4),
                        const SizedBox(width: 8),
                        const SkeletonBox(width: 20, height: 16, radius: 5),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── QR entry cards
                    _skeletonQrCard(),
                    const SizedBox(height: 8),
                    _skeletonQrCard(),
                  ],
                ),
              ),
            ),

            // ── Bottom action bar skeleton
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: const SkeletonBox(height: 46, radius: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// One compact info row: 32×32 icon square + two stacked lines.
  static Widget _skeletonInfoRow({double labelWidth = 120}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const SkeletonBox(width: 32, height: 32, radius: 8),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: labelWidth, height: 13, radius: 5),
              const SizedBox(height: 4),
              const SkeletonBox(width: 70, height: 10, radius: 4),
            ],
          ),
        ],
      ),
    );
  }

  /// Hairline divider aligned to the text column (not the icon).
  static Widget _skeletonDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  /// One QR entry card: 32×32 icon + two stacked lines + status pill.
  static Widget _skeletonQrCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 32, height: 32, radius: 8),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 13, radius: 5),
                SizedBox(height: 4),
                SkeletonBox(width: 140, height: 10, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(width: 48, height: 20, radius: 6),
        ],
      ),
    );
  }
}
