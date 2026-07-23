// Small-viewport overflow sweep (D-044) — owner reported pages "overlapping".
// Pumps the main screens standalone at a tight 320x568 logical viewport (small
// budget phone) and fails on ANY layout exception (RenderFlex overflow etc.).
// Run: flutter test test/small_viewport_overflow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sensei_app/app/theme.dart';
import 'package:sensei_app/presentation/dictionary_screen.dart';
import 'package:sensei_app/presentation/journey_map_screen.dart';
import 'package:sensei_app/presentation/lesson_screen_v4.dart';
import 'package:sensei_app/presentation/progress_screen_v4.dart';
import 'package:sensei_app/presentation/settings_screen.dart';
import 'package:sensei_app/presentation/vocab_screen.dart';

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(640, 1136); // 320x568 @2x — tight
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(theme: BhasagoTheme.dark(), home: screen),
  ));
  // Let async providers resolve; never pumpAndSettle (infinite animations).
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final screens = <String, Widget Function()>{
    'Settings': () => const SettingsScreen(),
    'Dictionary (form)': () => const DictionaryScreen(),
    'Vocab bank': () => const VocabScreen(),
    'Journey map': () => const JourneyMapScreen(),
    'Progress v4': () => ProgressScreenV4(onOpenAiCheck: () {}),
    'Lesson (practice)': () =>
        const LessonScreenV4(practiceLessonId: 'lesson_greetings'),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} lays out clean at 320x568', (tester) async {
      await _pumpScreen(tester, Scaffold(body: e.value()));
      final ex = tester.takeException();
      expect(ex, isNull, reason: '${e.key} threw at small viewport: $ex');
    });
  }
}
