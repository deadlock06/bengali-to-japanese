import 'dart:convert';
import '../domain/models.dart';
import 'whitelist_service.dart';
import 'card_generator.dart';

class ContentImportService {
  final CardGenerator _cardGenerator = CardGenerator();

  Future<void> importLessonFromJson(String jsonString) async {
    final Map<String, dynamic> map = jsonDecode(jsonString);
    final lesson = Lesson.fromJson(map);
    final whitelist = await WhitelistService.getInstance();
    for (final item in lesson.items) {
      if (!whitelist.lessonItemPasses(item)) {
        throw Exception('Item \${item.id} contains non-whitelisted words');
      }
    }
    await _cardGenerator.generateCardsForLesson(lesson);
  }
}
