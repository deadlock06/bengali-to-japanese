// T-112 — classroom batch builder (pure).
//
// Selects the learner's next lesson (first uncompleted, in curriculum order —
// rev-3 rule: "AI tutor lesson batches MUST be selected from the current
// curriculum unit") and turns its verified items into answer-key multiple-
// choice questions for LessonScreenV4.
//
// DETERMINISTIC on purpose: no Random. Same content + same progress ⇒ same
// batch, so behaviour is provable off-device (tools/batch_reference.mjs mirrors
// this file 1:1). Grading stays deterministic key-match (00 §4 / D-001): the
// correct option IS meaning.bn from the verified JSON; distractors are other
// verified meanings — the LLM never authors any option.

import '../domain/models.dart';

class ClassroomQuestion {
  const ClassroomQuestion({
    required this.itemId,
    required this.jp,
    required this.yomi,
    required this.options,
    required this.answerIndex,
    required this.hint,
    required this.noteBn,
    this.prompt = 'এর মানে কী?',
    this.introBn = '',
  });

  final String itemId, jp, yomi, hint, noteBn;
  final List<String> options;
  final int answerIndex;

  /// The question the sensei asks — 'এর মানে কী?' for vocab, 'এটি কোন ধ্বনি?'
  /// (which sound?) for kana recognition.
  final String prompt;

  /// The sensei's teaching line shown BEFORE the learner answers (teach → ask).
  final String introBn;
}

class ClassroomBatch {
  const ClassroomBatch({
    required this.lessonId,
    required this.titleBn,
    required this.questions,
  });

  final String lessonId;
  final String titleBn; // lesson can_do.bn — the "why you're learning this"
  final List<ClassroomQuestion> questions;
}

/// Stable tiny hash — keeps the answer position varied but reproducible.
int _seed(String s) => s.codeUnits.fold(0, (a, c) => (a + c) & 0x7fffffff);

/// Builds the next lesson's question batch, or null when every candidate
/// lesson is completed (caller decides what "all done" looks like).
ClassroomBatch? buildClassroomBatch({
  required List<Lesson> curriculumOrdered,
  required Set<String> completed,
  int maxItems = 8,
}) {
  Lesson? next;
  for (final l in curriculumOrdered) {
    if (!completed.contains(l.id) && l.items.isNotEmpty) {
      next = l;
      break;
    }
  }
  if (next == null) return null;

  // Distractor pool: every OTHER verified meaning, lesson-local first so
  // options stay thematically close, then the rest of the curriculum.
  final poolLocal = <String>[];
  final poolGlobal = <String>[];
  for (final it in next.items) {
    if (!poolLocal.contains(it.meaning.bn)) poolLocal.add(it.meaning.bn);
  }
  for (final l in curriculumOrdered) {
    if (identical(l, next)) continue;
    for (final it in l.items) {
      final m = it.meaning.bn;
      if (!poolLocal.contains(m) && !poolGlobal.contains(m)) poolGlobal.add(m);
    }
  }

  final questions = <ClassroomQuestion>[];
  final items = next.items.take(maxItems).toList(growable: false);
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final correct = it.meaning.bn;
    final distractors = <String>[];
    // Rotate the local pool by the item index so consecutive questions don't
    // repeat the same wrong options; top up from the global pool.
    final local = [...poolLocal]..remove(correct);
    for (var k = 0; k < local.length && distractors.length < 3; k++) {
      distractors.add(local[(k + i) % local.length]);
    }
    for (var k = 0; k < poolGlobal.length && distractors.length < 3; k++) {
      distractors.add(poolGlobal[(k + i) % poolGlobal.length]);
    }
    if (distractors.length < 3) continue; // not enough verified content yet

    final answerIndex = _seed(it.id) % 4;
    final options = [...distractors]..insert(answerIndex, correct);

    final kanaHead = it.kana.isEmpty ? it.jp[0] : it.kana[0];
    questions.add(ClassroomQuestion(
      itemId: it.id,
      jp: it.jp,
      yomi: '${it.kana} · ${it.romaji}',
      options: options,
      answerIndex: answerIndex,
      hint: '「$kanaHead」 দিয়ে শুরু — ${it.note.bn}',
      noteBn: it.note.bn,
    ));
  }
  if (questions.isEmpty) return null;

  return ClassroomBatch(
    lessonId: next.id,
    titleBn: next.canDo.bn,
    questions: questions,
  );
}

// ── KANA teaching (recognition) — taught IN the sensei classroom ─────────────
// gojūon order, aligned char/romaji/Bengali-sound (matches WritingScreen).
const _hiraChars = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん';
const _kataChars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';
const _kanaRomaji = [
  'a','i','u','e','o','ka','ki','ku','ke','ko','sa','shi','su','se','so',
  'ta','chi','tsu','te','to','na','ni','nu','ne','no','ha','hi','fu','he','ho',
  'ma','mi','mu','me','mo','ya','yu','yo','ra','ri','ru','re','ro','wa','wo','n',
];
const _kanaBnSound = [
  'আ','ই','উ','এ','ও','কা','কি','কু','কে','কো','সা','শি','সু','সে','সো',
  'তা','চি','ৎসু','তে','তো','না','নি','নু','নে','নো','হা','হি','ফু','হে','হো',
  'মা','মি','মু','মে','মো','ইয়া','ইউ','ইয়ো','রা','রি','রু','রে','রো','ওয়া','ও','ন',
];

/// The sensei teaches kana IN the classroom: for each character, an intro
/// line + a "which sound is this?" recognition question with Bengali-sound
/// options. Answer-key graded (the correct sound), D-001/00§4. Deterministic.
ClassroomBatch buildKanaBatch({required bool katakana, int maxItems = 46}) {
  final chars = katakana ? _kataChars : _hiraChars;
  final script = katakana ? 'kana_katakana' : 'kana_hiragana';
  final label = katakana ? 'কাতাকানা' : 'হিরাগানা';
  final n = chars.length.clamp(0, maxItems);
  final questions = <ClassroomQuestion>[];
  for (var i = 0; i < n; i++) {
    final ch = chars[i];
    final correct = _kanaBnSound[i];
    // 3 nearby distractor sounds (deterministic), excluding the answer.
    final distractors = <String>[];
    for (var k = 1; distractors.length < 3 && k <= _kanaBnSound.length; k++) {
      final cand = _kanaBnSound[(i + k) % _kanaBnSound.length];
      if (cand != correct && !distractors.contains(cand)) distractors.add(cand);
    }
    final answerIndex = i % 4;
    final options = [...distractors]..insert(answerIndex, correct);
    final isVowel = i < 5;
    questions.add(ClassroomQuestion(
      itemId: '${script}_$i',
      jp: ch,
      yomi: '', // hidden — recognition is the point
      options: options,
      answerIndex: answerIndex,
      prompt: 'এটি কোন ধ্বনি?',
      introBn: isVowel
          ? 'এই যে — 「$ch」। জাপানির ৫টি মূল স্বরের একটি। বলো "$correct"।'
          : 'এই যে — 「$ch」। ধ্বনি "$correct" (romaji: ${_kanaRomaji[i]})।',
      hint: 'মুখে বলো "$correct" — romaji: ${_kanaRomaji[i]}।',
      noteBn: isVowel
          ? 'দারুণ! এই স্বরগুলোই জাপানি সব অক্ষরের ভিত্তি।'
          : '「$ch」 = "$correct"। Home এর ✍️ Write স্ক্রিনে হাতে লিখেও অনুশীলন করো।',
    ));
  }
  return ClassroomBatch(
    lessonId: script,
    titleBn: '$label — পড়া ও চেনা',
    questions: questions,
  );
}
