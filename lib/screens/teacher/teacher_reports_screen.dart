import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/main_scaffold.dart';
import '../../utils/sizing_utils.dart';
import '../../providers/app_provider.dart';

class TeacherReportsScreen extends ConsumerStatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  ConsumerState<TeacherReportsScreen> createState() =>
      _TeacherReportsScreenState();
}

// ─── Simple data holders ──────────────────────────────────────────────────────

class _DayStat {
  final String label;
  final int present;
  final int absent;
  _DayStat(this.label, this.present, this.absent);
  int get total => present + absent;
}

class _SectionStat {
  final String name;
  final int present;
  final int absent;
  _SectionStat(this.name, this.present, this.absent);
  int get total => present + absent;
  double get rate => total == 0 ? 0 : present / total;
}

class _Acc {
  int p = 0, a = 0;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class _TeacherReportsScreenState extends ConsumerState<TeacherReportsScreen> {
  final ApiService _api = ApiService();
  String _period = 'Today';
  bool _isLoading = false;
  String? _error;

  int _totalStudents = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  double _attendanceRate = 0;
  List<_DayStat> _dayStats = [];
  List<_SectionStat> _sectionStats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Date range helper ──────────────────────────────────────────────────────

  DateTimeRange _range() {
    final now = DateTime.now();
    switch (_period) {
      case 'Week':
        final mon = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: DateTime(mon.year, mon.month, mon.day), end: now);
      case 'Month':
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: now);
      case 'Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default:
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day), end: now);
    }
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 1️⃣  Top-level summary from /api/reports/attendance-summary
      Map<String, dynamic> summary = {};
      try {
        summary = await _api.getReportAttendanceSummary();
      } catch (_) {}

      // 2️⃣  Per-session breakdown from /api/reports/instructor-sessions/{id}
      List<dynamic> sessionList = [];
      try {
        final profile = await _api.getInstructorProfile();
        if (profile.hasValidId) {
          sessionList = await _api.getReportInstructorSessions(profile.id);
        }
      } catch (_) {}

      // Fallback: if reports API unavailable, use getMySessions + attendance
      if (sessionList.isEmpty) {
        try {
          final sessions = await _api.getMySessions();
          // Fetch attendance for each session in parallel
          final attendanceFutures = sessions.map((s) async {
            try {
              return await _api.getAttendanceBySession(s.id);
            } catch (_) {
              return [];
            }
          });
          final allAttendance = await Future.wait(attendanceFutures);

          sessionList = List.generate(sessions.length, (i) {
            final s = sessions[i];
            final records = allAttendance[i];
            int p = 0, a = 0;
            for (final r in records) {
              final st = (r.status as String).toLowerCase();
              if (st == 'present' || st == 'late') {
                p++;
              } else {
                a++;
              }
            }
            return {
              'sessionDate': s.sessionDate?.toIso8601String(),
              'sectionName': s.sectionName,
              'sessionId': s.id,
              'presentCount': p,
              'absentCount': a,
            };
          });
        } catch (_) {}
      }

      // ── Parse summary stats ──────────────────────────────────────────────
      final int totalStudents =
          (summary['totalStudents'] ?? summary['total_students'] ?? 0) as int;
      final int presentCount =
          (summary['totalPresent'] ?? summary['present'] ?? summary['presentCount'] ?? 0) as int;
      final int absentCount =
          (summary['totalAbsent'] ?? summary['absent'] ?? summary['absentCount'] ?? 0) as int;
      final double rate = (presentCount + absentCount) == 0
          ? 0
          : presentCount / (presentCount + absentCount);

      // ── Filter sessions by period ────────────────────────────────────────
      final r = _range();
      final filtered = sessionList.where((s) {
        final raw = s['sessionDate'] as String?;
        if (raw == null) return _period == 'Today'; // can't filter → include today only
        try {
          final d = DateTime.parse(raw);
          return !d.isBefore(r.start) && !d.isAfter(r.end);
        } catch (_) {
          return false;
        }
      }).toList();

      // ── Day buckets ──────────────────────────────────────────────────────
      final Map<String, _Acc> dayMap = {};
      final Map<String, _Acc> secMap = {};

      for (final s in filtered) {
        final raw = s['sessionDate'] as String?;
        final dayLabel = raw != null
            ? DateFormat('EEE').format(DateTime.parse(raw))
            : '?';
        final sectionName = (s['sectionName'] ?? s['section'] ?? 'Unknown') as String;
        final int p = (s['presentCount'] ?? s['present'] ?? 0) as int;
        final int a = (s['absentCount'] ?? s['absent'] ?? 0) as int;

        dayMap.putIfAbsent(dayLabel, _Acc.new)
          ..p += p
          ..a += a;
        secMap.putIfAbsent(sectionName, _Acc.new)
          ..p += p
          ..a += a;
      }

      if (mounted) {
        setState(() {
          // Use summary API if it returned data, else aggregate from sessions
          if (totalStudents > 0 || presentCount > 0 || absentCount > 0) {
            _totalStudents = totalStudents;
            _presentCount = presentCount;
            _absentCount = absentCount;
            _attendanceRate = rate;
          } else {
            // Aggregate from session rows
            int tp = 0, ta = 0;
            for (final s in filtered) {
              tp += (s['presentCount'] ?? s['present'] ?? 0) as int;
              ta += (s['absentCount'] ?? s['absent'] ?? 0) as int;
            }
            _presentCount = tp;
            _absentCount = ta;
            // tp+ta = total attendance records ≈ unique students in this period
            _totalStudents = tp + ta;
            _attendanceRate = (tp + ta) == 0 ? 0 : tp / (tp + ta);
          }
          _dayStats = dayMap.entries
              .map((e) => _DayStat(e.key, e.value.p, e.value.a))
              .toList();
          _sectionStats = secMap.entries
              .map((e) => _SectionStat(e.key, e.value.p, e.value.a))
              .toList()
            ..sort((a, b) => b.rate.compareTo(a.rate));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Reports & Analytics',
      currentIndex: -1,
      isStudent: false,
      showBackButton: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final app = ref.watch(appProvider);
    final isDark = app.isDarkMode;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final sub = isDark ? Colors.white60 : const Color(0xFF64748B);
    final card = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
    }
    if (_error != null) {
      return _buildError(textColor, sub);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF0EA5E9),
      child: Container(
        color: bg,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.all(Sizing.w(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Track attendance and performance metrics',
                  style: TextStyle(color: sub, fontSize: Sizing.sp(13))),
              SizedBox(height: Sizing.h(20)),

              // Period selector
              _buildPeriodRow(isDark, textColor),
              SizedBox(height: Sizing.h(24)),

              // 4 stat cards
              _buildStatsGrid(isDark, card, textColor, sub),
              SizedBox(height: Sizing.h(32)),

              // Attendance trend
              _buildSectionTitle('Attendance Trend', isDark, textColor),
              SizedBox(height: Sizing.h(4)),
              Text(
                  _period == 'Today'
                      ? "Today's session overview"
                      : '$_period attendance overview',
                  style: TextStyle(color: sub, fontSize: Sizing.sp(12))),
              SizedBox(height: Sizing.h(16)),
              _buildTrendCard(isDark, card, sub),
              SizedBox(height: Sizing.h(32)),

              // Class performance
              _buildSectionTitle('Class Performance', isDark, textColor),
              SizedBox(height: Sizing.h(4)),
              Text('Section-wise attendance rate',
                  style: TextStyle(color: sub, fontSize: Sizing.sp(12))),
              SizedBox(height: Sizing.h(16)),
              _buildPerformanceCard(isDark, card, textColor, sub),
              SizedBox(height: Sizing.h(40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────

  Widget _buildPeriodRow(bool isDark, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Today', 'Week', 'Month', 'Year'].map((p) {
          final sel = _period == p;
          return Padding(
            padding: EdgeInsets.only(right: Sizing.w(10)),
            child: GestureDetector(
              onTap: () {
                setState(() => _period = p);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.w(18), vertical: Sizing.h(9)),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)])
                      : null,
                  color: sel
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade300),
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Text(p,
                    style: TextStyle(
                        color: sel ? Colors.white : textColor,
                        fontSize: Sizing.sp(13),
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 4 stat cards ───────────────────────────────────────────────────────────

  Widget _buildStatsGrid(
      bool isDark, Color card, Color text, Color sub) {
    final pct = (_attendanceRate * 100).toStringAsFixed(1);
    return Column(children: [
      Row(children: [
        Expanded(
            child: _statCard('Total Students', '$_totalStudents',
                Icons.people_outline_rounded, const Color(0xFF6366F1),
                isDark, card, text, sub)),
        SizedBox(width: Sizing.w(14)),
        Expanded(
            child: _statCard('Present', '$_presentCount',
                Icons.check_circle_outline_rounded, const Color(0xFF10B981),
                isDark, card, text, sub)),
      ]),
      SizedBox(height: Sizing.h(14)),
      Row(children: [
        Expanded(
            child: _statCard('Absent', '$_absentCount',
                Icons.cancel_outlined, const Color(0xFFEF4444),
                isDark, card, text, sub)),
        SizedBox(width: Sizing.w(14)),
        Expanded(
            child: _statCard('Attendance Rate', '$pct%',
                Icons.bar_chart_rounded, const Color(0xFFF59E0B),
                isDark, card, text, sub)),
      ]),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color accent,
      bool isDark, Color card, Color text, Color sub) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(18)),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Sizing.w(9)),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: Sizing.sp(22)),
          ),
          SizedBox(height: Sizing.h(14)),
          Text(label,
              style: TextStyle(
                  color: sub,
                  fontSize: Sizing.sp(11),
                  fontWeight: FontWeight.w600)),
          SizedBox(height: Sizing.h(4)),
          Text(value,
              style: TextStyle(
                  color: text,
                  fontSize: Sizing.sp(26),
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, bool isDark, Color text) {
    return Row(children: [
      Container(
          width: Sizing.w(4),
          height: Sizing.h(20),
          decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              borderRadius: BorderRadius.circular(2))),
      SizedBox(width: Sizing.w(10)),
      Text(title,
          style: TextStyle(
              color: text,
              fontSize: Sizing.sp(17),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3)),
    ]);
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────

  Widget _buildTrendCard(bool isDark, Color card, Color sub) {
    return Container(
      padding: EdgeInsets.all(Sizing.w(20)),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: _dayStats.isEmpty
          ? _emptyState(Icons.show_chart_rounded, 'No Attendance Data',
              'No attendance records found for the selected period.\nCreate sessions and take attendance to see trends.',
              sub)
          : _buildBarChart(isDark, sub),
    );
  }

  Widget _buildBarChart(bool isDark, Color sub) {
    // Use present as the max scale reference
    final maxVal = _dayStats
        .map((d) => d.present > d.absent ? d.present : d.absent)
        .fold(0, (a, b) => a > b ? a : b);
    final scale = maxVal == 0 ? 1 : maxVal; // avoid divide-by-zero
    const double barH = 120;

    return Column(children: [
      // Legend
      Row(children: [
        _legend('Present', const Color(0xFF0EA5E9)),
        SizedBox(width: Sizing.w(16)),
        _legend('Absent', const Color(0xFFEF4444)),
      ]),
      SizedBox(height: Sizing.h(20)),
      SizedBox(
        height: Sizing.h(barH + 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _dayStats.map((d) {
            final pFrac = d.present / scale;
            final aFrac = d.absent / scale;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value labels
                  if (d.present > 0 || d.absent > 0)
                    Padding(
                      padding: EdgeInsets.only(bottom: Sizing.h(4)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${d.present}',
                              style: TextStyle(
                                  color: const Color(0xFF0EA5E9),
                                  fontSize: Sizing.sp(9),
                                  fontWeight: FontWeight.w700)),
                          Text('/',
                              style: TextStyle(
                                  color: sub.withValues(alpha: 0.4),
                                  fontSize: Sizing.sp(9))),
                          Text('${d.absent}',
                              style: TextStyle(
                                  color: const Color(0xFFEF4444),
                                  fontSize: Sizing.sp(9),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  // Side-by-side bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Present bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: Sizing.w(10),
                        height: pFrac == 0
                            ? Sizing.h(3)
                            : Sizing.h(barH) * pFrac,
                        decoration: BoxDecoration(
                            color: pFrac == 0
                                ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                                : const Color(0xFF0EA5E9),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4))),
                      ),
                      SizedBox(width: Sizing.w(3)),
                      // Absent bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: Sizing.w(10),
                        height: aFrac == 0
                            ? Sizing.h(3)
                            : Sizing.h(barH) * aFrac,
                        decoration: BoxDecoration(
                            color: aFrac == 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : const Color(0xFFEF4444).withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4))),
                      ),
                    ],
                  ),
                  SizedBox(height: Sizing.h(6)),
                  Text(d.label,
                      style: TextStyle(
                          color: sub,
                          fontSize: Sizing.sp(10),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _legend(String label, Color color) {
    return Row(children: [
      Container(
          width: Sizing.w(10),
          height: Sizing.h(10),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      SizedBox(width: Sizing.w(6)),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: Sizing.sp(11),
              fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Section performance list ───────────────────────────────────────────────

  Widget _buildPerformanceCard(
      bool isDark, Color card, Color text, Color sub) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: _sectionStats.isEmpty
          ? Padding(
              padding: EdgeInsets.all(Sizing.w(24)),
              child: _emptyState(Icons.school_outlined, 'No Section Data',
                  'No attendance data available for any section.\nAttendance taken in sections will appear here.',
                  sub))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sectionStats.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, i) =>
                  _sectionRow(_sectionStats[i], isDark, text, sub),
            ),
    );
  }

  Widget _sectionRow(
      _SectionStat s, bool isDark, Color text, Color sub) {
    final pct = (s.rate * 100).toStringAsFixed(0);
    final Color barColor = s.rate >= 0.8
        ? const Color(0xFF10B981)
        : (s.rate >= 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444));

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: Sizing.w(20), vertical: Sizing.h(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(s.name,
                style: TextStyle(
                    color: text,
                    fontSize: Sizing.sp(14),
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text('$pct%',
              style: TextStyle(
                  color: barColor,
                  fontSize: Sizing.sp(14),
                  fontWeight: FontWeight.w900)),
        ]),
        SizedBox(height: Sizing.h(4)),
        Text('${s.present} Present  •  ${s.absent} Absent',
            style: TextStyle(color: sub, fontSize: Sizing.sp(11))),
        SizedBox(height: Sizing.h(8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: s.rate,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: Sizing.h(6),
          ),
        ),
      ]),
    );
  }

  // ── Empty / Error states ───────────────────────────────────────────────────

  Widget _emptyState(
      IconData icon, String title, String body, Color sub) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: Sizing.sp(56), color: sub.withValues(alpha: 0.3)),
      SizedBox(height: Sizing.h(14)),
      Text(title,
          style: TextStyle(
              color: sub, fontSize: Sizing.sp(15), fontWeight: FontWeight.w700)),
      SizedBox(height: Sizing.h(6)),
      Text(body,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: sub.withValues(alpha: 0.65),
              fontSize: Sizing.sp(12),
              height: 1.5)),
    ]);
  }

  Widget _buildError(Color text, Color sub) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444), size: 56),
        const SizedBox(height: 14),
        Text('Failed to load reports',
            style: TextStyle(
                color: text, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(_error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 13)),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}
