// B2 proof: vocab items with audio get a say-it (Production) step after
// Recognition — degrades gracefully with no mic, skip stays free (D-001/D-002).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/app/providers.dart';
import 'package:sensei_app/data/lesson_batch.dart';
import 'package:sensei_app/presentation/lesson_screen_v4.dart';

const _batch = ClassroomBatch(lessonId: 'test_l', titleBn: 'টেস্ট পাঠ', questions: [
  ClassroomQuestion(
      itemId: 't1', jp: 'みず', yomi: 'みず · mizu',
      options: ['পানি', 'আগুন', 'গাছ', 'ভাত'], answerIndex: 0,
      hint: 'হিন্ট', noteBn: 'নোট', audioKey: 'fd_02'),
  ClassroomQuestion(
      itemId: 't2', jp: 'おちゃ', yomi: 'おちゃ · ocha',
      options: ['চা', 'জুস', 'কফি', 'দুধ'], answerIndex: 0,
      hint: 'হিন্ট', noteBn: 'নোট', audioKey: 'fd_03'),
]);

void main() {
  testWidgets('vocab: চেনা → বলা (say-it) → next item', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        classroomBatchProvider.overrideWith((ref) => Future.value(_batch)),
      ],
      child: const MaterialApp(home: LessonScreenV4()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Intro → recognition
    await tester.tap(find.text('চিনেছি → এবার পরীক্ষা'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'পানি'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Phase 3 — say-it card, skip still visible (D-001)
    expect(find.text('উচ্চারণ অনুশীলন 🎙️'), findsOneWidget);
    expect(find.text('বাদ'), findsOneWidget);

    // Step 1: Tap to hear native pronunciation (enables continue button)
    await tester.tap(find.text('জাপানি উচ্চারণ শোনো'));
    await tester.pump();

    // Done saying → next item's intro
    await tester.tap(find.text('পরের শব্দে যাই →'));
    await tester.pump();
    expect(find.text('চিনে নাও'), findsOneWidget);
    expect(find.text('おちゃ'), findsWidgets);
  });
}
