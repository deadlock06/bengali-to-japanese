// Mock-exam engine (PROJECT_SCALE A4) — JFT-Basic (A2.M) and JLPT-N4 (N4.M)
// practice mocks in the real exams' section structure.
//
// CONSTITUTION: questions are SELECTED from the verified content store (the
// same items the classroom teaches) — never invented (D-004/D-011); grading is
// deterministic answer-key match (D-001); the timer recommends, never locks —
// Skip/Quit work everywhere, and the band estimate is clearly labeled an
// ESTIMATE, never a promise (no false certification).
//
// Deterministic: same content + same seed ⇒ same exam (testable, provable).
import '../domain/models.dart';

class MockQuestion {
  const MockQuestion({
    required this.itemId,
    required this.jp,
    required this.options,
    required this.answerIndex,
    this.audioKey = '',
    this.hideText = false, // listening: play the clip, don't show the text
  });
  final String itemId, jp, audioKey;
  final List<String> options;
  final int answerIndex;
  final bool hideText;
}

class MockSection {
  const MockSection({required this.id, required this.titleBn, required this.questions});
  final String id, titleBn;
  final List<MockQuestion> questions;
}

class MockExam {
  const MockExam({required this.kind, required this.titleBn, required this.minutes, required this.sections});
  final String kind; // 'jft' | 'n4'
  final String titleBn;
  final int minutes;
  final List<MockSection> sections;
  int get totalQuestions => sections.fold(0, (s, x) => s + x.questions.length);
}

/// Per-section + overall result with an HONEST estimated band.
class MockResult {
  const MockResult({
    required this.kind,
    required this.sectionCorrect,
    required this.sectionTotal,
    required this.estimateLabel,
    required this.passed,
    required this.weakestSection,
  });
  final String kind;
  final Map<String, int> sectionCorrect, sectionTotal;
  final String estimateLabel;
  final bool passed;
  final String weakestSection;
  int get correct => sectionCorrect.values.fold(0, (a, b) => a + b);
  int get total => sectionTotal.values.fold(0, (a, b) => a + b);
}

int _hash(String s) => s.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);

/// Stable shuffle-free selection: sort by per-seed hash, take n.
List<T> _pick<T>(Iterable<T> xs, int n, int seed, String Function(T) key) {
  final l = xs.toList()
    ..sort((a, b) => _hash('${key(a)}#$seed').compareTo(_hash('${key(b)}#$seed')));
  return l.take(n).toList();
}

bool _isSentence(LessonItem it) =>
    it.jp.length > 7 || it.jp.contains('です') || it.jp.contains('ます') || it.jp.contains('か');

MockQuestion _mc(LessonItem it, List<String> pool, int seed,
    {bool listening = false}) {
  final correct = it.meaning.bn;
  final distractors = <String>[];
  final cands = [...pool]..remove(correct);
  cands.sort((a, b) =>
      _hash('$a#${it.id}#$seed').compareTo(_hash('$b#${it.id}#$seed')));
  for (final c in cands) {
    if (distractors.length == 3) break;
    if (c != correct && !distractors.contains(c)) distractors.add(c);
  }
  final ai = _hash('${it.id}pos$seed') % 4;
  final options = [...distractors]..insert(ai, correct);
  return MockQuestion(
    itemId: it.id, jp: it.jp, options: options, answerIndex: ai,
    audioKey: it.id, hideText: listening,
  );
}

/// Builds a mock, or null if the store lacks enough content (needs ≥4 distinct
/// meanings per pool — always true once L0–A2 is authored).
MockExam? buildMockExam({
  required Iterable<Lesson> lessons,
  required String kind, // 'jft' | 'n4'
  int seed = 0,
}) {
  final isN4 = kind == 'n4';
  final all = lessons
      .expand((l) => l.items.map((i) => (lesson: l, item: i)))
      .toList();
  final n4Items = all.where((x) => x.lesson.jftLevel.contains('N4')).map((x) => x.item);
  final a2Items = all.where((x) => !x.lesson.jftLevel.contains('N4')).map((x) => x.item);
  final base = (isN4 ? n4Items : a2Items).toList();
  if (base.length < 40) return null;
  final pool = base.map((i) => i.meaning.bn).toSet().toList()..sort();
  if (pool.length < 8) return null;

  final words = base.where((i) => !_isSentence(i));
  final sents = base.where(_isSentence);

  List<MockQuestion> qs(Iterable<LessonItem> src, int n, String salt,
          {bool listening = false}) =>
      _pick(src, n, _hash('$salt$seed'), (i) => i.id)
          .map((i) => _mc(i, pool, seed, listening: listening))
          .toList();

  if (isN4) {
    // JLPT N4: ~115min real; practice mock 39Q / 50min, 3 sections.
    return MockExam(kind: 'n4', titleBn: 'JLPT N4 মক পরীক্ষা', minutes: 50, sections: [
      MockSection(id: 'moji', titleBn: 'শব্দ ও লিপি (文字・語彙)', questions: qs(words, 13, 'moji')),
      MockSection(id: 'bunpou', titleBn: 'ব্যাকরণ ও পড়া (文法・読解)', questions: qs(sents, 13, 'bunpou')),
      MockSection(id: 'choukai', titleBn: 'শোনা (聴解)', questions: qs(base, 13, 'choukai', listening: true)),
    ]);
  }
  // JFT-Basic: CBT 60min ~50Q, 4 sections (docs/CURRICULUM.md §2).
  return MockExam(kind: 'jft', titleBn: 'JFT-Basic মক পরীক্ষা', minutes: 60, sections: [
    MockSection(id: 'script', titleBn: 'লিপি ও শব্দ (文字と語彙)', questions: qs(words, 14, 'script')),
    MockSection(id: 'kaiwa', titleBn: 'কথোপকথন ও প্রকাশ (会話と表現)', questions: qs(sents, 12, 'kaiwa')),
    MockSection(id: 'choukai', titleBn: 'শোনা (聴解)', questions: qs(base, 12, 'choukai', listening: true)),
    MockSection(id: 'dokkai', titleBn: 'পড়া (読解)', questions: qs(sents, 12, 'dokkai2')),
  ]);
}

/// Deterministic scoring → honest estimate (recommendation language, D-001).
MockResult scoreMockExam(MockExam exam, Map<String, int?> answers) {
  final sc = <String, int>{}, st = <String, int>{};
  for (final s in exam.sections) {
    var c = 0;
    for (final q in s.questions) {
      if (answers[q.itemId] == q.answerIndex) c++;
    }
    sc[s.id] = c;
    st[s.id] = s.questions.length;
  }
  final total = st.values.fold(0, (a, b) => a + b);
  final correct = sc.values.fold(0, (a, b) => a + b);
  final pct = total == 0 ? 0.0 : correct / total;
  String weakest = exam.sections.first.id;
  double worst = 2;
  for (final s in exam.sections) {
    final r = st[s.id] == 0 ? 1.0 : sc[s.id]! / st[s.id]!;
    if (r < worst) { worst = r; weakest = s.id; }
  }
  if (exam.kind == 'n4') {
    final est = (pct * 180).round();
    final sectionsOk = exam.sections.every(
        (s) => st[s.id] == 0 || sc[s.id]! / st[s.id]! >= 0.32);
    return MockResult(
      kind: 'n4', sectionCorrect: sc, sectionTotal: st,
      estimateLabel: 'আনুমানিক ~$est/180 (পাস ≥90 + প্রতি সেকশনে ন্যূনতম)',
      passed: est >= 90 && sectionsOk, weakestSection: weakest,
    );
  }
  final est = (10 + pct * 240).round();
  return MockResult(
    kind: 'jft', sectionCorrect: sc, sectionTotal: st,
    estimateLabel: 'আনুমানিক ~$est/250 (SSW পাস ≥200)',
    passed: est >= 200, weakestSection: weakest,
  );
}
