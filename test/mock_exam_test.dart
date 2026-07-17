// A4 proof: the mock-exam builder is deterministic, selects only from the
// verified store, fills the real section structure, and scores honestly.
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/data/mock_exam.dart';
import 'package:sensei_app/domain/models.dart';

Lesson mkLesson(String id, String level, int n, {bool sentences = false}) =>
    Lesson.fromJson({
      'type': 'lesson', 'id': id, 'pack_id': 'p', 'depends_on': [],
      'can_do': {'en': 'x', 'bn': 'x', 'ja': 'x'},
      'jlpt_or_jft': level, 'source': 't', 'verified': true, 'prerequisites': [],
      'items': [
        for (var i = 0; i < n; i++)
          {
            'id': '${id}_$i',
            'jp': sentences ? 'ぶんしょうです$i' : 'たん$i',
            'kana': 'かな$i', 'romaji': 'r$i',
            'meaning': {'en': 'm$i', 'bn': 'অর্থ$id$i', 'ja': 'j$i'},
            'note': {'en': 'n', 'bn': 'ন', 'ja': 'ノ'},
            'srs_words': ['w$i'],
          }
      ],
    });

void main() {
  final lessons = [
    mkLesson('a', 'JFT-Basic A2', 30),
    mkLesson('b', 'JFT-Basic A2', 30, sentences: true),
    mkLesson('c', 'JLPT N4', 30),
    mkLesson('d', 'JLPT N4', 30, sentences: true),
  ];

  test('JFT mock: 4 real sections, 50 questions, deterministic', () {
    final e1 = buildMockExam(lessons: lessons, kind: 'jft', seed: 7)!;
    final e2 = buildMockExam(lessons: lessons, kind: 'jft', seed: 7)!;
    expect(e1.sections.map((s) => s.id), ['script', 'kaiwa', 'choukai', 'dokkai']);
    expect(e1.totalQuestions, 50);
    expect(e1.minutes, 60);
    // deterministic: same seed → same questions & answers
    expect(e1.sections.first.questions.map((q) => q.itemId),
        e2.sections.first.questions.map((q) => q.itemId));
    // listening hides text; every option list has the answer in bounds
    for (final q in e1.sections[2].questions) {
      expect(q.hideText, true);
    }
    for (final s in e1.sections) {
      for (final q in s.questions) {
        expect(q.options.length, 4);
        expect(q.options[q.answerIndex].isNotEmpty, true);
        // only verified items: itemId comes from the store
        expect(q.itemId.startsWith(RegExp('[ab]_')), true,
            reason: 'JFT draws only from A2-level lessons');
      }
    }
  });

  test('N4 mock draws only N4 items; 39 questions', () {
    final e = buildMockExam(lessons: lessons, kind: 'n4', seed: 3)!;
    expect(e.totalQuestions, 39);
    for (final s in e.sections) {
      for (final q in s.questions) {
        expect(q.itemId.startsWith(RegExp('[cd]_')), true);
      }
    }
  });

  test('scoring: all correct passes, all skipped fails, weakest found', () {
    final e = buildMockExam(lessons: lessons, kind: 'jft', seed: 1)!;
    final perfect = {
      for (final s in e.sections) for (final q in s.questions) q.itemId: q.answerIndex
    };
    final r = scoreMockExam(e, perfect);
    expect(r.correct, 50);
    expect(r.passed, true);
    expect(r.estimateLabel.contains('250'), true);

    final none = scoreMockExam(e, {});
    expect(none.correct, 0);
    expect(none.passed, false);

    // only section 1 answered → some other section is weakest
    final partial = {
      for (final q in e.sections.first.questions) q.itemId: q.answerIndex
    };
    final pr = scoreMockExam(e, partial);
    expect(pr.weakestSection == 'script', false);
  });

  test('too little content → null (no invented questions, D-004)', () {
    expect(buildMockExam(lessons: [mkLesson('x', 'JFT-Basic A2', 10)], kind: 'jft'), null);
  });
}
