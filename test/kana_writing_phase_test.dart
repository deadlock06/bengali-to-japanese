// Phase 3 (Production) for kana in the classroom: after a correct recognition
// answer, the learner WRITES the character (trace pad) before the next item —
// writing practice is part of the lesson path. D-001: বাদ (skip) still works.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/app/providers.dart';
import 'package:sensei_app/data/lesson_batch.dart';
import 'package:sensei_app/presentation/kana_trace_pad.dart';
import 'package:sensei_app/presentation/lesson_screen_v4.dart';

void main() {
  testWidgets('kana lesson: চেনা → লেখা (writing step) → next item',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classroomBatchProvider
              .overrideWith((ref) => Future.value(buildKanaBatch(katakana: false))),
        ],
        child: const MaterialApp(home: LessonScreenV4()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Phase 1 — Intro presents あ; continue to recognition.
    expect(find.text('চিনে নাও'), findsOneWidget);
    await tester.tap(find.text('চিনেছি → এবার পরীক্ষা'));
    await tester.pump();

    // Phase 2 — Recognition: answer correctly (あ = আ).
    expect(find.text('এটি কোন ধ্বনি?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'আ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Phase 3 — Writing: the trace pad is part of the flow.
    expect(find.text('এবার লেখো ✍️'), findsOneWidget);
    expect(find.byType(KanaTracePad), findsOneWidget);
    // Skip stays available during writing (D-001).
    expect(find.text('বাদ'), findsOneWidget);

    // Finish writing → next item's Intro (い).
    await tester.tap(find.text('লেখা হয়েছে →'));
    await tester.pump();
    expect(find.text('চিনে নাও'), findsOneWidget);
    expect(find.text('い'), findsWidgets);
  });
}
