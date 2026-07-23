// Loads VERIFIED content from bundled JSON assets. This repository is the only
// authoritative source of Japanese the learner is taught — the LLM never adds
// to it at runtime.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models.dart';

class ContentRepository {
  List<KanaEntry> _hiragana = const [];
  List<KanaEntry> _katakana = const [];
  final Map<String, Lesson> _lessons = {};
  final List<PitchSet> _pitchSets = [];

  Future<List<KanaEntry>> _loadKana(String file) async {
    final data = json.decode(await rootBundle.loadString(file)) as Map<String, dynamic>;
    return (data['items'] as List).map((e) => KanaEntry.fromJson(e)).toList(growable: false);
  }

  Future<void> load() async {
    _hiragana = await _loadKana('assets/content/hiragana.json');
    _katakana = await _loadKana('assets/content/katakana.json');

    for (final file in const [
      'assets/content/lesson_greetings.json',
      'assets/content/lesson_work_intro.json',
      'assets/content/lesson_numbers.json',
      'assets/content/lesson_numbers_big.json',
      'assets/content/lesson_counters.json',
      'assets/content/lesson_week.json',
      'assets/content/lesson_food.json',
      'assets/content/lesson_polite.json',
      'assets/content/lesson_family.json',
      'assets/content/lesson_about_me.json',
      'assets/content/lesson_taste.json',
      'assets/content/lesson_shopping_adj.json',
      'assets/content/lesson_places.json',
      'assets/content/lesson_work_day.json',
      'assets/content/lesson_requests_2.json',
      'assets/content/lesson_frequency.json',
      'assets/content/lesson_problems.json',
      'assets/content/lesson_responses.json',
      'assets/content/lesson_clothes.json',
      'assets/content/lesson_drinks.json',
      'assets/content/lesson_body.json',
      'assets/content/lesson_vehicles.json',
      'assets/content/lesson_daily_verbs.json',
      'assets/content/lesson_work_verbs.json',
      'assets/content/lesson_work_phrases.json',
      'assets/content/lesson_permissions.json',
      'assets/content/lesson_symptoms.json',
      'assets/content/lesson_trouble_talk.json',
      'assets/content/lesson_hobbies.json',
      'assets/content/lesson_shop_talk.json',
      'assets/content/lesson_restaurant_talk.json',
      'assets/content/lesson_work_things.json',
      'assets/content/lesson_directions_words.json',
      'assets/content/lesson_learning_questions.json',
      'assets/content/lesson_weather.json',
      'assets/content/lesson_countries.json',
      'assets/content/lesson_work_team.json',
      'assets/content/lesson_medicine.json',
      'assets/content/lesson_stations.json',
      'assets/content/lesson_travel_manners.json',
      'assets/content/lesson_events.json',
      'assets/content/lesson_feelings.json',
      'assets/content/lesson_hygiene.json',
      'assets/content/lesson_asking_actions.json',
      'assets/content/lesson_te_now.json',
      'assets/content/lesson_te_state.json',
      'assets/content/lesson_te_sequence.json',
      'assets/content/lesson_te_rules.json',
      'assets/content/lesson_te_requests.json',
      'assets/content/lesson_te_try.json',
      'assets/content/lesson_te_giving.json',
      'assets/content/lesson_plain_present.json',
      'assets/content/lesson_plain_negative.json',
      'assets/content/lesson_plain_past.json',
      'assets/content/lesson_casual_talk.json',
      'assets/content/lesson_casual_questions.json',
      'assets/content/lesson_plain_think.json',
      'assets/content/lesson_casual_register.json',
      'assets/content/lesson_can_do.json',
      'assets/content/lesson_cannot_do.json',
      'assets/content/lesson_can_ask.json',
      'assets/content/lesson_dekiru_skills.json',
      'assets/content/lesson_can_work.json',
      'assets/content/lesson_can_life.json',
      'assets/content/lesson_give_triangle.json',
      'assets/content/lesson_give_things.json',
      'assets/content/lesson_give_polite.json',
      'assets/content/lesson_give_favors.json',
      'assets/content/lesson_give_situations.json',
      'assets/content/lesson_keigo_hear.json',
      'assets/content/lesson_keigo_humble.json',
      'assets/content/lesson_keigo_shop.json',
      'assets/content/lesson_keigo_work.json',
      'assets/content/lesson_keigo_phone.json',
      'assets/content/lesson_keigo_rules.json',
      'assets/content/lesson_konbini.json',
      'assets/content/lesson_shopping.json',
      'assets/content/lesson_clinic.json',
      'assets/content/lesson_time.json',
      'assets/content/lesson_directions.json',
      'assets/content/lesson_transport.json',
      'assets/content/lesson_emergency.json',
      'assets/content/lesson_smalltalk.json',
      'assets/content/lesson_restaurant.json',
      'assets/content/lesson_workplace.json',
      'assets/content/lesson_work_safety.json',
      'assets/content/lesson_work_requests.json',
      'assets/content/lesson_intro_qa.json',
      'assets/content/lesson_past_plans.json',
      'assets/content/lesson_apology.json',
    ]) {
      final lesson = Lesson.fromJson(json.decode(await rootBundle.loadString(file)));
      assert(lesson.verified, 'Refusing to load unverified lesson ${lesson.id}');
      _lessons[lesson.id] = lesson;
    }

    for (final file in const ['assets/content/pitch_accent.json']) {
      final set = PitchSet.fromJson(json.decode(await rootBundle.loadString(file)));
      assert(set.verified, 'Refusing to load unverified pitch set ${set.id}');
      _pitchSets.add(set);
    }
  }

  List<KanaEntry> get hiragana => _hiragana;
  List<KanaEntry> get katakana => _katakana;
  Lesson? lesson(String id) => _lessons[id];
  Iterable<Lesson> get lessons => _lessons.values;
  List<PitchSet> get pitchSets => _pitchSets;

  /// Offline dictionary fallback: searches the local curriculum for a match.
  /// [lang] localizes the field labels + prose (D-041) so an English/Japanese
  /// learner's offline sensei answer matches their UI language; the meaning
  /// itself comes from the trilingual `Tri`.
  String? explainOffline(String text, {String lang = 'bn'}) {
    final q = text.trim();
    if (q.isEmpty) return null;
    // Localized field labels for the offline card.
    String L(String bn, String en, String ja) =>
        lang == 'en' ? en : lang == 'ja' ? ja : bn;
    final lType = L('ধরন', 'Type', '種類');
    final lMean = L('অর্থ', 'Meaning', '意味');
    final lRead = L('পড়া', 'Reading', '読み');
    final lBreak = L('ভাঙা', 'Breakdown', '分解');
    final lTip = L('টিপ', 'Tip', 'ヒント');
    final letter = L('বর্ণ', 'letter', '文字');
    final single = L('এটি একটি মূল বর্ণ।', 'A base letter.', '基本の文字。');

    for (final k in _hiragana) {
      if (k.char == q) return '• $lType: $letter (${L('হিরাগানা', 'Hiragana', 'ひらがな')})\n• $lRead: ${k.char} (${k.romaji})\n• $lBreak: $single';
    }
    for (final k in _katakana) {
      if (k.char == q) return '• $lType: $letter (${L('কাতাকানা', 'Katakana', 'カタカナ')})\n• $lRead: ${k.char} (${k.romaji})\n• $lBreak: $single';
    }

    final word = L('শব্দ', 'Word', '単語');
    for (final p in _pitchSets) {
      for (final item in p.items) {
        if (item.word == q || item.kanji == q) {
          return '• $lType: $word\n• $lMean: ${item.meaning.of(lang)}\n• $lRead: ${item.word} (${item.romaji})\n• $lBreak: ${L('একটি একক শব্দ।', 'A single word.', '一つの単語。')}';
        }
      }
    }

    final sentence = L('বাক্য/শব্দ', 'Sentence/Word', '文/単語');
    final noData = L('(তথ্য নেই)', '(no data)', '(データなし)');
    for (final lesson in _lessons.values) {
      for (final item in lesson.items) {
        if (item.jp == q || item.kana == q || item.romaji == q) {
          String s = '• $lType: $sentence\n• $lMean: ${item.meaning.of(lang)}\n• $lRead: ${item.kana} (${item.romaji})';
          s += item.srsWords.isNotEmpty
              ? '\n• $lBreak: ${item.srsWords.join(' + ')}'
              : '\n• $lBreak: $noData';
          if (item.note.of(lang).isNotEmpty) s += '\n\n$lTip: ${item.note.of(lang)}';
          return s;
        }
      }
    }

    for (final lesson in _lessons.values) {
      for (final item in lesson.items) {
        if (item.jp.contains(q) || item.kana.contains(q) || item.meaning.bn.contains(q)) {
          final near = L('অফলাইনে হুবহু "$q" পাইনি, তবে কাছাকাছি একটি বাক্য আছে:',
              'No exact offline match for "$q", but here\'s a close one:',
              'オフラインで「$q」の完全一致はないけど、近いものがあるよ:');
          String s = '$near\n\n• $lType: ${L('বাক্য', 'Sentence', '文')}\n• $lMean: ${item.meaning.of(lang)}\n• $lRead: ${item.kana} (${item.romaji})';
          if (item.srsWords.isNotEmpty) s += '\n• $lBreak: ${item.srsWords.join(' + ')}';
          return s;
        }
      }
    }

    return null;
  }

  /// Offline chat handler for specific quick-chips when AI is unavailable.
  String? handleOfflineChat(String query, String contextJp) {
    final q = query.trim();
    if (contextJp.isEmpty) return null;

    LessonItem? foundItem;
    for (final lesson in _lessons.values) {
      for (final item in lesson.items) {
        if (item.jp == contextJp || item.kana == contextJp) {
          foundItem = item;
          break;
        }
      }
      if (foundItem != null) break;
    }

    if (foundItem != null) {
      if (q == 'উচ্চারণ ভেঙে দাও' || q == 'উচ্চারণ') {
        String res = '「${foundItem.jp}」 এর উচ্চারণ হলো: ${foundItem.kana} (${foundItem.romaji})।';
        if (foundItem.srsWords.isNotEmpty) {
          res += '\nশব্দগুলো আলাদা করলে: ${foundItem.srsWords.join(' + ')}';
        }
        return res;
      }
      if (q == 'আবার বুঝিয়ে দাও' || q == 'সহজ করে বলো') {
         return 'সহজভাবে বললে, 「${foundItem.jp}」 মানে ${foundItem.meaning.bn}।\n${foundItem.note.bn}';
      }
      if (q == 'কোথায় ব্যবহার হয়') {
         if (foundItem.note.bn.isNotEmpty) return foundItem.note.bn;
         return 'এটি সাধারণ কথাবার্তায় ব্যবহার হয়।';
      }
      if (q == 'একটা উদাহরণ' || q == 'আরেকটা উদাহরণ') {
         return 'দুঃখিত, অফলাইনে নতুন উদাহরণ তৈরি করা যাচ্ছে না। তবে এর মানে: ${foundItem.meaning.bn}।';
      }
    }

    KanaEntry? foundKana;
    for (final k in _hiragana) {
      if (k.char == contextJp) foundKana = k;
    }
    for (final k in _katakana) {
      if (k.char == contextJp) foundKana = k;
    }
    if (foundKana != null) {
      if (q == 'উচ্চারণ ভেঙে দাও' || q == 'উচ্চারণ') {
        return '「${foundKana.char}」 এর উচ্চারণ হলো "${foundKana.romaji}"। এটি একটি মূল বর্ণ, তাই আর ভাঙা যাবে না।';
      }
      if (q == 'আবার বুঝিয়ে দাও' || q == 'সহজ করে বলো') {
         return 'সহজভাবে বললে, 「${foundKana.char}」 হলো একটি জাপানি বর্ণ। এর উচ্চারণ: ${foundKana.romaji}।';
      }
      if (q == 'কোথায় ব্যবহার হয়') {
         return 'এটি জাপানি ভাষার একটি মৌলিক বর্ণ যা বিভিন্ন শব্দ তৈরিতে ব্যবহার হয়।';
      }
      if (q == 'একটা উদাহরণ' || q == 'আরেকটা উদাহরণ') {
         return 'অফলাইনে উদাহরণ দেখানো যাচ্ছে না, তবে এটি একটি জাপানি বর্ণ।';
      }
    }

    PitchItem? foundPitch;
    for (final p in _pitchSets) {
      for (final item in p.items) {
        if (item.word == contextJp || item.kanji == contextJp) {
          foundPitch = item;
          break;
        }
      }
      if (foundPitch != null) break;
    }
    if (foundPitch != null) {
      final title = foundPitch.kanji.isEmpty ? foundPitch.word : foundPitch.kanji;
      if (q == 'উচ্চারণ ভেঙে দাও' || q == 'উচ্চারণ') {
        return '「$title」 এর উচ্চারণ হলো: ${foundPitch.word} (${foundPitch.romaji})।';
      }
      if (q == 'আবার বুঝিয়ে দাও' || q == 'সহজ করে বলো') {
         return 'সহজভাবে বললে, 「$title」 মানে ${foundPitch.meaning.bn}।';
      }
      if (q == 'কোথায় ব্যবহার হয়') {
         return 'অফলাইনে বিস্তারিত ব্যবহার দেখানো যাচ্ছে না। তবে অর্থ হলো: ${foundPitch.meaning.bn}।';
      }
      if (q == 'একটা উদাহরণ' || q == 'আরেকটা উদাহরণ') {
         return 'অফলাইনে নতুন উদাহরণ তৈরি করা যাচ্ছে না। তবে এর মানে: ${foundPitch.meaning.bn}।';
      }
    }

    // Generic fallback for any other text when clicking a chip
    if (q == 'উচ্চারণ ভেঙে দাও' || q == 'উচ্চারণ') {
      return 'অফলাইনে বিস্তারিত উচ্চারণ দেখানো যাচ্ছে না। তবে মূল টেক্সট: 「$contextJp」';
    }
    return 'অফলাইনে এই বিষয়ে বিস্তারিত বলা যাচ্ছে না। ইন্টারনেট বা AI key থাকলে সেনসেই সাহায্য করতে পারত।';
  }
}
