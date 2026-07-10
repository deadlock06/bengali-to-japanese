import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../data/srs_local.dart';
import 'whitelist_service.dart';

class CardGenerator {
  final Fsrs _fsrs = const Fsrs();
  final SrsLocal _srsLocal = SrsLocal();

  Future<List<String>> generateCardsForItem(LessonItem item) async {
    final List<String> createdIds = [];
    final whitelist = await WhitelistService.getInstance();
    if (!whitelist.lessonItemPasses(item)) return createdIds;

    for (final word in item.srsWords) {
      try {
        final newCard = ScheduledCard(id: '\${item.id}_\$word', state: CardState.newCard);
        final seededCard = _fsrs.review(newCard, Rating.good);
        await _srsLocal.seedCard(
          id: seededCard.id,
          word: word,
          reading: item.kana,
          meaningBn: item.meaning.bn,
          meaningEn: item.meaning.en,
          jlptLevel: 'N5',
        );
        await _srsLocal.applyReview(_fsrs, seededCard, Rating.good);
        createdIds.add(seededCard.id);
      } catch (_) {}
    }
    return createdIds;
  }

  Future<Map<String, List<String>>> generateCardsForLesson(Lesson lesson) async {
    final result = <String, List<String>>{};
    for (final item in lesson.items) {
      result[item.id] = await generateCardsForItem(item);
    }
    return result;
  }
}
