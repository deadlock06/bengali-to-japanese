// Smoke test — the v4 "Bold Ink" shell builds inside a ProviderScope, shows
// the 4-tab NavigationBar (Home/Learn/Speak/Progress), the first-run
// onboarding gate works, and pushed pages (Write) render without throwing.
// Deliberately avoids pumpAndSettle: content-loading spinners animate forever.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sensei_app/main.dart';
import 'package:sensei_app/presentation/onboarding_screen.dart';

void main() {
  testWidgets('app shell builds with brand bar and 4 nav tabs', (tester) async {
    // Locale already chosen -> gate goes straight to HomeShell.
    SharedPreferences.setMockInitialValues({'locale_chosen': 'bn'});

    // Portrait budget-phone viewport (the target device class) for realistic
    // proportions. Not required for safety: WritingScreen adapts to the
    // shorter axis (D-013); the last test covers the landscape case.
    tester.view.physicalSize = const Size(720, 1640);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump(); // gate: prefs future resolves
    await tester.pump();

    expect(find.text('Bhasago'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Four destinations per the v4 shell (Kana/Write/Pitch/Review are pushes).
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Tab switching doesn't throw.
    await tester.tap(find.byIcon(Icons.monitor_heart_outlined));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('first run shows the language-select onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({}); // nothing chosen yet

    tester.view.physicalSize = const Size(720, 1640);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget); // Bengali-first default card
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('WritingScreen (pushed page) fits a short landscape viewport',
      (tester) async {
    SharedPreferences.setMockInitialValues({'locale_chosen': 'bn'});

    // Default 800x600 test surface — landscape. Regression test for the
    // canvas overflow fixed in D-013: the paper square sizes to the
    // shorter axis instead of forcing height = width.
    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump();
    await tester.pump();

    // Write moved off the tab bar in v4 — it's an AppBar action on Home.
    await tester.tap(find.byIcon(Icons.draw_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
