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

/// Robust back: a Material BackButton renders an [Icons.arrow_back]; custom
/// headers use it directly. Tap the TOPMOST arrow (`.last`, the visible one) —
/// works for single- and nested-Scaffold pushes; else fall back to pageBack.
Future<void> back(WidgetTester t) async {
  final arrow = find.byIcon(Icons.arrow_back);
  if (arrow.evaluate().isNotEmpty) {
    await t.tap(arrow.last);
  } else {
    await t.pageBack();
  }
  // Let the route-pop transition fully finish before the next interaction —
  // tapping mid-transition drops the next push.
  await t.pump();
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
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

    // ── 4. AI Classroom via the red Home card ───────────────────────────
    // The classroom now opens on the Phase-1 Intro card (sensei presents the
    // item); the recognition MC appears after "চিনেছি". Skip/Hint/Quit are the
    // 00 invariant and present throughout. Target the toolbar pills via
    // widgetWithText ('ইঙ্গিত' also labels the hint card once open).
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.tap(find.text('AI ক্লাসরুম'));
    await tester.pump();
    await tester.pump();
    final hint = find.widgetWithText(OutlinedButton, 'ইঙ্গিত');
    expect(hint, findsOneWidget, reason: 'Hint missing');
    expect(find.widgetWithText(OutlinedButton, 'বাদ'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'বন্ধ'), findsOneWidget);
    // Advance the intro → recognition if the intro button is showing.
    final introBtn = find.text('চিনেছি → এবার পরীক্ষা');
    if (introBtn.evaluate().isNotEmpty) {
      await tester.tap(introBtn);
      await tester.pump();
    }
    await tester.tap(hint);
    await tester.pump();
    await tester.tap(hint);
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'বাদ'));
    await tester.pump();
    ok(tester, 'classroom intro + hint/skip');
    // Quit via the header back arrow (the 'বন্ধ' pill can sit partly off the
    // short test viewport). Sensei chat is covered by its own test below.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump();
    ok(tester, 'classroom quit');

    // ── 5. Review (fresh user, empty deck, DB off-device) ───────────────
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.tap(find.text('আজকের রিভিউ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    ok(tester, 'review screen (empty state)');
    await back(tester);

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
    await back(tester);

    // ── 8. Home AppBar: Kana/Write/Settings reachable; one push+pop works ─
    // (A loop of push→pop→push is flaky under fake-async — the 2nd push after a
    // pop is dropped mid-transition — so assert the affordances then exercise a
    // single real push+pop. Kana + Writing also have their own widget tests.)
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    for (final icon in [Icons.grid_view, Icons.draw, Icons.settings_outlined]) {
      expect(find.byIcon(icon), findsOneWidget, reason: 'AppBar icon $icon');
    }
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('ভাষা'), findsWidgets,
        reason: 'settings screen (language section)');
    ok(tester, 'settings screen');
    await back(tester);

    // ── 9. Sanity: back home, shell intact ───────────────────────────────
    await pumpUntil(tester, find.textContaining('হাই'), what: 'home after tour');
    expect(find.byType(NavigationBar), findsOneWidget);
    ok(tester, 'final state');
  });

  // The classroom's sensei chat + autonomy invariants, direct-pumped for stable
  // semantics (the full-app journey can't reach it reliably under fake-async).
  testWidgets('AI Classroom: intro → hint/skip + sensei chat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1640);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final sem = tester.ensureSemantics();

    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: LessonScreenV4())));
    await tester.pump();
    await tester.pump();

    // Skip/Hint/Quit invariant (toolbar pills).
    final hintBtn = find.widgetWithText(OutlinedButton, 'ইঙ্গিত');
    expect(hintBtn, findsOneWidget, reason: 'Hint missing');
    expect(find.widgetWithText(OutlinedButton, 'বাদ'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'বন্ধ'), findsOneWidget);
    // Advance the Phase-1 intro into recognition.
    final introBtn = find.text('চিনেছি → এবার পরীক্ষা');
    if (introBtn.evaluate().isNotEmpty) {
      await tester.tap(introBtn);
      await tester.pump();
    }
    await tester.tap(hintBtn);
    await tester.pump();
    await tester.tap(hintBtn);
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'বাদ'));
    await tester.pump();
    ok(tester, 'classroom hint/skip');

    // Sensei chat: open (sprite), quick chip → canned reply, close.
    await tester.tap(find.bySemanticsLabel('Talk to sensei'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('একটা উদাহরণ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    ok(tester, 'sensei chat');
    await tester.tap(find.descendant(
        of: find.byType(SenseiChatSheet),
        matching: find.byIcon(Icons.close)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    ok(tester, 'sensei chat close');
    sem.dispose();
  });
}
