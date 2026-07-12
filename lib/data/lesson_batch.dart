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
  });

  final String itemId, jp, yomi, hint, noteBn;
  final List<String> options;
  final int answerIndex;
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
