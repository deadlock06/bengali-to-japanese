// New-learner end-to-end journey — drives the whole app the way a
// first-time user would, asserting every screen builds and the autonomy
// invariants hold. Run: flutter test test/user_journey_test.dart
//
// No pumpAndSettle anywhere: spinners and the agent strip animate forever.
// pumpUntil() polls with real 100ms pumps instead.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sensei_app/main.dart';
import 'package:sensei_app/presentation/lesson_screen_v4.dart';
import 'package:sensei_app/presentation/onboarding_screen.dart';

Future<void> pumpUntil(WidgetTester t, Finder f,
    {int tries = 50, String what = ''}) async {
  for (var i = 0; i < tries; i++) {
    if (f.evaluate().isNotEmpty) return;
    await t.pump(const Duration(milliseconds: 100));
  }
  fail('pumpUntil timed out waiting for $what ($f)');
}

void ok(WidgetTester t, String where) {
  final e = t.takeException();
  expect(e, isNull, reason: 'exception on $where: $e');
}

void main() {
  testWidgets('new learner: onboarding → every screen, no crashes',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // truly fresh install
    tester.view.physicalSize = const Size(720, 1640); // budget phone
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump();
    await tester.pump();

    // ── 1. First run: language-select onboarding ─────────────────────────
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget); // Bengali-first default
    // a curious user taps around before deciding
    await tester.tap(find.text('English').first);
    await tester.pump();
    await tester.tap(find.text('বাংলা').first);
    await tester.pump();
    await tester.tap(find.textContaining('চলো শুরু করি'));
    await tester.pump();
    await tester.pump();
    ok(tester, 'onboarding accept');

    // ── 2. Home (Bold Ink) ───────────────────────────────────────────────
    await pumpUntil(tester, find.textContaining('হাই'), what: 'home greeting');
    expect(find.text('AI ক্লাসরুম'), findsOneWidget); // red flagship card (rev-2)
    expect(find.text('আজকের রিভিউ'), findsOneWidget); // pink card
    expect(find.text('AI চেক'), findsOneWidget); // blue card
    expect(find.text('এই সপ্তাহের টপিক'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    ok(tester, 'home');

    // ── 3. Learn tab: full lesson catalogue from packs ───────────────────
    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pump();
    await pumpUntil(tester, find.textContaining('শব্দ · ৫ ধাপ'),
        what: 'lesson list tiles');
    expect(find.byType(ListTile), findsWidgets);
    ok(tester, 'lesson list');

    // ── 4. AI Classroom (adaptive lesson) via the red Home card ─────────
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.tap(find.text('AI ক্লাসরুম'));
    await tester.pump();
    await tester.pump();
    // Skip / Hint / Quit — always visible, always enabled (00 invariant)
    expect(find.text('ইঙ্গিত'), findsOneWidget, reason: 'Hint missing');
    expect(find.text('বাদ'), findsOneWidget, reason: 'Skip missing');
    expect(find.text('বন্ধ'), findsOneWidget, reason: 'Quit missing');
    // hesitant learner: hint on/off, wrong answer (→ struggle, D-001 neutral),
    // skip, then talk to the sensei, then quit
    await tester.tap(find.text('ইঙ্গিত'));
    await tester.pump();
    await tester.tap(find.text('ইঙ্গিত'));
    await tester.pump();
    await tester.tap(find.text('বাদ'));
    await tester.pump();
    ok(tester, 'classroom hint/skip');
    // sensei chat sheet (rev-2 §4): open, quick chip, close
    await tester.tap(find.bySemanticsLabel('Talk to sensei'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('একটা উদাহরণ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200)); // canned reply lands
    ok(tester, 'sensei chat sheet');
    await tester.tap(find.descendant(
        of: find.byType(SenseiChatSheet),
        matching: find.byIcon(Icons.close))); // close the sheet, not the toolbar
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('বন্ধ')); // quit lesson (pops)
    await tester.pump();
    ok(tester, 'classroom quit');

    // ── 5. Review (fresh user, empty deck, DB off-device) ───────────────
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.tap(find.text('আজকের রিভিউ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    ok(tester, 'review screen (empty state)');
    await tester.pageBack();
    await tester.pump();

    // ── 6. Speak tab ─────────────────────────────────────────────────────
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    ok(tester, 'speak/shadowing tab');

    // ── 7. Progress tab + AI mock exam ───────────────────────────────────
    await tester.tap(find.byIcon(Icons.monitor_heart_outlined));
    await tester.pump();
    await pumpUntil(tester, find.text('তোমার অগ্রগতি'), what: 'progress v4');
    expect(find.text('N5 · 72%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.psychology).first);
    await tester.pump();
    await pumpUntil(tester, find.text('AI এক্সামিনার'), what: 'AI examiner');
    await tester.tap(find.text('মক এক্সাম শুরু করো'));
    await tester.pump(); // checking spinner
    await tester.pump(const Duration(seconds: 3)); // exam runs (demo 2.4s)
    expect(find.text('মক এক্সাম শুরু করো'), findsNothing,
        reason: 'exam should have started');
    ok(tester, 'AI check mock exam');
    await tester.pageBack();
    await tester.pump();

    // ── 8. Home AppBar pushes: Kana, Writing, Settings ───────────────────
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    for (final icon in [Icons.grid_view, Icons.draw, Icons.settings_outlined]) {
      await tester.tap(find.byIcon(icon));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      ok(tester, 'pushed page for $icon');
      await tester.pageBack();
      await tester.pump();
    }

    // ── 9. Sanity: back home, shell intact ───────────────────────────────
    await pumpUntil(tester, find.textContaining('হাই'), what: 'home after tour');
    expect(find.byType(NavigationBar), findsOneWidget);
    ok(tester, 'final state');
  });
}
