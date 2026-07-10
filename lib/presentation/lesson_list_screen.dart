// Lesson picker — all verified lessons grouped by pack (basics → daily →
// work), each opening the 5-step micro-loop. Choosing is always the
// learner's: no locks, no forced order (prerequisites are shown as guidance).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../domain/models.dart';
import 'screens.dart';
import 'widgets.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  static const _packOrder = ['basics', 'daily', 'work'];
  static const _packNames = {
    'basics': 'ভিত্তি · Basics',
    'daily': 'দৈনন্দিন · Daily life',
    'work': 'কাজ · Work',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final lang = ref.watch(localeProvider).languageCode;

    final byPack = <String, List<Lesson>>{};
    for (final l in repo.lessons) {
      byPack.putIfAbsent(l.packId, () => []).add(l);
    }
    final packs = [
      ..._packOrder.where(byPack.containsKey),
      ...byPack.keys.where((p) => !_packOrder.contains(p)),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final pack in packs) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
            child: Text(_packNames[pack] ?? pack,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          for (final lesson in byPack[pack]!)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: BilingualText(lesson.canDo, lang: lang),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${lesson.items.length} শব্দ · ৫ ধাপ',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(lesson.canDo.of(lang))),
                    body: LessonScreen(lessonId: lesson.id),
                  ),
                )),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
