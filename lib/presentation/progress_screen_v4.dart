// Bhasago — Progress screen (v4 design). Step 5.
//
//   ProgressScreenV4 — level chips (real per-level %), live retention chart,
//                      skill blocks (retention + completion, both real)
//
// Wiring:
//  - main.dart tab 3 → ProgressScreenV4(); onOpenAiCheck opens the real
//    deterministic MockExamScreen (answer-key graded, never LLM judgment).
//
// Correctness model (00 non-negotiables): NOTHING on this screen is invented.
// Every number is derived from real state — curriculum completion, the SRS
// review history — or shown as an honest empty state when there is no data
// yet. No demo series, no coin-flip exams, no fabricated skill percentages.
//
// D-001: fail/empty states are neutral (chart shows a next step, never shame).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../data/curriculum_service.dart';
import 'state_pack.dart';

/// Daily retention % for the chart, oldest → newest, from real review history
/// (SrsLocal.retentionByDay). A brand-new user has no reviews → all-zeros; the
/// UI then shows an honest empty state rather than inventing a trend
/// (correctness over generation, docs/00).
final retentionSeriesProvider = FutureProvider<List<double>>((ref) async {
  final daily = await ref.read(srsProvider).retentionByDay(20); // 0..1 per day
  return daily.map((r) => r * 100).toList();
});

// ═══════════════════════════════ PROGRESS ═══════════════════════════════

class ProgressScreenV4 extends ConsumerWidget {
  final VoidCallback onOpenAiCheck;
  const ProgressScreenV4({super.key, required this.onOpenAiCheck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final series = ref.watch(retentionSeriesProvider).valueOrNull;
    final units = ref.watch(curriculumProvider).valueOrNull;
    final goal = ref.watch(goalProvider).valueOrNull ?? '';

    // Real derived stats — never fabricated. Retention = avg over days that
    // actually had reviews; completion = mean unit progress across the ladder.
    final scored = series?.where((v) => v > 0).toList() ?? const [];
    final hasReviews = scored.isNotEmpty;
    final retentionAvg = hasReviews
        ? scored.reduce((a, b) => a + b) / scored.length
        : null;
    final overallPct = (units == null || units.isEmpty)
        ? null
        : units.map((u) => u.pct).reduce((a, b) => a + b) / units.length * 100;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Expanded(child: Text('তোমার অগ্রগতি', style: text.headlineSmall)),
            IconButton(
              icon: const Icon(Icons.psychology, color: BhasagoColors.green),
              tooltip: 'AI চেক',
              onPressed: onOpenAiCheck,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // level chips — REAL per-level completion; active = current level
        // (ink-filled), goal (from D-015 goalProvider) = pink.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _levelChips(units, goal),
        ),
        const SizedBox(height: 12),
        // live retention chart card
        Card(
          color: const Color(0xFF111111),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 14, 13, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('রিটেনশন স্কোর ২০২৬',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall),
                    ),
                    const _LiveDot(),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: series == null
                      ? const StatePack.loading()
                      : !hasReviews
                          ? const StatePack.empty(
                              title: 'রিভিউ শুরু করলে চার্ট আসবে',
                              body: 'কিছু কার্ড রিভিউ করলে এখানে তোমার '
                                  'রিটেনশন ট্রেন্ড দেখাবে।',
                              emoji: '📈')
                          : CustomPaint(
                              size: const Size(double.infinity, 120),
                              painter: RetentionChartPainter(series,
                                  line: BhasagoColors.green),
                            ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // skill blocks — BOTH real: retention (from review history) +
        // completion (from the curriculum ladder). No fabricated skill scores.
        Row(
          children: [
            Expanded(
              child: _SkillBlock(
                color: BhasagoColors.green,
                label: 'মনে রাখা',
                pct: retentionAvg?.round(),
                spark: hasReviews ? series : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SkillBlock(
                color: BhasagoColors.pink,
                label: 'সম্পন্ন',
                pct: overallPct?.round(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Real per-level chips from the curriculum ladder. The current level shows
  /// its live % and is ink-filled; other authored levels are idle; the chosen
  /// goal (D-015) is appended as a pink recommendation chip. Never invents a
  /// level or a percentage — falls back to a neutral placeholder while loading.
  List<Widget> _levelChips(List<CurriculumUnit>? units, String goal) {
    final chips = <Widget>[];
    if (units != null && units.isNotEmpty) {
      final order = <String>[];
      final byLevel = <String, List<CurriculumUnit>>{};
      String? current;
      for (final u in units) {
        if (!byLevel.containsKey(u.level)) order.add(u.level);
        (byLevel[u.level] ??= []).add(u);
        if (u.state == UnitProgress.current) current ??= u.level;
      }
      for (final lv in order) {
        final us = byLevel[lv]!;
        final pct =
            (us.map((u) => u.pct).reduce((a, b) => a + b) / us.length * 100)
                .round();
        final isCurrent = lv == current;
        chips.add(_LevelChip(
          label: isCurrent ? '$lv · $pct%' : lv,
          style: isCurrent ? _ChipStyle.active : _ChipStyle.idle,
        ));
      }
    }
    final goalLabel = switch (goal) {
      'ssw' => 'SSW লক্ষ্য',
      'jlpt' => 'JLPT লক্ষ্য',
      'daily' => 'দৈনিক লক্ষ্য',
      _ => null,
    };
    if (goalLabel != null) {
      chips.add(_LevelChip(label: goalLabel, style: _ChipStyle.goal));
    }
    if (chips.isEmpty) {
      chips.add(const _LevelChip(label: '…', style: _ChipStyle.idle));
    }
    return chips;
  }
}

// ═══════════════════════════════ pieces ══════════════════════════════════

enum _ChipStyle { active, idle, goal }

class _LevelChip extends StatelessWidget {
  final String label;
  final _ChipStyle style;
  const _LevelChip({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bd) = switch (style) {
      _ChipStyle.active => (BhasagoColors.ink, const Color(0xFF111111), BhasagoColors.ink),
      _ChipStyle.goal => (BhasagoColors.pink, const Color(0xFF111111), BhasagoColors.pink),
      _ChipStyle.idle => (Colors.transparent, BhasagoColors.inkDim, const Color(0xFF3A3A3A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bd, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'Archivo',
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: BhasagoColors.green, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      const Text('LIVE',
          style: TextStyle(
              fontSize: 9,
              fontFamily: 'Archivo',
              letterSpacing: 1.6,
              color: BhasagoColors.green)),
    ]);
  }
}

class _SkillBlock extends StatelessWidget {
  final Color color;
  final String label;

  /// The real metric, 0–100. null ⇒ no data yet → shows a neutral "—" and a
  /// flat track rather than a fabricated number (correctness over generation).
  final int? pct;

  /// Real series for the sparkline (e.g. the retention trend). null ⇒ render a
  /// simple progress bar filled to [pct].
  final List<double>? spark;
  const _SkillBlock(
      {required this.color, required this.label, this.pct, this.spark});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = spark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: text.titleSmall?.copyWith(color: const Color(0xFF111111))),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: (s != null && s.length >= 2)
                ? CustomPaint(
                    painter: RetentionChartPainter(s,
                        line: const Color(0xFF111111), thin: true))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (_, c) => Container(
                        height: 8,
                        width: c.maxWidth,
                        decoration: BoxDecoration(
                          color: const Color(0x33111111),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ((pct ?? 0) / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(pct == null ? '—' : '$pct%',
              style: text.titleMedium?.copyWith(color: const Color(0xFF111111))),
        ],
      ),
    );
  }
}

/// Line chart painter shared by the retention chart and sparklines.
class RetentionChartPainter extends CustomPainter {
  final List<double> values;
  final Color line;
  final bool thin;
  const RetentionChartPainter(this.values,
      {required this.line, this.thin = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : (max - min);
    Offset pt(int i) => Offset(
        i * size.width / (values.length - 1),
        size.height - ((values[i] - min) / span) * (size.height * 0.9) -
            size.height * 0.05);

    if (!thin) {
      // grid lines
      final grid = Paint()
        ..color = const Color(0xFF232323)
        ..strokeWidth = 1;
      for (final f in const [0.25, 0.5, 0.75]) {
        canvas.drawLine(Offset(0, size.height * f),
            Offset(size.width, size.height * f), grid);
      }
      // area fill
      final area = Path()..moveTo(0, size.height);
      for (var i = 0; i < values.length; i++) {
        area.lineTo(pt(i).dx, pt(i).dy);
      }
      area.lineTo(size.width, size.height);
      canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.08));
    }

    final paint = Paint()
      ..color = line
      ..strokeWidth = thin ? 2 : 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(path, paint);

    if (!thin) {
      canvas.drawCircle(pt(values.length - 1), 3.5, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(RetentionChartPainter old) =>
      old.values != values || old.line != line;
}
