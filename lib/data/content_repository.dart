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
}
