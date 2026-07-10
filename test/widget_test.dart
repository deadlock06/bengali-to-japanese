// Smoke test — the app shell builds inside a ProviderScope, shows the brand
// app bar and the six-tab NavigationBar, and tab switching doesn't throw.
// Deliberately avoids pumpAndSettle: content-loading spinners animate forever.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sensei_app/main.dart';

void main() {
  testWidgets('app shell builds with brand bar and nav tabs', (tester) async {
    // Portrait budget-phone viewport (the target device class) for realistic
    // proportions. No longer required for safety: WritingScreen adapts to the
    // shorter axis (D-013), so even the default landscape surface is fine —
    // the second test below covers that case.
    tester.view.physicalSize = const Size(720, 1640);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump();

    expect(find.text('Bhasago'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Six destinations per main.dart's HomeShell.
    expect(find.byType(NavigationDestination), findsNWidgets(6));

    // Switching to the Write tab renders without throwing.
    await tester.tap(find.byIcon(Icons.draw));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('WritingScreen fits a short landscape viewport', (tester) async {
    // Default 800x600 test surface — landscape. Regression test for the
    // canvas overflow fixed in D-013: the paper square now sizes to the
    // shorter axis instead of forcing height = width.
    await tester.pumpWidget(const ProviderScope(child: SenseiApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.draw));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
