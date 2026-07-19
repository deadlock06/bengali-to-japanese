// Bhasago — app entry point (v4 "Bold Ink" shell). Step 3 of the design handoff.
//
// Changes vs v0.1 main.dart:
//  - 4-tab NavigationBar: Home / Learn / Speak / Progress (was 6 flat tabs)
//  - HomeScreen (step 2) is tab 0; Kana, Writing, Pitch, Review are reached
//    by push from Home cards / the Learn tab — not top-level tabs
//  - AppBar removed on Home (design has its own greeting header); kept on
//    pushed pages for back navigation
//  - Locale + theme wiring unchanged (localeProvider, BhasagoTheme.dark())
//
// Wiring: replace lib/main.dart with this AFTER steps 1-2 are in place.
// Steps 4 (onboarding gate) and 5 (ProgressScreenV4) are wired in below.
// The "AI চেক" entry points open the real deterministic MockExamScreen
// (answer-key graded) — never an LLM/coin-flip grader.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'agents/agent_state.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'presentation/home_screen.dart';
import 'presentation/screens.dart';
import 'presentation/accent_screens.dart';
import 'presentation/journey_map_screen.dart';
import 'presentation/roleplay_entry.dart';
import 'presentation/book_screen_v4.dart';
import 'presentation/lesson_screen_v4.dart';
import 'presentation/mock_exam_screen.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/progress_screen_v4.dart';
import 'presentation/settings_screen.dart';
import 'presentation/dictionary_screen.dart';
import 'presentation/vocab_screen.dart';
import 'presentation/selection_explain.dart';
import 'presentation/writing_screen.dart';
import 'data/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prepare OPTIONAL cloud sync (D1) — no-op until the user opts in. Never
  // blocks startup; offline-first is untouched.
  await SyncService.instance.init();
  runApp(const ProviderScope(child: SenseiApp()));
}

class SenseiApp extends ConsumerWidget {
  const SenseiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // Step 4: first-run language-select gate. null = prefs still loading
    // (sub-frame blank screen, then straight into the right home).
    final chosen = ref.watch(localeChosenProvider).valueOrNull;
    return MaterialApp(
      title: 'Bhasago',
      debugShowCheckedModeBanner: false,
      // Root navigator key — lets the in-screen selection toolbar open the
      // explain sheet on the right overlay (see SelectionExplain).
      navigatorKey: appNavigatorKey,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('bn'), Locale('ja')],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: BhasagoTheme.dark(),
      home: chosen == null
          ? const Scaffold(body: SizedBox.shrink())
          : chosen
              ? const HomeShell()
              : OnboardingScreen(
                  onDone: () => ref.invalidate(localeChosenProvider)),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    // Boot carry-overs (00 §5 + 04): honour an elapsed 7-day deletion grace,
    // then restore the learner's persisted persona into the agent bus.
    Future.microtask(() async {
      try {
        final srs = ref.read(srsProvider);
        final requested = await srs.deletionRequestedAt();
        if (requested != null &&
            DateTime.now().difference(requested).inDays >= 7) {
          await srs.purgeAllData();
        }
        final saved = await srs.getMeta('persona');
        if (saved != null && mounted) {
          for (final p in PersonaType.values) {
            if (p.name == saved) {
              ref.read(agentBusProvider.notifier).setPersona(p);
              break;
            }
          }
        }
      } catch (_) {/* off-device DB (widget tests) — defaults apply */}
    });
  }

  void _push(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: body,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Tab bodies. Home gets callbacks so it never touches Navigator directly.
    final pages = <Widget>[
      HomeScreen(
        // AI Classroom → the sensei classroom, which teaches the current unit
        // (kana recognition first, then vocab). Kana WRITING practice stays
        // available via the Home ✍️ AppBar action.
        onOpenLesson: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const LessonScreenV4())),
        onOpenReview: () =>
            _push(context, s.navReview, const ReviewScreen()),
        onOpenAiCheck: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const MockExamScreen(kind: 'jft'))),
        onOpenProgress: () => setState(() => tab = 3),
        // Book has its own header/back — plain push, no _push scaffold.
        onOpenBook: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BookScreenV4())),
        onOpenLearn: () => setState(() => tab = 1), // design: goLearn
      ),
      const JourneyMapScreen(),
      // Speak tab: roleplay (C2 — the conversation corner) + shadowing + pitch.
      Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: RoleplayEntryCard(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Material(
            color: BhasagoTheme.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: BhasagoTheme.outline)),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _push(context, 'উচ্চারণ · Pitch', const PitchScreen()),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(children: [
                  Icon(Icons.graphic_eq, size: 20, color: BhasagoTheme.muted),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('পিচ অ্যাকসেন্ট অনুশীলন',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5))),
                  Icon(Icons.chevron_right, size: 20, color: BhasagoTheme.muted),
                ]),
              ),
            ),
          ),
        ),
        const Expanded(child: ShadowingScreen()),
      ]),
      ProgressScreenV4(
        onOpenAiCheck: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const MockExamScreen(kind: 'jft'))),
      ),
    ];

    return Scaffold(
      // Design: Home has its own header; other tabs keep a slim AppBar.
      appBar: tab == 0
          ? AppBar(
              title: const Text('Bhasago'),
              actions: [
                // Vocabulary bank — browse/search every word + learning status.
                IconButton(
                  icon: const Icon(Icons.style_outlined),
                  tooltip: 'শব্দভাণ্ডার · Vocabulary',
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VocabScreen())),
                ),
                // AI dictionary — explain any copied/typed Japanese text.
                IconButton(
                  icon: const Icon(Icons.translate),
                  tooltip: 'AI অভিধান · Dictionary',
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DictionaryScreen())),
                ),
                // Kana grid + writing practice moved off the tab bar (v4):
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  tooltip: s.kanaTitle,
                  onPressed: () =>
                      _push(context, s.kanaTitle, const KanaScreen()),
                ),
                IconButton(
                  icon: const Icon(Icons.draw),
                  tooltip: 'লিখো · Write',
                  onPressed: () =>
                      _push(context, 'লিখো · Write', const WritingScreen()),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'সেটিংস · Settings',
                  onPressed: () => _push(
                      context, 'সেটিংস · Settings', const SettingsScreen()),
                ),
              ],
            )
          : null,
      // Design "Japanese 3D depth field": red sun + seigaiha waves + floating
      // kana behind every tab. Purely ambient; reduced-motion freezes it.
      body: Stack(fit: StackFit.expand, children: [
        const Positioned.fill(child: _DepthField()),
        // Select any text in the tabs → the sensei appears to explain it.
        SelectionExplain(child: pages[tab]),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'হোম'),
          NavigationDestination(icon: const Icon(Icons.school_outlined), label: s.navLearn),
          NavigationDestination(icon: const Icon(Icons.mic_none), label: s.navSpeak),
          const NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined), label: 'অগ্রগতি'),
        ],
      ),
    );
  }
}

/// Home v4 design backdrop — "Japanese 3D depth field": pulsing red sun
/// (top-right), seigaiha wave arcs (bottom), three faint floating kana.
/// One slow loop; still under reduced-motion (accessibility gate).
class _DepthField extends StatefulWidget {
  const _DepthField();
  @override
  State<_DepthField> createState() => _DepthFieldState();
}

class _DepthFieldState extends State<_DepthField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 20));

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!reduce && !_loop.isAnimating) _loop.repeat();
    if (reduce && _loop.isAnimating) _loop.stop();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _DepthFieldPainter(t: reduce ? 0 : _loop.value),
        ),
      ),
    );
  }
}

class _DepthFieldPainter extends CustomPainter {
  _DepthFieldPainter({required this.t});
  final double t; // 0..1 master phase (0 = frozen)

  void _glyph(Canvas canvas, String ch, double x, double y, double fs,
      Color color, double dx, double dy) {
    final tp = TextPainter(
      text: TextSpan(
          text: ch,
          style: TextStyle(
              fontFamily: 'ZenKakuGothicNew',
              fontSize: fs,
              fontWeight: FontWeight.w900,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + dx, y + dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // red sun — sunPulse 7s (≈3 cycles per 20s loop)
    final pulse = math.sin(t * 3 * 2 * math.pi); // -1..1
    final sunR = 75.0 * (1 + .03 * pulse);
    final sunC = Offset(w + 34 - 75, 46 + 75);
    canvas.drawCircle(
      sunC, sunR,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFD84040).withValues(alpha: .30 + .04 * pulse),
          const Color(0xFFD84040).withValues(alpha: .09),
          Colors.transparent,
        ], stops: const [0, .62, .78])
            .createShader(Rect.fromCircle(center: sunC, radius: sunR)),
    );
    // seigaiha arcs above the nav area
    final wave = Paint()
      ..color = const Color(0xFFF5F5F0).withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final baseY = h - 54;
    for (final r in [40.0, 28.0]) {
      for (double cx = -20 + (r == 28 ? 12 : 0); cx < w + 60; cx += 80) {
        canvas.drawArc(Rect.fromCircle(center: Offset(cx + 40, baseY), radius: r),
            math.pi, math.pi, false, wave);
      }
    }
    // floating kana — float3d A/B as gentle offsets
    final a = math.sin(t * 2 * math.pi); // slow drift
    final b = math.sin(t * 2 * math.pi + math.pi / 2);
    _glyph(canvas, '語', 8, 120, 64,
        const Color(0xFFF5F5F0).withValues(alpha: .045), 6 * a, -14 * a.abs());
    _glyph(canvas, 'あ', w - 56, 300, 50,
        const Color(0xFFD84040).withValues(alpha: .07), -10 * b, 12 * b.abs());
    _glyph(canvas, 'ん', 20, h - 260, 40,
        const Color(0xFFF5F5F0).withValues(alpha: .04), 6 * b, -10 * b.abs());
  }

  @override
  bool shouldRepaint(_DepthFieldPainter old) => old.t != t;
}
