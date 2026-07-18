// Mock-exam screen (A4) — JFT-Basic / JLPT-N4 practice mocks in real section
// structure, from the verified store (lib/data/mock_exam.dart).
// D-001 throughout: the timer RECOMMENDS (hits 0 → results, never locks);
// বাদ (skip) and বন্ধ (quit) always work; the score is labeled an estimate.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/audio_service.dart';
import '../data/mock_exam.dart';

const _red = Color(0xFFB3121B);

class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key, required this.kind});
  final String kind; // 'jft' | 'n5' | 'n4' | 'n3' | 'n2' | 'n1'
  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();

  /// Maps a mock curriculum-unit id ('N4.M', 'A2.M', 'N2.M'…) to a mock kind.
  /// A2.M → JFT-Basic; every N-level mock → its own JLPT kind.
  static String kindForUnit(String unitId) {
    final lvl = unitId.split('.').first.toLowerCase(); // 'n4', 'a2', 'n3'…
    return lvl.startsWith('n') ? lvl : 'jft';
  }
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  MockExam? exam;
  final answers = <String, int?>{};
  bool started = false, finished = false;
  int si = 0, qi = 0;
  int secondsLeft = 0;
  Timer? _timer;
  bool completionSaved = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      started = true;
      secondsLeft = exam!.minutes * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        secondsLeft--;
        // Time up → gently move to results (recommend, never lock — D-001).
        if (secondsLeft <= 0) _finish();
      });
    });
  }

  void _finish() {
    _timer?.cancel();
    setState(() => finished = true);
    _saveCompletion();
  }

  Future<void> _saveCompletion() async {
    if (completionSaved) return;
    completionSaved = true;
    try {
      final r = scoreMockExam(exam!, answers);
      await ref.read(srsProvider).recordLessonCompletion(
            lessonId: 'mock_${widget.kind == 'jft' ? 'a2' : widget.kind}',
            items: r.total,
            correct: r.correct,
            hints: 0,
            skips: r.total - answers.values.whereType<int>().length,
          );
      ref.invalidate(curriculumProvider);
    } catch (_) {/* off-device DB — result still shows */}
  }

  MockQuestion get q => exam!.sections[si].questions[qi];

  void _answer(int i) {
    answers[q.itemId] = i;
    _next();
  }

  void _next() {
    setState(() {
      final sec = exam!.sections[si];
      if (qi < sec.questions.length - 1) {
        qi++;
      } else if (si < exam!.sections.length - 1) {
        si++;
        qi = 0;
      } else {
        _finish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    exam ??= buildMockExam(
      lessons: ref.watch(contentProvider).valueOrNull?.lessons ?? const [],
      kind: widget.kind,
      // Varies per attempt but stays reproducible within one: day-of-year seed.
      seed: DateTime.now().difference(DateTime(DateTime.now().year)).inDays,
    );
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      body: SafeArea(
        child: exam == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('মকের জন্য যথেষ্ট কনটেন্ট এখনো লোড হয়নি — একটু পরে আবার এসো।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BhasagoTheme.muted)),
                ),
              )
            : !started
                ? _intro()
                : finished
                    ? _results()
                    : _question(),
      ),
    );
  }

  Widget _header(String title) => Row(children: [
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20, color: BhasagoTheme.muted)),
        Expanded(
            child: Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
        if (started && !finished)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                border: Border.all(color: secondsLeft < 300 ? _red : BhasagoTheme.outline, width: 1.5),
                borderRadius: BorderRadius.circular(999)),
            child: Text(
                '${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: secondsLeft < 300 ? _red : BhasagoTheme.text,
                    fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        const SizedBox(width: 12),
      ]);

  Widget _intro() {
    final e = exam!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header(e.titleBn),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: BhasagoTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _red, width: 1.3)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.totalQuestions}টি প্রশ্ন · ${e.minutes} মিনিট · আসল পরীক্ষার সেকশন-কাঠামো',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (final s in e.sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                        '•  ${s.titleBn} — ${s.questions.length}টি'
                        '${s.minutes != null ? ' · ${s.minutes} মিনিট' : ''}',
                        style: const TextStyle(fontSize: 12.5, color: BhasagoTheme.muted)),
                  ),
                const SizedBox(height: 8),
                const Text(
                    'নিয়ম নয়, অভ্যাস: সময় শেষ হলে ফলাফলে চলে যাবে — কিছুই আটকে যায় না। '
                    'যেকোনো প্রশ্ন বাদ দেওয়া যায়, যেকোনো সময় বন্ধ করা যায়। '
                    'ফলাফল একটি অনুমান — আসল পরীক্ষার নম্বর নয়।',
                    style: TextStyle(fontSize: 11.5, height: 1.6, color: BhasagoTheme.muted)),
              ]),
            ),
          ]),
        ),
        FilledButton(
          onPressed: _start,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: const StadiumBorder()),
          child: const Text('মক শুরু করি', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _question() {
    final sec = exam!.sections[si];
    final done = exam!.sections.take(si).fold(0, (s, x) => s + x.questions.length) + qi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header('${sec.titleBn} · ${done + 1}/${exam!.totalQuestions}'),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                    value: done / exam!.totalQuestions,
                    backgroundColor: const Color(0xFF242424),
                    valueColor: const AlwaysStoppedAnimation(_red))),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
              decoration: BoxDecoration(
                  color: BhasagoTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BhasagoTheme.outline)),
              child: Column(children: [
                if (q.hideText) ...[
                  // Listening: sound only — like the real exam.
                  IconButton(
                    onPressed: () => AudioService.instance.play(q.audioKey),
                    icon: const Icon(Icons.volume_up, size: 44, color: _red),
                  ),
                  const Text('শুনে মানে বেছে নাও (আবার শুনতে 🔊 চাপো)',
                      style: TextStyle(fontSize: 11.5, color: BhasagoTheme.muted)),
                ] else
                  Text(q.jp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'ZenKakuGothicNew',
                          fontSize: 26, fontWeight: FontWeight.w900, height: 1.4)),
                const SizedBox(height: 16),
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: OutlinedButton(
                      onPressed: () => _answer(i),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: BhasagoTheme.text,
                          side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.5),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      child: Text(q.options[i]),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _next, // skip — always available (D-001)
              icon: const Icon(Icons.skip_next, size: 16, color: BhasagoTheme.muted),
              label: const Text('বাদ'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: BhasagoTheme.text,
                  side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.5),
                  shape: const StadiumBorder()),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: BhasagoTheme.text,
                  side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.5),
                  shape: const StadiumBorder()),
              child: const Text('বন্ধ'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _results() {
    final r = scoreMockExam(exam!, answers);
    final names = {for (final s in exam!.sections) s.id: s.titleBn};
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header('ফলাফল — ${exam!.titleBn}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: BhasagoTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: r.passed ? const Color(0xFF35E065) : _red, width: 1.4)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.correct}/${r.total} সঠিক',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(r.estimateLabel,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: r.passed ? const Color(0xFF35E065) : _red)),
                const SizedBox(height: 2),
                const Text('⚠️ এটা অনুশীলনের অনুমান — আসল পরীক্ষার নম্বর নয়।',
                    style: TextStyle(fontSize: 11, color: BhasagoTheme.muted)),
                const SizedBox(height: 14),
                for (final s in exam!.sections) ...[
                  Text('${names[s.id]} — ${r.sectionCorrect[s.id]}/${r.sectionTotal[s.id]}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                          value: (r.sectionTotal[s.id] ?? 0) == 0
                              ? 0
                              : r.sectionCorrect[s.id]! / r.sectionTotal[s.id]!,
                          backgroundColor: const Color(0xFF242424),
                          valueColor: AlwaysStoppedAnimation(
                              s.id == r.weakestSection ? _red : const Color(0xFF35E065))),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
                Text('সেনসেইয়ের পরামর্শ: "${names[r.weakestSection]}" অংশটা সবচেয়ে দুর্বল — '
                    'সংশ্লিষ্ট ইউনিটগুলো আবার review করে আরেকবার মক দাও। কোনো তাড়া নেই।',
                    style: const TextStyle(fontSize: 12, height: 1.6, color: BhasagoTheme.muted)),
              ]),
            ),
          ]),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF35E065),
              foregroundColor: const Color(0xFF111111),
              shape: const StadiumBorder()),
          child: const Text('ফিরে যাই', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
