// Bhasago — app entry point. Trilingual (en/bn/ja) with bilingual Bengali mode,
// offline-first. Bottom-nav shell hosts Kana / Lesson / Shadowing / Pitch /
// Review, mirroring the interactive HTML prototype.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'presentation/screens.dart';
import 'presentation/accent_screens.dart';
import 'presentation/lesson_list_screen.dart';
import 'presentation/progress_screen.dart';
import 'presentation/settings_screen.dart';
import 'presentation/writing_screen.dart';

void main() => runApp(const ProviderScope(child: SenseiApp()));

class SenseiApp extends ConsumerWidget {
  const SenseiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
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
      home: const HomeShell(),
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

  static const _pages = [
    KanaScreen(),
    WritingScreen(),
    LessonListScreen(),
    ShadowingScreen(),
    PitchScreen(),
    ReviewScreen(),
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhasago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'অগ্রগতি · Progress',
            onPressed: () => _push(context, 'অগ্রগতি · Progress',
                const ProgressScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'সেটিংস · Settings',
            onPressed: () => _push(context, 'সেটিংস · Settings',
                const SettingsScreen()),
          ),
        ],
      ),
      body: _pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.grid_view), label: s.kanaTitle),
          NavigationDestination(icon: const Icon(Icons.draw), label: 'Write'),
          NavigationDestination(icon: const Icon(Icons.school), label: s.navLearn),
          NavigationDestination(icon: const Icon(Icons.mic), label: s.navSpeak),
          NavigationDestination(icon: const Icon(Icons.show_chart), label: s.pitchTitle),
          NavigationDestination(icon: const Icon(Icons.loop), label: s.navReview),
        ],
      ),
    );
  }
}
