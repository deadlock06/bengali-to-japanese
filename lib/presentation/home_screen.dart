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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../data/curriculum_service.dart';
import '../data/lesson_batch.dart' show ClassroomBatch;
import 'progress_screen_v4.dart' show retentionSeriesProvider;
import 'sensei_chat_sheet.dart';
import 'voice_tutor_screen.dart';

/// Blood-red section ink — EXCLUSIVE to the AI Classroom surface (do not reuse).
const _aiClassroomRed = Color(0xFFB3121B);

String _bnDigits(int n) =>
    n.toString().split('').map((d) => '০১২৩৪৫৬৭৮৯'[int.parse(d)]).join();

/// Callbacks let the shell own navigation (no Navigator coupling here).
class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenLesson;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenAiCheck;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenLearn;
  final VoidCallback? onOpenVoiceTutor;
  const HomeScreen({
    super.key,
    required this.onOpenLesson,
    required this.onOpenReview,
    required this.onOpenAiCheck,
    required this.onOpenProgress,
    required this.onOpenBook,
    required this.onOpenLearn,
    this.onOpenVoiceTutor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE: strings are hardcoded BN for design parity; a later step moves
    // them to lib/l10n ARB keys (S.homeGreeting etc.) + BilingualText.
    final text = Theme.of(context).textTheme;
    // Course % = mean unit progress from the live curriculum ladder (T-120).
    // 0 for a fresh learner; demo-free.
    final lang = ref.watch(langProvider);
    final units = ref.watch(curriculumProvider).valueOrNull;
    final coursePct = (units == null || units.isEmpty)
        ? 0.0
        : units.fold<double>(0, (a, u) => a + u.pct) / units.length;
    final pctLabel = '${_bnDigits((coursePct * 100).round())}%';
    // Design top row + greeting personalisation (Home v4 userName prop).
    final name = ref.watch(userNameProvider).valueOrNull ?? 'রাফি';
    // Red card mirrors the CURRENT curriculum unit (design lessonTitle + 64%).
    CurriculumUnit? current;
    for (final u in units ?? const <CurriculumUnit>[]) {
      if (u.state == UnitProgress.current) { current = u; break; }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // ── top row: language pill + avatar (design chrome) ─────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _LangPill(),
            Container(
              width: 34, height: 34, alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: BhasagoColors.yellow, shape: BoxShape.circle),
              child: Text(name.isEmpty ? '?' : name.characters.first,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF111111))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── greeting + course progress ──────────────────────────────────
        Text('হাই, $name', style: text.headlineMedium),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('কোর্স অগ্রগতি', style: text.bodySmall),
            Text(pctLabel, style: text.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: coursePct,
            minHeight: 8,
            backgroundColor: const Color(0xFF262626),
            color: BhasagoColors.ink,
          ),
        ),
        const SizedBox(height: 14),

        // ── AI Classroom card (flagship, blood-red section ink) ─────────
        // Design: spinning 4-point star top-right; subtitle = current unit;
        // #111 progress pill w/ white fill + red knob; WHOLE card taps.
        // Director "what next" (02/04): a kana unit opens the kana screen (so a
        // beginner meets hiragana first), a vocab unit opens the classroom.
        _AccentCard(
          color: _aiClassroomRed,
          // Always opens the sensei classroom — which itself teaches the current
          // unit (kana recognition first, then vocab). One consistent AI-tutor
          // experience, never a bare tool.
          onTap: onOpenLesson,
          child: Stack(children: [
            const Positioned(top: 0, right: 0, child: _SpinStar()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI ক্লাসরুম',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                        color: const Color(0xFFF5F5F0),
                        fontWeight: FontWeight.w800)),
                Padding(
                  padding: const EdgeInsets.only(right: 38),
                  child: Text(current?.title.of(lang) ?? 'কনবিনিতে কেনাকাটা — Can-do',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall
                          ?.copyWith(color: const Color(0xFFF5B8BC))),
                ),
                const SizedBox(height: 12),
                _SliderProgress(value: current?.pct ?? 0),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Voice Tutor card ("Gemini Live" style) ─────────────────────────
        _VoiceTutorCard(
          onTap: onOpenVoiceTutor ??
              () => Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const VoiceTutorScreen())),
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
                            _MiniRetention(),
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

        // ── book entry (rev-3 §2: mini cover + progress, green section) ──
        _BookEntryCard(onTap: onOpenBook),
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
              onPressed: onOpenLearn, // design: goLearn (Learn tab)
              child: Text('সব দেখো', style: text.bodySmall),
            ),
          ],
        ),
        SizedBox(
          height: 96,
          child: units == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  scrollDirection: Axis.horizontal,
                  // REAL topics from the curriculum ladder — level chip, title,
                  // and live per-unit % (never fabricated). Colours cycle.
                  children: [
                    for (final (i, u) in units.indexed)
                      _TopicCard(
                        jp: u.level,
                        label: u.title.of(lang).isEmpty ? u.id : u.title.of(lang),
                        pct: u.pct,
                        color: const [
                          BhasagoColors.yellow,
                          BhasagoColors.green,
                          BhasagoColors.pink,
                          BhasagoColors.blue,
                        ][i % 4],
                        onTap: onOpenLearn,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // ── AI sensei outline pill (design: pulsing dot + typed greeting) ─
        _SenseiPill(),
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
          // Fixed 3-row list as a plain Column — a scrollable (ListView) here
          // is illegal under the IntrinsicHeight the card grid uses (it can't
          // compute a viewport's intrinsic height). Rows sit at the top; the
          // Spacer pushes "see all" to the bottom of the stretched card.
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
          const Spacer(),
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

/// Design progress pill: #111 track, #F5F5F0 fill, red knob (#111 ring)
/// riding the fill's right edge.
class _SliderProgress extends StatelessWidget {
  final double value;
  const _SliderProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final fillW = ((w - 8) * value.clamp(0.0, 1.0)).clamp(18.0, w - 8);
        return Stack(clipBehavior: Clip.none, children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Positioned(
            left: 4, top: 4,
            child: Container(
              width: fillW, height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            left: 4 + fillW - 13, top: 0,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: _aiClassroomRed,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF111111), width: 3),
              ),
            ),
          ),
        ]);
      }),
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


/// Design top row: outline pill cycling bn→en→ja, persisted like onboarding.
class _LangPill extends ConsumerWidget {
  const _LangPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider).languageCode;
    const labels = {'bn': 'বাংলা', 'en': 'English', 'ja': '日本語'};
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFF3A3A3A))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          const order = ['bn', 'en', 'ja'];
          final next = order[(order.indexOf(code) + 1) % 3];
          ref.read(localeProvider.notifier).state = Locale(next);
          final p = await SharedPreferences.getInstance();
          await p.setString('locale_chosen', next);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(labels[code] ?? 'বাংলা',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 15, color: BhasagoColors.inkDim),
          ]),
        ),
      ),
    );
  }
}

/// Design starSpin: 4-point white star, 5s rotate ±12° + scale breathe.
/// Static under reduced-motion.
class _SpinStar extends StatefulWidget {
  const _SpinStar();
  @override
  State<_SpinStar> createState() => _SpinStarState();
}

class _SpinStarState extends State<_SpinStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!reduce && !_c.isAnimating) _c.repeat();
    if (reduce && _c.isAnimating) _c.stop();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = (1 + math.sin(_c.value * 2 * math.pi)) / 2; // 0..1..0
        return Transform.rotate(
          angle: reduce ? 0 : 12 * math.pi / 180 * t,
          child: Transform.scale(scale: reduce ? 1 : 1 + .08 * t, child: child),
        );
      },
      child: const CustomPaint(size: Size(34, 34), painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 34;
    final p = Path()
      ..moveTo(17 * s, 0)..lineTo(20 * s, 13 * s)..lineTo(33 * s, 17 * s)
      ..lineTo(20 * s, 21 * s)..lineTo(17 * s, 34 * s)..lineTo(14 * s, 21 * s)
      ..lineTo(1 * s, 17 * s)..lineTo(14 * s, 13 * s)..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFF5F5F0));
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// Green card sparkline on the LIVE retention series (falls back to the
/// design's demo shape only while loading).
class _MiniRetention extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(retentionSeriesProvider).valueOrNull;
    final vals = (series == null || series.length < 2)
        ? const [58.0, 62.0, 60.0, 66.0, 65.0, 70.0, 72.0]
        : series.sublist(math.max(0, series.length - 8))
            .map((v) => v * 100).toList();
    return CustomPaint(
      size: const Size(double.infinity, 26),
      painter: _SparklinePainter(vals),
    );
  }
}

/// Voice Tutor entry card — "সেনসেইয়ের সাথে কথা বলো" (Gemini Live style).
/// Deep purple/blue gradient, pulsing mic ring — visually distinct from the
/// blood-red Classroom card.
class _VoiceTutorCard extends StatefulWidget {
  const _VoiceTutorCard({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_VoiceTutorCard> createState() => _VoiceTutorCardState();
}

class _VoiceTutorCardState extends State<_VoiceTutorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    const accent = Color(0xFF8B5CF6); // vivid purple
    const bg = Color(0xFF1A1130);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: .45), width: 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A1130), Color(0xFF0F0A20)],
            ),
          ),
          child: Row(children: [
            // Pulsing mic avatar
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final reduce = MediaQuery.of(context).disableAnimations;
                final t = _pulse.value;
                final ring = reduce ? 1.0 : 1.0 + 0.12 * math.sin(t * 2 * math.pi).abs();
                return Stack(alignment: Alignment.center, children: [
                  Transform.scale(
                    scale: ring,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(
                              alpha: reduce ? .3 : .2 + .3 * math.sin(t * 2 * math.pi).abs()),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: .18),
                      border: Border.all(color: accent, width: 1.8),
                      boxShadow: reduce ? [] : [
                        BoxShadow(
                          color: accent.withValues(alpha: .35),
                          blurRadius: 10, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, size: 20, color: accent),
                  ),
                ]);
              },
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  lang == 'en'
                      ? 'Talk with Sensei'
                      : lang == 'ja'
                          ? '先生と話す'
                          : 'সেনসেইয়ের সাথে কথা বলো',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                      color: const Color(0xFFF5F5F0), fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  lang == 'en'
                      ? 'Live AI conversation — learn to speak, step by step'
                      : lang == 'ja'
                          ? 'ライブAI会話 — 少しずつ話す練習'
                          : 'Live AI কথোপকথন — ধাপে ধাপে কথা বলা শেখো',
                  style: text.bodySmall?.copyWith(
                      fontSize: 11, color: accent.withValues(alpha: .8))),
            ])),
            Icon(Icons.chevron_right, size: 20, color: accent.withValues(alpha: .6)),
          ]),
        ),
      ),
    );
  }
}

/// Design "AI sensei" outline pill: pulsing green dot + greeting typed out
/// (30ms/2-char cadence). Tap opens live "Talk with Sensei" (D-042). The
/// greeting re-types automatically on batch-resolve and language switch;
/// reduced-motion shows full text / no pulse.
class _SenseiPill extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SenseiPill> createState() => _SenseiPillState();
}

class _SenseiPillState extends ConsumerState<_SenseiPill>
    with SingleTickerProviderStateMixin {
  String _shown = '';
  String _full = '';
  Timer? _timer;
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _greeting() =>
      _greetingText(ref.read(classroomBatchProvider).valueOrNull, ref.read(langProvider));

  /// The pill's typed line, localized (D-041). Falls back to a generic invite
  /// while the batch is still resolving.
  static String _greetingText(ClassroomBatch? batch, String lang) {
    final n = batch?.questions.length ?? 3;
    final title = batch?.titleBn ?? '';
    switch (lang) {
      case 'en':
        return batch == null
            ? "A few new words in today's lesson — talk with me?"
            : 'Today: "$title" — $n new words. Let\'s talk?';
      case 'ja':
        return batch == null
            ? '今日のレッスンに新しい言葉がいくつか — 話そう？'
            : '今日は「$title」— $n個の新しい言葉。話してみる？';
      default:
        return batch == null
            ? 'আজ লেসনে কয়েকটা নতুন শব্দ — একটু কথা বলি?'
            : 'আজ "$title" — ${_bnDigits(n)}টা নতুন শব্দ। কথা বলি?';
    }
  }

  void _type(bool reduce) {
    _timer?.cancel();
    _full = _greeting();
    if (reduce) {
      setState(() => _shown = _full);
      return;
    }
    var i = 0;
    setState(() => _shown = '');
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      i += 2;
      if (!mounted) { t.cancel(); return; }
      setState(() => _shown = _full.substring(0, math.min(i, _full.length)));
      if (i >= _full.length) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!reduce && !_pulse.isAnimating) _pulse.repeat();
    if (reduce && _pulse.isAnimating) _pulse.stop();
    // First fill (and refresh when the batch resolves or the language changes).
    final live = ref.watch(classroomBatchProvider).valueOrNull;
    final want = _greetingText(live, ref.watch(langProvider));
    if (_full != want && (_timer == null || !_timer!.isActive)) {
      // Never setState during build — type on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _full != want) _type(reduce);
      });
    }

    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(
          side: BorderSide(color: Color(0xFFF5F5F0), width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        // D-042: open live "Talk with Sensei" — free, online-AI-led spoken
        // sentence practice, sequenced by the teaching contract.
        onTap: () => showTalkSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Opacity(
                opacity: reduce
                    ? 1
                    : .25 + .75 *
                        math.sin(_pulse.value * math.pi).abs(),
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: BhasagoColors.green, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(_shown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward, size: 17, color: BhasagoColors.ink),
          ]),
        ),
      ),
    );
  }
}

/// Rev-3 §2: Home entry to the Bhasha Go book (green section ink).
class _BookEntryCard extends StatelessWidget {
  const _BookEntryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF35E065);
    final text = Theme.of(context).textTheme;
    return Material(
      color: BhasagoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BhasagoColors.outline)),
          child: Row(children: [
            Container( // 34×44 mini cover
              width: 34, height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D5B), Color(0xFF1F5C42)]),
              ),
              child: Row(children: [
                Container(width: 4, color: const Color(0xFF174632)),
                const Expanded(
                  child: Center(
                    child: Text('語', style: TextStyle(
                        fontFamily: 'ZenKakuGothicNew', fontSize: 15,
                        fontWeight: FontWeight.w900, color: Color(0xFFF5F5F0))),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ভাষা গো — বাংলায় জাপানি শেখো',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(color: BhasagoColors.ink)),
                const SizedBox(height: 2),
                Text('অধ্যায় ২ চলছে · ২২% পড়া হয়েছে',
                    style: text.bodySmall?.copyWith(fontSize: 11)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 20, color: green),
          ]),
        ),
      ),
    );
  }
}
