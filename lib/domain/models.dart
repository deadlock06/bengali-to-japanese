// Content models. Meanings/notes are trilingual (en/bn/ja); the Japanese
// target text (jp/kana/romaji) is fixed and never varies with UI language.

/// A string localized into the three supported UI languages.
class Tri {
  final String en, bn, ja;
  const Tri({required this.en, required this.bn, required this.ja});

  factory Tri.fromJson(Map<String, dynamic> j) =>
      Tri(en: j['en'] as String, bn: j['bn'] as String, ja: j['ja'] as String);

  /// Returns the string for a locale code ('en'|'bn'|'ja'), defaulting to en.
  String of(String lang) => lang == 'bn' ? bn : lang == 'ja' ? ja : en;

  /// Lines to render. In Bengali mode we return [bn, en] so the English gloss
  /// backs up any Bengali wording that isn't a perfect fit for the learner.
  /// Other languages return a single line.
  List<String> lines(String lang) => lang == 'bn' ? [bn, en] : [of(lang)];

  /// True when [lines] carries a secondary (English) gloss to de-emphasize.
  bool isBilingual(String lang) => lang == 'bn';
}

/// A single kana character.
class KanaEntry {
  final String id, char, romaji, row;

  /// Bengali picture-story mnemonic (D-034, YouTube kana-method): a shape
  /// association that hooks the glyph to its sound. Empty on older data.
  final String mnemonicBn;
  const KanaEntry(
      {required this.id,
      required this.char,
      required this.romaji,
      required this.row,
      this.mnemonicBn = ''});

  factory KanaEntry.fromJson(Map<String, dynamic> j) => KanaEntry(
        id: j['id'],
        char: j['char'],
        romaji: j['romaji'],
        mnemonicBn: j['mnemonic_bn'] ?? '',
        row: j['row'] ?? '',
      );
}

/// A verified phrase/sentence inside a Can-do lesson.
class LessonItem {
  final String id, jp, kana, romaji;
  final Tri meaning, note;
  final List<String> srsWords;

  /// Optional JLPT exam item-type tag (jlpt.jp 問題 taxonomy) — drives
  /// item-type-granular mock sections. See [ItemType]. Null on the ~714 legacy
  /// items (back-compatible); the mock builder falls back to broad sections.
  final String? itemType;

  const LessonItem({
    required this.id,
    required this.jp,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.note,
    required this.srsWords,
    this.itemType,
  });

  factory LessonItem.fromJson(Map<String, dynamic> j) => LessonItem(
        id: j['id'],
        jp: j['jp'],
        kana: j['kana'],
        romaji: j['romaji'],
        meaning: Tri.fromJson(j['meaning']),
        note: Tri.fromJson(j['note']),
        srsWords: (j['srs_words'] as List).cast<String>(),
        itemType: j['item_type'] as String?,
      );
}

/// The official JLPT exam item types (jlpt.jp "Composition of test items").
/// Content items may be tagged with one of these `id`s so mock exams can build
/// the real 問題 structure per level. Grouped by the section they belong to.
class ItemType {
  static const vocabulary = <String>[
    'kanji_reading', // 漢字読み — read the kanji
    'orthography', // 表記 — choose the correct spelling
    'word_formation', // 語形成 — build the word
    'contextual', // 文脈規定 — contextually-defined expression
    'paraphrase', // 言い換え類義 — paraphrase / synonym
    'usage', // 用法 — correct usage
  ];
  static const grammar = <String>[
    'grammar_form', // 文法形式の判断 — select the grammar form
    'sentence_composition', // 文の組み立て — sentence composition
    'text_grammar', // 文章の文法 — text grammar
  ];
  static const reading = <String>[
    'reading_short', // 内容理解（短文）
    'reading_mid', // 内容理解（中文）
    'reading_long', // 内容理解（長文）
    'reading_integrated', // 統合理解
    'reading_thematic', // 主張理解（長文）
    'info_retrieval', // 情報検索
  ];
  static const listening = <String>[
    'listen_task', // 課題理解 — task-based comprehension
    'listen_keypoint', // ポイント理解 — comprehension of key points
    'listen_outline', // 概要理解 — comprehension of general outline
    'listen_verbal', // 発話表現 — verbal expressions
    'listen_quick', // 即時応答 — quick response
    'listen_integrated', // 統合理解
  ];

  /// All valid item-type ids (validation + tests).
  static const all = <String>[
    ...vocabulary,
    ...grammar,
    ...reading,
    ...listening,
  ];
}

/// A Can-do lesson (exam-aligned unit).
class Lesson {
  final String id;
  final Tri canDo;
  final String jftLevel, source, packId;
  final bool verified;
  final List<LessonItem> items;

  const Lesson({
    required this.id,
    required this.canDo,
    required this.jftLevel,
    required this.source,
    required this.verified,
    required this.items,
    this.packId = '',
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'],
        canDo: Tri.fromJson(j['can_do']),
        jftLevel: j['jlpt_or_jft'] ?? '',
        source: j['source'] ?? '',
        packId: j['pack_id'] ?? '',
        verified: j['verified'] == true,
        items: (j['items'] as List)
            .map((e) => LessonItem.fromJson(e))
            .toList(growable: false),
      );
}

/// A pitch-accent minimal-pair entry. [pattern] is one 0/1 (low/high) per mora.
class PitchItem {
  final String id, word, kanji, romaji;
  final List<int> pattern;
  final Tri meaning, accentType;

  const PitchItem({
    required this.id,
    required this.word,
    required this.kanji,
    required this.romaji,
    required this.pattern,
    required this.meaning,
    required this.accentType,
  });

  factory PitchItem.fromJson(Map<String, dynamic> j) => PitchItem(
        id: j['id'],
        word: j['word'],
        kanji: j['kanji'] ?? '',
        romaji: j['romaji'],
        pattern: (j['pattern'] as List).cast<int>(),
        meaning: Tri.fromJson(j['meaning']),
        accentType: Tri.fromJson(j['accent_type']),
      );
}

class PitchSet {
  final String id, dialect, source;
  final bool verified;
  final List<PitchItem> items;
  const PitchSet({
    required this.id,
    required this.dialect,
    required this.source,
    required this.verified,
    required this.items,
  });

  factory PitchSet.fromJson(Map<String, dynamic> j) => PitchSet(
        id: j['id'],
        dialect: j['dialect'] ?? '',
        source: j['source'] ?? '',
        verified: j['verified'] == true,
        items: (j['items'] as List)
            .map((e) => PitchItem.fromJson(e))
            .toList(growable: false),
      );
}
