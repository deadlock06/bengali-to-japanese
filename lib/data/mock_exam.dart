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
    this.itemType, // JLPT 問題 tag (forward-compat; null on legacy content)
  });
  final String itemId, jp, audioKey;
  final List<String> options;
  final int answerIndex;
  final bool hideText;
  final String? itemType;
}

class MockSection {
  const MockSection(
      {required this.id, required this.titleBn, required this.questions, this.minutes});
  final String id, titleBn;
  final List<MockQuestion> questions;

  /// Official section time in minutes (JLPT N4 blueprint, jlpt.jp). null when
  /// the test doesn't publish per-section times for this mock.
  final int? minutes;
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
    audioKey: it.id, hideText: listening, itemType: it.itemType,
  );
}

/// Builds a mock, or null if the store lacks enough content (needs ≥4 distinct
/// meanings per pool — always true once L0–A2 is authored).
/// Official JLPT pass marks (published, out of 180). Sectional minimums also
/// apply in the real exam; we approximate that with a per-section floor below.
const _jlptPass = <String, int>{'n5': 80, 'n4': 90, 'n3': 95, 'n2': 90, 'n1': 100};

/// Builds a mock for any exam kind, or null if the store lacks enough content
/// (N3/N2/N1 return null until their packs are authored → the screen shows an
/// honest "content coming" state, never invented questions — D-004).
///
/// Section layout & times follow the official jlpt.jp blueprint: N5/N4/N3 have
/// THREE sections (Vocabulary / Grammar·Reading / Listening); N2/N1 combine
/// Language Knowledge + Reading into ONE section + Listening. JFT-Basic keeps
/// its CBT 4-section shape. Question counts are a content-bounded practice
/// subset weighted by the real section times — never the full item count.
MockExam? buildMockExam({
  required Iterable<Lesson> lessons,
  required String kind, // 'jft' | 'n5' | 'n4' | 'n3' | 'n2' | 'n1'
  int seed = 0,
}) {
  final all = lessons
      .expand((l) => l.items.map((i) => (lesson: l, item: i)))
      .toList();
  bool at(({Lesson lesson, LessonItem item}) x, String n) =>
      x.lesson.jftLevel.contains(n);
  // Basic tier (JFT-Basic / N5) = everything NOT tagged N4–N1.
  bool isBasic(({Lesson lesson, LessonItem item}) x) =>
      !['N4', 'N3', 'N2', 'N1'].any((n) => at(x, n));
  final upper = {'n4': 'N4', 'n3': 'N3', 'n2': 'N2', 'n1': 'N1'}[kind];
  final base = <LessonItem>[
    for (final x in all)
      if (upper != null ? at(x, upper) : isBasic(x)) x.item
  ];
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

  MockSection vocab(int min, int n) => MockSection(
      id: 'moji', titleBn: 'শব্দ ও লিপি (文字・語彙)', minutes: min, questions: qs(words, n, 'moji'));
  MockSection grammarReading(int min, int n) => MockSection(
      id: 'bunpou', titleBn: 'ব্যাকরণ ও পড়া (文法・読解)', minutes: min, questions: qs(sents, n, 'bunpou'));
  MockSection listening(int min, int n) => MockSection(
      id: 'choukai', titleBn: 'শোনা (聴解)', minutes: min, questions: qs(base, n, 'choukai', listening: true));
  // N2/N1: Language Knowledge (vocab+grammar) + Reading, one combined section.
  MockSection langKnowledge(int min, int nv, int ng) => MockSection(
      id: 'gengo', titleBn: 'ভাষাজ্ঞান ও পড়া (言語知識・読解)', minutes: min,
      questions: [...qs(words, nv, 'gengo_v'), ...qs(sents, ng, 'gengo_g')]);

  switch (kind) {
    case 'n5':
      return MockExam(kind: 'n5', titleBn: 'JLPT N5 মক পরীক্ষা', minutes: 90,
          sections: [vocab(20, 12), grammarReading(40, 14), listening(30, 10)]);
    case 'n4':
      return MockExam(kind: 'n4', titleBn: 'JLPT N4 মক পরীক্ষা', minutes: 115,
          sections: [vocab(25, 14), grammarReading(55, 16), listening(35, 12)]);
    case 'n3':
      return MockExam(kind: 'n3', titleBn: 'JLPT N3 মক পরীক্ষা', minutes: 140,
          sections: [vocab(30, 14), grammarReading(70, 18), listening(40, 12)]);
    case 'n2':
      return MockExam(kind: 'n2', titleBn: 'JLPT N2 মক পরীক্ষা', minutes: 155,
          sections: [langKnowledge(105, 12, 12), listening(50, 12)]);
    case 'n1':
      return MockExam(kind: 'n1', titleBn: 'JLPT N1 মক পরীক্ষা', minutes: 165,
          sections: [langKnowledge(110, 13, 13), listening(55, 12)]);
    default: // 'jft' — JFT-Basic CBT 60min, 4 sections (docs/CURRICULUM.md §2)
      return MockExam(kind: 'jft', titleBn: 'JFT-Basic মক পরীক্ষা', minutes: 60, sections: [
        MockSection(id: 'script', titleBn: 'লিপি ও শব্দ (文字と語彙)', questions: qs(words, 14, 'script')),
        MockSection(id: 'kaiwa', titleBn: 'কথোপকথন ও প্রকাশ (会話と表現)', questions: qs(sents, 12, 'kaiwa')),
        MockSection(id: 'choukai', titleBn: 'শোনা (聴解)', questions: qs(base, 12, 'choukai', listening: true)),
        MockSection(id: 'dokkai', titleBn: 'পড়া (読解)', questions: qs(sents, 12, 'dokkai2')),
      ]);
  }
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
  final passMark = _jlptPass[exam.kind];
  if (passMark != null) {
    // All JLPT levels are scored out of 180 with published pass marks + section
    // minimums (approximated by a 32% per-section floor). Honest ESTIMATE only.
    final est = (pct * 180).round();
    final sectionsOk = exam.sections.every(
        (s) => st[s.id] == 0 || sc[s.id]! / st[s.id]! >= 0.32);
    return MockResult(
      kind: exam.kind, sectionCorrect: sc, sectionTotal: st,
      estimateLabel: 'আনুমানিক ~$est/180 (পাস ≥$passMark + প্রতি সেকশনে ন্যূনতম)',
      passed: est >= passMark && sectionsOk, weakestSection: weakest,
    );
  }
  final est = (10 + pct * 240).round();
  return MockResult(
    kind: 'jft', sectionCorrect: sc, sectionTotal: st,
    estimateLabel: 'আনুমানিক ~$est/250 (SSW পাস ≥200)',
    passed: est >= 200, weakestSection: weakest,
  );
}
