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
  String? explainOffline(String text) {
    final q = text.trim();
    if (q.isEmpty) return null;

    for (final k in _hiragana) {
      if (k.char == q) return '• ধরন: বর্ণ (Alphabet)\n• অর্থ: জাপানি অক্ষর (হিরাগানা)\n• পড়া: ${k.char} (${k.romaji})\n• ভাঙা: এটি একটি মূল বর্ণ।';
    }
    for (final k in _katakana) {
      if (k.char == q) return '• ধরন: বর্ণ (Alphabet)\n• অর্থ: জাপানি অক্ষর (কাতাকানা)\n• পড়া: ${k.char} (${k.romaji})\n• ভাঙা: এটি একটি মূল বর্ণ।';
    }

    for (final p in _pitchSets) {
      for (final item in p.items) {
        if (item.word == q || item.kanji == q) {
          return '• ধরন: শব্দ (Word)\n• অর্থ: ${item.meaning.bn}\n• পড়া: ${item.word} (${item.romaji})\n• ভাঙা: এটি একটি একক শব্দ।';
        }
      }
    }

    for (final lesson in _lessons.values) {
      for (final item in lesson.items) {
        if (item.jp == q || item.kana == q || item.romaji == q) {
          String s = '• ধরন: বাক্য/শব্দ (Sentence/Word)\n• অর্থ: ${item.meaning.bn}\n• পড়া: ${item.kana} (${item.romaji})';
          if (item.srsWords.isNotEmpty) {
             s += '\n• ভাঙা: ${item.srsWords.join(' + ')}';
          } else {
             s += '\n• ভাঙা: (তথ্য নেই)';
          }
          if (item.note.bn.isNotEmpty) s += '\n\nটিপ: ${item.note.bn}';
          return s;
        }
      }
    }

    for (final lesson in _lessons.values) {
      for (final item in lesson.items) {
        if (item.jp.contains(q) || item.kana.contains(q) || item.meaning.bn.contains(q)) {
          String s = 'অফলাইনে হুবহু "$q" পাইনি, তবে কাছাকাছি একটি বাক্য আছে:\n\n• ধরন: বাক্য (Sentence)\n• অর্থ: ${item.meaning.bn}\n• পড়া: ${item.kana} (${item.romaji})';
          if (item.srsWords.isNotEmpty) {
             s += '\n• ভাঙা: ${item.srsWords.join(' + ')}';
          }
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
