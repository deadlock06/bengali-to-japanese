// Bhasago — Progress screen + AI progress-check screen (v4 design). Step 5.
//
// Two screens in one file (they ship together):
//   ProgressScreenV4 — level chips (N5→N4→JFT-A2), live retention chart,
//                      skill blocks (green listening / pink speaking)
//   AiCheckScreen    — blue examiner card, mock exam, chart reaction,
//                      real-time Banglish suggestion
//
// Wiring:
//  - Drop into lib/presentation/progress_screen_v4.dart
//  - main.dart (step 3): tab 3 → ProgressScreenV4(); the stubbed
//    onOpenAiCheck → AiCheckScreen()
//  - Data: retentionSeriesProvider below reads SrsLocal.reviewHistory().
//    Until T-108 lands a real query, it falls back to a demo series.
//
// Correctness model (00 non-negotiables): the "AI examiner" NEVER grades by
// LLM judgment. The mock exam samples items from verified content and checks
// answers against the content answer key; the LLM (when attached) only
// phrases the Banglish suggestion. Grading = answer key. Always.
//
// D-001: fail state is neutral feedback (chart dips, suggestion says what to
// practice). No shame copy, no locks, no streak threats.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';

/// Daily retention % for the chart. TODO(T-108): implement
/// SrsLocal.retentionByDay() → SELECT day, avg(grade>=good) FROM
/// review_history GROUP BY day. Demo series until then.
final retentionSeriesProvider = FutureProvider<List<double>>((ref) async {
  final daily = await ref.read(srsProvider).retentionByDay(20); // 0..1 per day
  final pct = daily.map((r) => r * 100).toList();
  // Handoff demo fallback: a brand-new user has no review history (all zeros) —
  // keep the chart alive until real reviews land, then show real data.
  if (pct.every((v) => v == 0)) {
    return const [58, 60, 59, 62, 64, 63, 66, 65, 68, 70, 69, 72];
  }
  return pct;
});

// ═══════════════════════════════ PROGRESS ═══════════════════════════════

class ProgressScreenV4 extends ConsumerWidget {
  final VoidCallback onOpenAiCheck;
  const ProgressScreenV4({super.key, required this.onOpenAiCheck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final series = ref.watch(retentionSeriesProvider).valueOrNull;

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
        // level chips — active = ink-filled, goal = pink (styleguide chips)
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _LevelChip(label: 'N5 · 72%', style: _ChipStyle.active),
            _LevelChip(label: 'N4', style: _ChipStyle.idle),
            _LevelChip(label: 'JFT-A2 goal', style: _ChipStyle.goal),
            _LevelChip(label: 'SSW পথ', style: _ChipStyle.idle),
          ],
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
                      ? const Center(child: CircularProgressIndicator())
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
        // skill blocks — green + pink accent cards
        const Row(
          children: [
            Expanded(
              child: _SkillBlock(
                color: BhasagoColors.green,
                label: 'শোনা',
                pct: 55, // TODO(T-108): per-skill accuracy from review_history
                sparkline: true,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SkillBlock(
                color: BhasagoColors.pink,
                label: 'বলা',
                pct: 32, // TODO: avg accentScore() from pitch sessions
                sparkline: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════ AI CHECK ═══════════════════════════════

class AiCheckScreen extends ConsumerStatefulWidget {
  const AiCheckScreen({super.key});
  @override
  ConsumerState<AiCheckScreen> createState() => _AiCheckScreenState();
}

enum _ExamState { idle, checking, passed, failed }

class _AiCheckScreenState extends ConsumerState<AiCheckScreen> {
  _ExamState _exam = _ExamState.idle;
  String _suggestion =
      'Tumi valo pace e aso! Mock exam dile ami bole dibo kon section e '
      'focus korte hobe. Kono pressure nai — ready hole start koro.';

  Future<void> _runExam() async {
    setState(() => _exam = _ExamState.checking);
    // TODO: real mock exam — sample N items from verified content packs,
    // grade against the content answer key (NEVER LLM judgment), then compute
    // pass = score >= passMark. Suggestion text = weak-skill template filled
    // from the per-skill error counts (LLM may rephrase, offline template ok).
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final passed = DateTime.now().millisecond.isEven; // demo only
    setState(() {
      _exam = passed ? _ExamState.passed : _ExamState.failed;
      _suggestion = passed
          ? 'Darun cholcheho! Tumi A2 er pothe thik ase. Listening ta aro '
              'strong koro — protidin 10 min shadowing korle N4 er kotha bujha '
              'easy hobe. Kana 64% — "ra" row ta revise koro!'
          : 'Mon kharap koro na — pass mark er ektu niche chile. Speaking e '
              '32%, eta e beshi mark kata gese. Ajke 15 min shadowing + kalke '
              'abar try koro. Vocabulary daily review koro!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // blue examiner card
        Card(
          color: BhasagoColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF111111),
                    child: Icon(Icons.psychology,
                        size: 18, color: BhasagoColors.blue),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI এক্সামিনার',
                          style: text.titleMedium
                              ?.copyWith(color: const Color(0xFF111111))),
                      Text('JFT-BASIC A2 · MOCK',
                          style: text.labelSmall?.copyWith(
                              color: BhasagoColors.blueDim,
                              letterSpacing: 1.6)),
                    ],
                  ),
                ]),
                const SizedBox(height: 11),
                switch (_exam) {
                  _ExamState.idle => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'তোমার শেখা data দেখে ছোট মক এক্সাম নেব। পাস করলে '
                          'চার্ট উঠবে, না টিকলে নামবে — আর বলে দেব কোথায় কাজ '
                          'করতে হবে।',
                          style: text.bodySmall
                              ?.copyWith(color: BhasagoColors.blueDim),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF111111),
                            foregroundColor: BhasagoColors.ink,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _runExam,
                          child: const Text('মক এক্সাম শুরু করো'),
                        ),
                      ],
                    ),
                  _ExamState.checking => Row(children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Color(0xFF111111))),
                      const SizedBox(width: 10),
                      Text('AI বিশ্লেষণ করছে…',
                          style: text.bodyMedium
                              ?.copyWith(color: const Color(0xFF111111))),
                    ]),
                  _ExamState.passed => _AlertRow(
                      bg: const Color(0xFFDEF7E5),
                      dot: BhasagoColors.success,
                      icon: Icons.check,
                      textColor: const Color(0xFF0B3D20),
                      message: 'পাস! স্কোর +৬ — A2 আরও কাছে।',
                      onRetry: _runExam,
                    ),
                  _ExamState.failed => _AlertRow(
                      bg: const Color(0xFFFBE3EF),
                      dot: BhasagoColors.error,
                      icon: Icons.priority_high,
                      textColor: const Color(0xFF5C1136),
                      message: 'এবার হয়নি — চার্ট −১৪। নিচের পরামর্শ দেখো।',
                      onRetry: _runExam,
                    ),
                },
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Banglish suggestion — yellow card
        Card(
          color: BhasagoColors.yellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates,
                      size: 16, color: Color(0xFF111111)),
                  const SizedBox(width: 7),
                  Text('REAL-TIME SUGGESTION',
                      style: text.labelSmall?.copyWith(
                          color: const Color(0xFF111111), letterSpacing: 1.4)),
                ]),
                const SizedBox(height: 7),
                // Banglish register (BN + English loanwords) — spec-aligned.
                Text(_suggestion,
                    style: text.bodySmall?.copyWith(
                        color: const Color(0xFF111111), height: 1.6)),
              ],
            ),
          ),
        ),
      ],
    );
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
  final int pct;
  final bool sparkline;
  const _SkillBlock(
      {required this.color,
      required this.label,
      required this.pct,
      required this.sparkline});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
            child: sparkline
                ? const CustomPaint(
                    painter: RetentionChartPainter(
                        [20, 16, 18, 10, 13, 6, 9],
                        line: Color(0xFF111111),
                        thin: true))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in const [0.3, 0.45, 0.35, 0.6, 0.5]) ...[
                        Expanded(
                            child: FractionallySizedBox(
                          heightFactor: h,
                          child: Container(
                              decoration: const BoxDecoration(
                                  color: Color(0xFF111111),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(3)))),
                        )),
                        const SizedBox(width: 4),
                      ]
                    ],
                  ),
          ),
          const SizedBox(height: 4),
          Text('$pct%',
              style: text.titleMedium?.copyWith(color: const Color(0xFF111111))),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Color bg, dot, textColor;
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  const _AlertRow(
      {required this.bg,
      required this.dot,
      required this.icon,
      required this.textColor,
      required this.message,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          CircleAvatar(
              radius: 8,
              backgroundColor: dot,
              child: Icon(icon, size: 11, color: Colors.white)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColor))),
        ]),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF111111), width: 1.5),
            foregroundColor: const Color(0xFF111111),
            minimumSize: const Size.fromHeight(44)),
        onPressed: onRetry,
        child: const Text('আবার চেষ্টা করো'),
      ),
    ]);
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
