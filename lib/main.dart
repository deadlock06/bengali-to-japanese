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
// Steps 4 (onboarding gate) and 5 (ProgressScreenV4 + AiCheckScreen) are
// wired in below, exactly per the handoff. The v0.1 ProgressScreen file is
// kept in the repo (its T-108 queries feed V4 later) but is not in the UI.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'presentation/home_screen.dart';
import 'presentation/screens.dart';
import 'presentation/accent_screens.dart';
import 'presentation/lesson_list_screen.dart';
import 'presentation/book_screen_v4.dart';
import 'presentation/lesson_screen_v4.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/progress_screen_v4.dart';
import 'presentation/settings_screen.dart';
import 'presentation/writing_screen.dart';

void main() => runApp(const ProviderScope(child: SenseiApp()));

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
        // AI Classroom card → push the adaptive lesson (its own close/back pops).
        onOpenLesson: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => LessonScreenV4())),
        onOpenReview: () =>
            _push(context, s.navReview, const ReviewScreen()),
        onOpenAiCheck: () =>
            _push(context, 'AI চেক', const AiCheckScreen()),
        onOpenProgress: () => setState(() => tab = 3),
        // Book has its own header/back — plain push, no _push scaffold.
        onOpenBook: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BookScreenV4())),
      ),
      const LessonListScreen(),
      const ShadowingScreen(),
      ProgressScreenV4(
        onOpenAiCheck: () => _push(context, 'AI চেক', const AiCheckScreen()),
      ),
    ];

    return Scaffold(
      // Design: Home has its own header; other tabs keep a slim AppBar.
      appBar: tab == 0
          ? AppBar(
              title: const Text('Bhasago'),
              actions: [
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
      body: pages[tab],
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
