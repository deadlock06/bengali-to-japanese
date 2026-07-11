// Bhasago — Home screen (v4 "Bold Ink" design). Step 2 of the design handoff.
//
// Mirrors Home v4.dc.html: greeting + course progress, yellow current-lesson
// card, pink today's-review card (live due count from SrsLocal), blue AI-check
// card, green progress mini-chart, "this week's topics" scroll row.
//
// Wiring:
//  - Drop into lib/presentation/home_screen.dart
//  - Requires step1_theme.dart tokens (BhasagoColors.yellow/pink/blue/green…)
//  - main.dart: add HomeScreen() as tab 0 (step 3 rewires the shell)
//
// D-001 compliance: no streak warnings, no pressure copy. All numbers neutral.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';

/// Blood-red section ink — EXCLUSIVE to the AI Classroom surface (do not reuse).
const _aiClassroomRed = Color(0xFFB3121B);

/// Callbacks let the shell own navigation (no Navigator coupling here).
class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenLesson;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenAiCheck;
  final VoidCallback onOpenProgress;
  const HomeScreen({
    super.key,
    required this.onOpenLesson,
    required this.onOpenReview,
    required this.onOpenAiCheck,
    required this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE: strings are hardcoded BN for design parity; a later step moves
    // them to lib/l10n ARB keys (S.homeGreeting etc.) + BilingualText.
    final repo = ref.watch(contentProvider).valueOrNull;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // ── greeting + course progress ──────────────────────────────────
        Text('হাই!', style: text.headlineMedium), // TODO: user name provider
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('কোর্স অগ্রগতি', style: text.bodySmall),
            // TODO(T-108): real course % from review_history + lesson state
            Text('৬৪%', style: text.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            value: 0.64,
            minHeight: 8,
            backgroundColor: Color(0xFF262626),
            color: BhasagoColors.ink,
          ),
        ),
        const SizedBox(height: 14),

        // ── AI Classroom card (flagship, blood-red section ink) ─────────
        _AccentCard(
          color: _aiClassroomRed,
          onTap: onOpenLesson,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome,
                    size: 18, color: Color(0xFFF5F5F0)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('AI ক্লাসরুম',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                          color: const Color(0xFFF5F5F0),
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              Text('কনবিনিতে কেনাকাটা — Can-do',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: const Color(0xFFF5B8BC))),
              const SizedBox(height: 12),
              const _SliderProgress(value: 0.64),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: const Color(0xFFF5F5F0),
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: onOpenLesson,
                icon: const Icon(Icons.play_arrow,
                    size: 18, color: Color(0xFFF5F5F0)),
                label: const Text('ক্লাসে ঢোকো'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── color grid: pink review (tall) · blue AI check · green progress ─
        // Simple two-column layout; pink card spans both rows on the left.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _ReviewCard(onTap: onOpenReview)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _AccentCard(
                        color: BhasagoColors.blue,
                        onTap: onOpenAiCheck,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI চেক',
                                style: text.titleMedium?.copyWith(
                                    color: const Color(0xFF111111))),
                            Text('মক এক্সাম',
                                style: text.bodySmall?.copyWith(
                                    color: BhasagoColors.blueDim)),
                            const Spacer(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.psychology,
                                    size: 20, color: Color(0xFF111111)),
                                _Tag(label: 'A2'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _AccentCard(
                        color: BhasagoColors.green,
                        onTap: onOpenProgress,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('অগ্রগতি',
                                style: text.titleMedium?.copyWith(
                                    color: const Color(0xFF111111))),
                            Text('রিয়েল-টাইম',
                                style: text.bodySmall?.copyWith(
                                    color: BhasagoColors.greenDim)),
                            const Spacer(),
                            // TODO(T-108): sparkline from review_history
                            const CustomPaint(
                              size: Size(double.infinity, 26),
                              painter: _SparklinePainter(
                                  [58, 62, 60, 66, 65, 70, 72]),
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
        const SizedBox(height: 16),

        // ── this week's topics (See-all row) ────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text('এই সপ্তাহের টপিক',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium),
            ),
            TextButton(
              onPressed: onOpenLesson,
              child: Text('সব দেখো', style: text.bodySmall),
            ),
          ],
        ),
        SizedBox(
          height: 96,
          child: repo == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // TODO: derive from repo.lessons + per-lesson progress
                    _TopicCard(jp: 'かな', label: 'হিরাগানা', pct: 0.64, color: BhasagoColors.yellow, onTap: onOpenLesson),
                    _TopicCard(jp: '買い物', label: 'কেনাকাটা', pct: 0.42, color: BhasagoColors.green, onTap: onOpenLesson),
                    _TopicCard(jp: '挨拶', label: 'অভিবাদন', pct: 0.80, color: BhasagoColors.pink, onTap: onOpenLesson),
                    _TopicCard(jp: '仕事', label: 'কাজের ভাষা', pct: 0.18, color: BhasagoColors.blue, onTap: onOpenLesson),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── pieces ────────────────────────────────────────────────────────────────

class _AccentCard extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  const _AccentCard(
      {required this.color, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(13), child: child),
      ),
    );
  }
}

/// Pink "today's review" card with live due count from SrsLocal.
class _ReviewCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _ReviewCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final due = ref.watch(dueCountProvider).valueOrNull ?? 0;
    return _AccentCard(
      color: BhasagoColors.pink,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের রিভিউ',
              style: text.titleMedium?.copyWith(color: const Color(0xFF111111))),
          const SizedBox(height: 8),
          // Expanded + non-scrolling ListView: rows flex to the card height set
          // by IntrinsicHeight, so they never RenderFlex-overflow vertically.
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final row in const [
                  ('たべもの', '৩টা কার্ড'),
                  ('みず', 'আজ সকাল'),
                  ('ありがとう', 'গতকাল থেকে'),
                ]) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 5, right: 7),
                      decoration: const BoxDecoration(
                          color: Color(0xFF111111), shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Zen Kaku Gothic New',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111111))),
                            Text(row.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(
                                    fontSize: 10, color: BhasagoColors.pinkDim)),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Row(children: [
            Flexible(
              child: Text('$due' 'টি কার্ড দেখো',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111))),
            ),
            const Icon(Icons.arrow_forward, size: 13, color: Color(0xFF111111)),
          ]),
        ],
      ),
    );
  }
}

class _SliderProgress extends StatelessWidget {
  final double value;
  const _SliderProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(
            decoration: BoxDecoration(
              color: BhasagoColors.yellow,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Archivo',
              color: BhasagoColors.ink)),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String jp;
  final String label;
  final double pct;
  final Color color;
  final VoidCallback onTap;
  const _TopicCard(
      {required this.jp,
      required this.label,
      required this.pct,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: BhasagoColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              border: Border.all(color: BhasagoColors.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jp,
                    style: const TextStyle(
                        fontFamily: 'Zen Kaku Gothic New',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: BhasagoColors.ink)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(fontSize: 10)),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF262626),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  const _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : (max - min);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - ((values[i] - min) / span) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}
