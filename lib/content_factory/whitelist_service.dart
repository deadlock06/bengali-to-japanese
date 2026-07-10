import 'package:flutter/services.dart';
import '../domain/models.dart';

class WhitelistService {
  static WhitelistService? _instance;
  static Future<WhitelistService> getInstance() async {
    _instance ??= WhitelistService._();
    await _instance!._load();
    return _instance!;
  }

  final Set<String> _words = {};
  bool _loaded = false;

  WhitelistService._();

  Future<void> _load() async {
    if (_loaded) return;
    try {
      final data = await rootBundle.loadString('assets/content_factory/jft_a2_whitelist.txt');
      for (final line in data.split('\n')) {
        final word = line.trim();
        if (word.isNotEmpty && !word.startsWith('#')) _words.add(word);
      }
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
  }

  bool isWhitelisted(String word) => _words.contains(word);
  bool lessonItemPasses(LessonItem item) => item.srsWords.every(isWhitelisted);
}
