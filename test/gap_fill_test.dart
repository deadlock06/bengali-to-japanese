// B1 proof: Phase-4 gap-fill is deterministic, boundary-guarded (never splits
// kana mid-word), and only ever blanks KNOWN verified words (D-004).
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/data/lesson_batch.dart';
import 'package:sensei_app/domain/models.dart';

Lesson mk(String id, List<(String, String)> items) => Lesson.fromJson({
      'type': 'lesson', 'id': id, 'pack_id': 'p', 'depends_on': [],
      'can_do': {'en': 'x', 'bn': 'x', 'ja': 'x'},
      'jlpt_or_jft': 'JFT-Basic A2', 'source': 't', 'verified': true,
      'prerequisites': [],
      'items': [
        for (final (jp, bn) in items)
          {
            'id': '${id}_${items.indexWhere((e) => e.$1 == jp)}',
            'jp': jp, 'kana': jp, 'romaji': 'r',
            'meaning': {'en': 'e', 'bn': bn, 'ja': 'j'},
            'note': {'en': 'n', 'bn': 'ন', 'ja': 'ノ'},
            'srs_words': [jp],
          }
      ],
    });

void main() {
  final words = mk('words', [
    ('みず', 'পানি'), ('ごはん', 'ভাত'), ('でんしゃ', 'ট্রেন'), ('せん', 'হাজার'),
    ('きっぷ', 'টিকিট'), ('やすみ', 'ছুটি'),
  ]);
  final sentences = mk('sents', [
    ('みずをください', 'পানি দিন'),
    ('ここですってはいけません', 'এখানে ধূমপান নিষেধ'),
    ('でんしゃにのります', 'ট্রেনে চড়ি'),
    ('あしたはやすみです', 'কাল ছুটি'),
  ]);

  test('gap-fill blanks a known word at a boundary', () {
    final b = buildClassroomBatch(
        curriculumOrdered: [words, sentences], completed: {'words'})!;
    final mizu = b.questions.firstWhere((q) => q.jp == 'みずをください');
    expect(mizu.hasGap, true);
    expect(mizu.gapText, '＿＿をください');
    expect(mizu.gapOptions[mizu.gapAnswerIndex], 'みず');
    expect(mizu.gapOptions.length, 4);
  });

  test('boundary guard: せん never matches inside いけません', () {
    final b = buildClassroomBatch(
        curriculumOrdered: [words, sentences], completed: {'words'})!;
    final ike = b.questions.firstWhere((q) => q.jp == 'ここですってはいけません');
    // no known word sits at a particle boundary in this sentence → no gap,
    // rather than a WRONG gap (quality over coverage)
    expect(ike.hasGap, false);
  });

  test('deterministic: same input ⇒ identical gaps', () {
    final b1 = buildClassroomBatch(
        curriculumOrdered: [words, sentences], completed: {'words'})!;
    final b2 = buildClassroomBatch(
        curriculumOrdered: [words, sentences], completed: {'words'})!;
    for (var i = 0; i < b1.questions.length; i++) {
      expect(b1.questions[i].gapText, b2.questions[i].gapText);
      expect(b1.questions[i].gapOptions, b2.questions[i].gapOptions);
    }
  });

  test('word items themselves get no gap', () {
    final b = buildClassroomBatch(
        curriculumOrdered: [words, sentences], completed: const {})!;
    for (final q in b.questions) {
      expect(q.hasGap, false, reason: 'word lesson has no sentences');
    }
  });
}
