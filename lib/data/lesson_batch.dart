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
    this.audioKey = '',
    this.gapText = '',
    this.gapOptions = const [],
    this.gapAnswerIndex = -1,
  });

  final String itemId, jp, yomi, hint, noteBn;
  final List<String> options;
  final int answerIndex;

  /// The question the sensei asks — 'এর মানে কী?' for vocab, 'এটি কোন ধ্বনি?'
  /// (which sound?) for kana recognition.
  final String prompt;

  /// The sensei's teaching line shown BEFORE the learner answers (teach → ask).
  final String introBn;

  /// assets/audio manifest key for the 🔊 button (lesson item id for vocab,
  /// 'kana_hira_a' etc. for kana). Empty = no audio.
  final String audioKey;

  /// Phase 4 (Context, 09 micro-loop): gap-fill built by blanking a KNOWN word
  /// inside this sentence (boundary-guarded — only at particle/edge boundaries,
  /// so kana substrings never split mid-word). Empty gapText = no Phase 4.
  final String gapText;
  final List<String> gapOptions;
  final int gapAnswerIndex;
  bool get hasGap => gapText.isNotEmpty;
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

// ── Phase 4 (Context) gap-fill ────────────────────────────────────────────────
const _boundary = 'をがはにでとのへも、 ';
bool _sentencey(String jp) =>
    jp.length > 7 || jp.contains('です') || jp.contains('ます') ||
    jp.contains('か') || jp.contains('ください');

/// Blank a known word inside [jp] — only at particle/edge boundaries so kana
/// never splits mid-word (e.g. せん must NOT match inside いけません).
({String gap, String word})? _findGap(String jp, List<String> wordPool) {
  for (final w in wordPool) {
    if (w == jp) continue;
    var idx = jp.indexOf(w);
    while (idx != -1) {
      final preOk = idx == 0 || _boundary.contains(jp[idx - 1]);
      final after = idx + w.length;
      final nxtOk = after >= jp.length || _boundary.contains(jp[after]);
      if (preOk && nxtOk) {
        return (gap: jp.replaceRange(idx, after, '＿＿'), word: w);
      }
      idx = jp.indexOf(w, idx + 1);
    }
  }
  return null;
}

/// Builds the next lesson's question batch, or null when every candidate
/// lesson is completed (caller decides what "all done" looks like).
ClassroomBatch? buildClassroomBatch({
  required List<Lesson> curriculumOrdered,
  required Set<String> completed,
  int maxItems = 8,
  // Free practice (D-036): teach THIS lesson regardless of completion state —
  // the vocab bank's "অনুশীলন" path. null = normal ladder behaviour.
  String? forceLessonId,
}) {
  Lesson? next;
  if (forceLessonId != null) {
    for (final l in curriculumOrdered) {
      if (l.id == forceLessonId && l.items.isNotEmpty) {
        next = l;
        break;
      }
    }
  } else {
    for (final l in curriculumOrdered) {
      if (!completed.contains(l.id) && l.items.isNotEmpty) {
        next = l;
        break;
      }
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

  // Phase-4 word pool: every verified single WORD in the whole curriculum
  // (≥2 chars), longest first so the most specific word wins the gap.
  final wordPool = <String>{
    for (final l in curriculumOrdered)
      for (final it in l.items)
        if (!_sentencey(it.jp) && it.jp.length >= 2) it.jp,
  }.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

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

    // Phase 4 (Context): gap-fill for sentence items containing a known word.
    var gapText = '';
    var gapOptions = const <String>[];
    var gapAnswer = -1;
    if (_sentencey(it.jp)) {
      final g = _findGap(it.jp, wordPool);
      if (g != null) {
        final ds = <String>[];
        final cands = wordPool.where((w) => w != g.word).toList()
          ..sort((a, b) => _seed('$a${it.id}').compareTo(_seed('$b${it.id}')));
        for (final c in cands) {
          if (ds.length == 3) break;
          ds.add(c);
        }
        if (ds.length == 3) {
          gapAnswer = _seed('gap${it.id}') % 4;
          gapOptions = [...ds]..insert(gapAnswer, g.word);
          gapText = g.gap;
        }
      }
    }

    questions.add(ClassroomQuestion(
      itemId: it.id,
      jp: it.jp,
      yomi: '${it.kana} · ${it.romaji}',
      options: options,
      answerIndex: answerIndex,
      hint: '「$kanaHead」 দিয়ে শুরু — ${it.note.bn}',
      noteBn: it.note.bn,
      audioKey: it.id, // lesson audio is keyed by item id
      gapText: gapText,
      gapOptions: gapOptions,
      gapAnswerIndex: gapAnswer,
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
// gojūon order (46 base) + the 25 voiced/semi-voiced (dakuten ゛ / handakuten ゜)
// that the L0.1 assessment expects (46+25, classroom/CURRICULUM.md §6). Aligned
// char/romaji/Bengali-sound; ぢ/づ reuse じ/ず audio (phonetically identical).
const _hiraChars =
    'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'
    'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ';
const _kataChars =
    'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'
    'ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ';
const _kanaRomaji = [
  'a','i','u','e','o','ka','ki','ku','ke','ko','sa','shi','su','se','so',
  'ta','chi','tsu','te','to','na','ni','nu','ne','no','ha','hi','fu','he','ho',
  'ma','mi','mu','me','mo','ya','yu','yo','ra','ri','ru','re','ro','wa','wo','n',
  // voiced (dakuten) + semi-voiced (handakuten); ぢ→ji, づ→zu reuse clips
  'ga','gi','gu','ge','go','za','ji','zu','ze','zo','da','ji','zu','de','do',
  'ba','bi','bu','be','bo','pa','pi','pu','pe','po',
];
const _kanaBnSound = [
  'আ','ই','উ','এ','ও','কা','কি','কু','কে','কো','সা','শি','সু','সে','সো',
  'তা','চি','ৎসু','তে','তো','না','নি','নু','নে','নো','হা','হি','ফু','হে','হো',
  'মা','মি','মু','মে','মো','ইয়া','ইউ','ইয়ো','রা','রি','রু','রে','রো','ওয়া','ও','ন',
  'গা','গি','গু','গে','গো','জা','জি','জু','জে','জো','দা','জি','জু','দে','দো',
  'বা','বি','বু','বে','বো','পা','পি','পু','পে','পো',
];

/// Index where the voiced/semi-voiced (dakuten ゛/ handakuten ゜) set begins.
const _kanaVoicedStart = 46;

// ── B3: yōon (small ゃゅょ combos) + sokuon/long-vowel demo units ─────────────
// Multi-char units, so they live in (char, romaji, bn) records appended after
// the 71 single-kana items. Writing stays base-46-only (no stroke data here).
const _extHira = [
  ('きゃ','kya','ক্যা'),('きゅ','kyu','কিউ'),('きょ','kyo','কিয়ো'),
  ('しゃ','sha','শা'),('しゅ','shu','শু'),('しょ','sho','শো'),
  ('ちゃ','cha','চা'),('ちゅ','chu','চু'),('ちょ','cho','চো'),
  ('にゃ','nya','নিয়া'),('にゅ','nyu','নিউ'),('にょ','nyo','নিয়ো'),
  ('ひゃ','hya','হিয়া'),('ひゅ','hyu','হিউ'),('ひょ','hyo','হিয়ো'),
  ('みゃ','mya','মিয়া'),('みゅ','myu','মিউ'),('みょ','myo','মিয়ো'),
  ('りゃ','rya','রিয়া'),('りゅ','ryu','রিউ'),('りょ','ryo','রিয়ো'),
  ('ぎゃ','gya','গিয়া'),('ぎゅ','gyu','গিউ'),('ぎょ','gyo','গিয়ো'),
  ('じゃ','ja','জা'),('じゅ','ju','জু'),('じょ','jo','জো'),
  ('びゃ','bya','বিয়া'),('びゅ','byu','বিউ'),('びょ','byo','বিয়ো'),
  ('ぴゃ','pya','পিয়া'),('ぴゅ','pyu','পিউ'),('ぴょ','pyo','পিয়ো'),
  // demos: sokuon (double/stop) + hiragana long vowel
  ('きって','kitte','কিত্তে (মাঝে থামা)'),
  ('おかあさん','okaasan','ওকাআসান (টানা আ)'),
];
const _extKata = [
  ('キャ','kya','ক্যা'),('キュ','kyu','কিউ'),('キョ','kyo','কিয়ো'),
  ('シャ','sha','শা'),('シュ','shu','শু'),('ショ','sho','শো'),
  ('チャ','cha','চা'),('チュ','chu','চু'),('チョ','cho','চো'),
  ('ニャ','nya','নিয়া'),('ニュ','nyu','নিউ'),('ニョ','nyo','নিয়ো'),
  ('ヒャ','hya','হিয়া'),('ヒュ','hyu','হিউ'),('ヒョ','hyo','হিয়ো'),
  ('ミャ','mya','মিয়া'),('ミュ','myu','মিউ'),('ミョ','myo','মিয়ো'),
  ('リャ','rya','রিয়া'),('リュ','ryu','রিউ'),('リョ','ryo','রিয়ো'),
  ('ギャ','gya','গিয়া'),('ギュ','gyu','গিউ'),('ギョ','gyo','গিয়ো'),
  ('ジャ','ja','জা'),('ジュ','ju','জু'),('ジョ','jo','জো'),
  ('ビャ','bya','বিয়া'),('ビュ','byu','বিউ'),('ビョ','byo','বিয়ো'),
  ('ピャ','pya','পিয়া'),('ピュ','pyu','পিউ'),('ピョ','pyo','পিয়ো'),
  // demos: katakana sokuon + the ー long-vowel mark
  ('カップ','kappu','কাপ্পু (মাঝে থামা)'),
  ('コーヒー','koohii','কোওহিই (ー=টানা)'),
];

/// The sensei teaches kana IN the classroom: for each character, an intro
/// line + a "which sound is this?" recognition question with Bengali-sound
/// options. Answer-key graded (the correct sound), D-001/00§4. Deterministic.
ClassroomBatch buildKanaBatch({required bool katakana, int maxItems = 200}) {
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
    final isVoiced = i >= _kanaVoicedStart; // dakuten ゛/ handakuten ゜ set
    final isHandakuten = isVoiced && _kanaBnSound[i].startsWith('প'); // ぱ-row
    questions.add(ClassroomQuestion(
      itemId: '${script}_$i',
      jp: ch,
      yomi: '', // hidden — recognition is the point
      options: options,
      answerIndex: answerIndex,
      prompt: 'এটি কোন ধ্বনি?',
      introBn: isVowel
          ? 'এই যে — 「$ch」। জাপানির ৫টি মূল স্বরের একটি। বলো "$correct"।'
          : isVoiced
              ? 'এই যে — 「$ch」। মূল অক্ষরে ${isHandakuten ? '"゜" (maru)' : '"゛" (ten-ten)'} '
                  'যোগ হয়ে ধ্বনি "$correct" (romaji: ${_kanaRomaji[i]})।'
              : 'এই যে — 「$ch」। ধ্বনি "$correct" (romaji: ${_kanaRomaji[i]})।',
      hint: 'মুখে বলো "$correct" — romaji: ${_kanaRomaji[i]}।',
      noteBn: isVowel
          ? 'দারুণ! এই স্বরগুলোই জাপানি সব অক্ষরের ভিত্তি।'
          : isVoiced
              ? '${isHandakuten ? '"゜" (maru)' : '"゛" (ten-ten)'} চিহ্নে ধ্বনি বদলায় — '
                  'যেমন か→が, は→ば→ぱ। এটাই dakuten/handakuten।'
              : '「$ch」 = "$correct"। চেনার পরে এটা হাতে লিখবেও — সেনসেই stroke-order দেখিয়ে দেবে।',
      audioKey: 'kana_${katakana ? "kata" : "hira"}_${_kanaRomaji[i]}',
    ));
  }

  // B3 — yōon + sokuon/long-vowel: taught after the 71 singles, with the
  // combination RULE in every intro (small ゃゅょ merges; っ = stop; ー = stretch).
  final ext = katakana ? _extKata : _extHira;
  final extBn = [for (final e in ext) e.$3];
  for (var i = 0; i < ext.length && questions.length < maxItems; i++) {
    final (ch, romaji, bn) = ext[i];
    final distractors = <String>[];
    for (var k = 1; distractors.length < 3 && k <= extBn.length; k++) {
      final cand = extBn[(i + k) % extBn.length];
      if (cand != bn && !distractors.contains(cand)) distractors.add(cand);
    }
    final answerIndex = (71 + i) % 4;
    final options = [...distractors]..insert(answerIndex, bn);
    final isYoon = i < 33;
    final isSokuon = romaji == 'kitte' || romaji == 'kappu';
    questions.add(ClassroomQuestion(
      itemId: '${script}_ext_$i',
      jp: ch,
      yomi: '',
      options: options,
      answerIndex: answerIndex,
      prompt: 'এটি কোন ধ্বনি?',
      introBn: isYoon
          ? 'এই যে — 「$ch」। ছোট ゃ/ゅ/ょ আগের অক্ষরের সাথে মিশে এক ধ্বনি: "$bn" ($romaji)। আলাদা করে পোড়ো না!'
          : isSokuon
              ? 'এই যে — 「$ch」। ছোট্ট っ মানে এক মুহূর্তের থামা: "$bn"। থামাটা না দিলে অন্য শব্দ হয়ে যায়!'
              : 'এই যে — 「$ch」। লম্বা স্বর — টেনে বলো: "$bn"। ছোট করলে মানে বদলে যায় (おばさん≠おばあさん)!',
      hint: 'মুখে বলো "$bn" — romaji: $romaji।',
      noteBn: isYoon
          ? 'ছোট ゃゅょ = যুক্ত-ধ্বনি (yōon)। きや (কিয়া, ২ ধ্বনি) আর きゃ (ক্যা, ১ ধ্বনি) — পার্থক্যটা কানে গেঁথে নাও।'
          : isSokuon
              ? 'っ (sokuon) = দ্বিগুণ ব্যঞ্জন — きて(এসো) vs きって(ডাকটিকিট)। থামাই অর্থ বদলায়!'
              : 'লম্বা স্বর (long vowel) — হিরাগানায় স্বর দ্বিগুণ, কাতাকানায় ー দাগ।',
      audioKey: 'kana_${katakana ? "kata" : "hira"}_$romaji',
    ));
  }

  return ClassroomBatch(
    lessonId: script,
    titleBn: '$label — পড়া ও চেনা',
    questions: questions,
  );
}
