// lib/screens/stats/stats_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bingo_widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';

// ─── Palette helpers ────────────────────────────────────────────────────────
class _NC {
  static const emerald   = Color(0xFF2D6A4F);
  static const forest    = Color(0xFF1B4332);
  static const mid       = Color(0xFF40916C);
  static const mint      = Color(0xFF52B788);
  static const pale      = Color(0xFF95D5B2);
  static const fog       = Color(0xFFD8F3DC);
  static const bark      = Color(0xFF774936);
  static const soil      = Color(0xFF9C6644);
  static const amber     = Color(0xFFF4A261);
  static const flame     = Color(0xFFE76F51);
  static const sunlight  = Color(0xFFFFF3B0);
  static const stone     = Color(0xFF8A8A8A);
  static const redAlert  = Color(0xFFE63946);
  static const goldBadge = Color(0xFFF4C430);
}

// ─── Root screen ────────────────────────────────────────────────────────────
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final tasks  = ref.watch(tasksProvider);
    final notes  = ref.watch(notesProvider);

    final total     = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final rate      = total == 0 ? 0.0 : completed / total;
    final high      = tasks.where((t) => t.priority == Priority.high).length;
    final medium    = tasks.where((t) => t.priority == Priority.medium).length;
    final low       = tasks.where((t) => t.priority == Priority.low).length;

    // Derived insight values
    final velocity   = total == 0 ? 0.0 : completed / 7.0;
    final momentum   = (rate * 60 + min(velocity, 5) * 8).clamp(0, 100).toInt();
    final pinnedNotes = notes.where((n) => n.isPinned).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F16) : const Color(0xFFF0F7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _Header(isDark: isDark)
                  .animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0),

              const SizedBox(height: 20),

              // ── Streak banner ──
              _StreakBanner(isDark: isDark)
                  .animate().fadeIn(delay: 80.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── AI Insights panel ──
              _AIInsightsPanel(isDark: isDark, rate: rate, velocity: velocity)
                  .animate().fadeIn(delay: 140.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── 3-metric row ──
              _MetricRow(
                isDark: isDark,
                completionPct: (rate * 100).toInt(),
                completed: completed,
                total: total,
                velocity: velocity,
                noteCount: notes.length,
                pinnedCount: pinnedNotes,
              ).animate().fadeIn(delay: 180.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── Charts row: weekly + time-of-day ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _WeeklyRhythmCard(isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _TimeOfDayCard(isDark: isDark)),
                ],
              ).animate().fadeIn(delay: 220.ms, duration: 450.ms),

              const SizedBox(height: 14),

              // ── Priority breakdown ──
              _PriorityBreakdown(
                isDark: isDark,
                high: high, medium: medium, low: low, total: total,
              ).animate().fadeIn(delay: 270.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── Donut + Overdue risk ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DonutCard(isDark: isDark, completed: completed, total: total, rate: rate)),
                  const SizedBox(width: 12),
                  Expanded(child: _OverdueRiskCard(isDark: isDark)),
                ],
              ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── Momentum score ──
              _MomentumCard(isDark: isDark, score: momentum)
                  .animate().fadeIn(delay: 360.ms, duration: 400.ms),

              const SizedBox(height: 14),

              // ── Activity heatmap ──
              _HeatmapCard(isDark: isDark)
                  .animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth Stats',
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
            color: isDark ? _NC.pale : _NC.forest,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Your productivity garden 🌱',
          style: TextStyle(fontSize: 13, color: isDark ? _NC.mint.withOpacity(0.55) : _NC.stone),
        ),
      ],
    );
  }
}

// ─── Streak banner ───────────────────────────────────────────────────────────
class _StreakBanner extends StatelessWidget {
  final bool isDark;
  const _StreakBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A40), Color(0xFFFF4D4D)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 24))),
          ).animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(1,1), end: const Offset(1.08,1.08), duration: 1.seconds, curve: Curves.easeInOut)
            .then()
            .scale(begin: const Offset(1.08,1.08), end: const Offset(1,1), duration: 1.seconds, curve: Curves.easeInOut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-day streak — personal best',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Avg 4.8 tasks/day · 92nd percentile',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              const Text('7', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1)),
              Text('days', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── AI Insights panel ───────────────────────────────────────────────────────
class _AIInsightsPanel extends StatelessWidget {
  final bool isDark;
  final double rate, velocity;
  const _AIInsightsPanel({required this.isDark, required this.rate, required this.velocity});

  @override
  Widget build(BuildContext context) {
    final insights = [
      'You complete ${(rate * 100).toInt()}% of tasks — ${rate >= 0.7 ? "great consistency! 🌿" : "let\'s push a bit harder 🌱"}',
      'Medium-priority tasks have a 2.4× higher skip rate. Try breaking them into smaller steps.',
      'Your completion rate rose +18% this week vs your 4-week average.',
    ];

    final borderColor = isDark ? const Color(0xFF0C447C) : const Color(0xFF185FA5);
    final bgColor     = isDark ? const Color(0xFF0A1929) : const Color(0xFFE6F1FB);
    final labelColor  = isDark ? const Color(0xFF85B7EB) : const Color(0xFF185FA5);
    final textColor   = isDark ? const Color(0xFFB5D4F4) : const Color(0xFF0C447C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, size: 13, color: labelColor),
            const SizedBox(width: 5),
            Text('AI INSIGHTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: labelColor)),
          ]),
          const SizedBox(height: 10),
          ...insights.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('·', style: TextStyle(fontSize: 18, color: labelColor, height: 0.9)),
                const SizedBox(width: 6),
                Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: textColor, height: 1.55))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── 3-metric row ────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  final bool isDark;
  final int completionPct, completed, total, noteCount, pinnedCount;
  final double velocity;
  const _MetricRow({
    required this.isDark, required this.completionPct,
    required this.completed, required this.total,
    required this.velocity, required this.noteCount, required this.pinnedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _SmallMetric(isDark: isDark, label: 'COMPLETION', value: '$completionPct%',
          sub: '$completed of $total', badge: '+12%', badgeUp: true)),
      const SizedBox(width: 10),
      Expanded(child: _SmallMetric(isDark: isDark, label: 'VELOCITY', value: velocity.toStringAsFixed(1),
          sub: 'tasks / day', badge: '+0.6', badgeUp: true)),
      const SizedBox(width: 10),
      Expanded(child: _SmallMetric(isDark: isDark, label: 'NOTES', value: '$noteCount',
          sub: '$pinnedCount pinned', badge: 'stable', badgeUp: null)),
    ]);
  }
}

class _SmallMetric extends StatelessWidget {
  final bool isDark;
  final String label, value, sub, badge;
  final bool? badgeUp; // null = neutral
  const _SmallMetric({required this.isDark, required this.label, required this.value,
      required this.sub, required this.badge, required this.badgeUp});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);

    Color badgeBg, badgeFg;
    if (badgeUp == null) {
      badgeBg = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);
      badgeFg = isDark ? Colors.white54 : Colors.black45;
    } else if (badgeUp!) {
      badgeBg = const Color(0xFFEAF3DE); badgeFg = const Color(0xFF3B6D11);
    } else {
      badgeBg = const Color(0xFFFCEBEB); badgeFg = const Color(0xFFA32D2D);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1,
            color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
          child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeFg)),
        ),
      ]),
    );
  }
}

// ─── Weekly rhythm chart ─────────────────────────────────────────────────────
class _WeeklyRhythmCard extends StatelessWidget {
  final bool isDark;
  const _WeeklyRhythmCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const days   = ['M','T','W','T','F','S','S'];
    const values = [3.0, 5.0, 4.0, 7.0, 6.0, 2.0, 4.0];

    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final grid   = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final tick   = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly rhythm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        const SizedBox(height: 2),
        Text('tasks per day', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 10,
            barTouchData: BarTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 18,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox();
                  return Text(days[i], style: TextStyle(fontSize: 10, color: tick));
                },
              )),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: values.asMap().entries.map((e) {
              final isToday = e.key == 3;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value, width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: isToday ? _NC.emerald : (isDark ? _NC.mid.withOpacity(0.5) : _NC.fog),
                ),
              ]);
            }).toList(),
          )),
        ),
      ]),
    );
  }
}

// ─── Time-of-day chart ───────────────────────────────────────────────────────
class _TimeOfDayCard extends StatelessWidget {
  final bool isDark;
  const _TimeOfDayCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const labels = ['Morn','Aft','Eve','Night'];
    const values = [14.0, 9.0, 6.0, 3.0];

    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final grid   = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final tick   = isDark ? Colors.white38 : Colors.black38;

    final barColors = [_NC.emerald, _NC.mid, _NC.mint, isDark ? _NC.fog.withOpacity(0.25) : _NC.fog];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Time of day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        const SizedBox(height: 2),
        Text('when you work', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 18,
            barTouchData: BarTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 18,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Text(labels[i], style: TextStyle(fontSize: 9, color: tick));
                },
              )),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: values.asMap().entries.map((e) => BarChartGroupData(
              x: e.key, barRods: [BarChartRodData(
                toY: e.value, width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                color: barColors[e.key],
              )],
            )).toList(),
          )),
        ),
      ]),
    );
  }
}

// ─── Priority breakdown ──────────────────────────────────────────────────────
class _PriorityBreakdown extends StatelessWidget {
  final bool isDark;
  final int high, medium, low, total;
  const _PriorityBreakdown({required this.isDark, required this.high,
      required this.medium, required this.low, required this.total});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
            borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Add tasks to see priority breakdown.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13))),
      );
    }

    // fake completion rates per tier (replace with real data when available)
    final highDone   = (high   * 0.81).round();
    final medDone    = (medium * 0.61).round();
    final lowDone    = (low    * 0.55).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Priority breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        Text('distribution & completion per tier',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 14),
        _PriorRow(isDark: isDark, label: 'High',   count: high,   done: highDone,
            fillColor: const Color(0xFFE74C3C), pct: high   / total),
        const SizedBox(height: 10),
        _PriorRow(isDark: isDark, label: 'Medium', count: medium, done: medDone,
            fillColor: const Color(0xFFF0A500), pct: medium / total),
        const SizedBox(height: 10),
        _PriorRow(isDark: isDark, label: 'Low',    count: low,    done: lowDone,
            fillColor: _NC.mint,                pct: low    / total),
      ]),
    );
  }
}

class _PriorRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final int count, done;
  final Color fillColor;
  final double pct;
  const _PriorRow({required this.isDark, required this.label, required this.count,
      required this.done, required this.fillColor, required this.pct});

  @override
  Widget build(BuildContext context) {
    final donePct = count == 0 ? 0 : ((done / count) * 100).toInt();
    final isGood  = donePct >= 70;

    return Row(children: [
      SizedBox(width: 58, child: Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: fillColor))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          minHeight: 7,
          backgroundColor: fillColor.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      )),
      const SizedBox(width: 10),
      SizedBox(width: 24, child: Text('$count', textAlign: TextAlign.end,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fillColor))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isGood ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$donePct%', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: isGood ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D),
        )),
      ),
    ]);
  }
}

// ─── Donut card ──────────────────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  final bool isDark;
  final int completed, total;
  final double rate;
  const _DonutCard({required this.isDark, required this.completed,
      required this.total, required this.rate});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final remaining = (total - completed).clamp(0, 9999);
    final pct = (rate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 26,
                sections: [
                  PieChartSectionData(value: rate * 100, color: _NC.emerald,
                      radius: 12, showTitle: false),
                  PieChartSectionData(
                      value: (1 - rate) * 100,
                      color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
                      radius: 12, showTitle: false),
                ],
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87)),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Legend(color: _NC.emerald, label: 'Done', value: '$completed'),
            const SizedBox(height: 6),
            _Legend(color: isDark ? Colors.white24 : Colors.black12,
                label: 'Left', value: '$remaining'),
            const SizedBox(height: 10),
            Container(height: 0.5, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 8),
            Text('vs last week', style: TextStyle(fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.trending_up_rounded, size: 13, color: const Color(0xFF3B6D11)),
              const SizedBox(width: 3),
              const Text('+18%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF3B6D11))),
            ]),
          ])),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label — $value', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

// ─── Overdue risk card ───────────────────────────────────────────────────────
class _OverdueRiskCard extends StatelessWidget {
  final bool isDark;
  const _OverdueRiskCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overdue risk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        Text('approaching deadline', style: TextStyle(fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 12),
        _RiskPill(isDark: isDark, icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFBA7517), text: '2 high-priority due today'),
        const SizedBox(height: 8),
        _RiskPill(isDark: isDark, icon: Icons.access_time_rounded,
            iconColor: isDark ? Colors.white38 : Colors.black38,
            text: '4 medium tasks overdue'),
        const SizedBox(height: 8),
        _RiskPill(isDark: isDark, icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF3B6D11), text: 'Low backlog looks healthy'),
      ]),
    );
  }
}

class _RiskPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String text;
  const _RiskPill({required this.isDark, required this.icon,
      required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87))),
      ]),
    );
  }
}

// ─── Momentum score card ──────────────────────────────────────────────────────
class _MomentumCard extends StatelessWidget {
  final bool isDark;
  final int score;
  const _MomentumCard({required this.isDark, required this.score});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final grid   = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    final label  = score >= 80 ? 'Great week 🌿' : score >= 60 ? 'Solid progress' : 'Keep going 🌱';

    final sparkData = [62.0, 70.0, 65.0, 78.0, 74.0, score.toDouble()];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Momentum score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        Text('AI-calculated weekly index', style: TextStyle(fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
          Text('$score', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w600, height: 1,
              color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(width: 8),
          Text('/ 100  ·  $label', style: TextStyle(fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black45)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: LineChart(LineChartData(
            minY: 50, maxY: 100,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
            ),
            titlesData: const FlTitlesData(
              leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [LineChartBarData(
              spots: sparkData.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true, curveSmoothness: 0.35,
              color: _NC.emerald,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: _NC.emerald.withOpacity(0.08),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                  radius: i == sparkData.length - 1 ? 4 : 0,
                  color: _NC.emerald,
                  strokeColor: _NC.emerald,
                  strokeWidth: 0,
                ),
              ),
            )],
          )),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('6 weeks ago', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
          Text('now', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
        ]),
      ]),
    );
  }
}

// ─── Heatmap card ────────────────────────────────────────────────────────────
class _HeatmapCard extends StatelessWidget {
  final bool isDark;
  const _HeatmapCard({required this.isDark});

  static const _levels = [
    0,1,2,1,3,2,0,1,3,2,3,2,1,2,2,
    2,3,3,2,1,0,1,2,3,3,3,2,1,2,3,
    3,2,1,3,3,
  ];

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF0D1F16) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final empty  = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);

    final palette = [empty, _NC.fog, _NC.mint, _NC.emerald];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('5-week activity heatmap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? _NC.pale : _NC.forest)),
        Text('daily task completion intensity', style: TextStyle(fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (ctx, c) {
          final cellSize = (c.maxWidth - (34 * 3)) / 35;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(35, (i) {
              final lv = _levels[i % _levels.length];
              return Container(
                width: cellSize, height: cellSize,
                decoration: BoxDecoration(
                  color: palette[lv], borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Less', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(width: 5),
          ...([
            isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
            _NC.fog, _NC.mint, _NC.emerald,
          ].map((c) => Container(
            width: 11, height: 11, margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ))),
          const SizedBox(width: 5),
          Text('More', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
        ]),
      ]),
    );
  }
}