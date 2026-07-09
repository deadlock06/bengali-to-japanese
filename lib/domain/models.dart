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
  const KanaEntry(
      {required this.id,
      required this.char,
      required this.romaji,
      required this.row});

  factory KanaEntry.fromJson(Map<String, dynamic> j) => KanaEntry(
        id: j['id'],
        char: j['char'],
        romaji: j['romaji'],
        row: j['row'] ?? '',
      );
}

/// A verified phrase/sentence inside a Can-do lesson.
class LessonItem {
  final String id, jp, kana, romaji;
  final Tri meaning, note;
  final List<String> srsWords;

  const LessonItem({
    required this.id,
    required this.jp,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.note,
    required this.srsWords,
  });

  factory LessonItem.fromJson(Map<String, dynamic> j) => LessonItem(
        id: j['id'],
        jp: j['jp'],
        kana: j['kana'],
        romaji: j['romaji'],
        meaning: Tri.fromJson(j['meaning']),
        note: Tri.fromJson(j['note']),
        srsWords: (j['srs_words'] as List).cast<String>(),
      );
}

/// A Can-do lesson (exam-aligned unit).
class Lesson {
  final String id;
  final Tri canDo;
  final String jftLevel, source;
  final bool verified;
  final List<LessonItem> items;

  const Lesson({
    required this.id,
    required this.canDo,
    required this.jftLevel,
    required this.source,
    required this.verified,
    required this.items,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'],
        canDo: Tri.fromJson(j['can_do']),
        jftLevel: j['jlpt_or_jft'] ?? '',
        source: j['source'] ?? '',
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
