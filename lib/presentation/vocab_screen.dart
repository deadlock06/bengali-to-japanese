// শব্দভাণ্ডার — the browsable vocabulary bank (D-035). One place to see EVERY
// word in the course: search it, hear it, and see your real learning status.
//
// Status is the SRS truth, never a guess (correctness over generation):
//   🟢 আয়ত্তে   — FSRS stability ≥ 7 days (mastered, D-031 definition)
//   🟡 শিখছি    — seeded into SRS (met in the classroom, still fragile)
//   ⚪ সামনে     — in the course, not met yet
// Grouping follows the live curriculum order (same ladder the classroom
// teaches). Browsing is free — nothing is locked (D-001).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/audio_service.dart';
import '../domain/models.dart';
import 'lesson_screen_v4.dart';
import 'sensei_chat_sheet.dart';
import 'state_pack.dart';

class VocabScreen extends ConsumerStatefulWidget {
  const VocabScreen({super.key});

  @override
  ConsumerState<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends ConsumerState<VocabScreen> {
  String _query = '';

  /// itemId → FSRS stability (days). Absent = never seeded.
  Map<String, double>? _stability;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final cards = await ref.read(srsProvider).allCards();
      if (mounted) {
        setState(() => _stability = {
              for (final c in cards) c.card.id: c.card.stability,
            });
      }
    } catch (_) {
      if (mounted) setState(() => _stability = const {}); // off-device DB
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(contentProvider).valueOrNull;
    final units = ref.watch(curriculumProvider).valueOrNull;
    if (repo == null) {
      return const Scaffold(
          body: StatePack.loading(bn: 'শব্দ লোড হচ্ছে…'));
    }

    // Lessons in curriculum-ladder order (same order the classroom teaches),
    // then any unwired lessons at the end.
    final ordered = <Lesson>[];
    if (units != null) {
      for (final u in units) {
        for (final id in u.lessonIds) {
          final l = repo.lesson(id);
          if (l != null && !ordered.contains(l)) ordered.add(l);
        }
      }
    }
    for (final l in repo.lessons) {
      if (!ordered.contains(l)) ordered.add(l);
    }

    final q = _query.trim().toLowerCase();
    bool match(LessonItem it) =>
        q.isEmpty ||
        it.jp.toLowerCase().contains(q) ||
        it.kana.toLowerCase().contains(q) ||
        it.romaji.toLowerCase().contains(q) ||
        it.meaning.bn.toLowerCase().contains(q) ||
        it.meaning.en.toLowerCase().contains(q);

    final sections = <(Lesson, List<LessonItem>)>[
      for (final l in ordered)
        if (l.items.where(match).isNotEmpty) (l, l.items.where(match).toList())
    ];
    final total = ordered.fold<int>(0, (a, l) => a + l.items.length);
    final learned =
        _stability == null ? 0 : _stability!.length;
    final mastered = _stability == null
        ? 0
        : _stability!.values.where((s) => s >= 7.0).length;

    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      appBar: AppBar(title: const Text('শব্দভাণ্ডার · Vocabulary')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'খোঁজো — বাংলা, জাপানি বা romaji…',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            _Legend(color: BhasagoColors.green, label: 'আয়ত্তে $mastered'),
            const SizedBox(width: 12),
            _Legend(color: BhasagoColors.yellow, label: 'শিখছি ${learned - mastered}'),
            const SizedBox(width: 12),
            _Legend(
                color: BhasagoTheme.muted, label: 'মোট $total শব্দ'),
          ]),
        ),
        Expanded(
          child: sections.isEmpty
              ? const StatePack.empty(
                  title: 'কিছু পাওয়া যায়নি',
                  body: 'অন্যভাবে লিখে খুঁজে দেখো — বাংলা মানে দিয়েও খোঁজা যায়।',
                  emoji: '🔍')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: sections.length,
                  itemBuilder: (_, i) {
                    final (lesson, items) = sections[i];
                    return _LessonBlock(
                      lesson: lesson,
                      items: items,
                      stability: _stability ?? const {},
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: BhasagoTheme.muted)),
      ]);
}

class _LessonBlock extends ConsumerWidget {
  final Lesson lesson;
  final List<LessonItem> items;
  final Map<String, double> stability;
  const _LessonBlock(
      {required this.lesson, required this.items, required this.stability});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(lesson.canDo.of(lang == 'bn' ? 'bn' : 'en'),
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text('${items.length}টি শব্দ',
            style: const TextStyle(fontSize: 11.5, color: BhasagoTheme.muted)),
        children: [
          // Free practice (D-036): run THIS lesson in the classroom anytime —
          // recommend-never-force means old lessons are always re-practicable.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.school_outlined, size: 16),
                label: const Text('ক্লাসরুমে অনুশীলন করো'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        LessonScreenV4(practiceLessonId: lesson.id))),
              ),
            ),
          ),
          for (final it in items)
            ListTile(
              dense: true,
              leading: _statusDot(it.id),
              title: Text(
                  (ref.watch(romajiShownProvider).valueOrNull ?? true)
                      ? '${it.jp}  ·  ${it.romaji}'
                      : it.jp,
                  style: const TextStyle(
                      fontFamily: 'ZenKakuGothicNew',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              subtitle: Text(it.meaning.bn,
                  style: const TextStyle(fontSize: 12.5)),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up, size: 20),
                tooltip: 'শোনো',
                onPressed: () => AudioService.instance.play(it.id),
              ),
              // Tap = ask the sensei about this exact word (same unified chat).
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SenseiChatSheet(
                  accent: BhasagoColors.yellow,
                  moodLabel: 'শব্দ',
                  seedText: it.jp,
                  chatKey: 'vocab:${it.id}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusDot(String id) {
    final s = stability[id];
    final color = s == null
        ? BhasagoTheme.muted
        : s >= 7.0
            ? BhasagoColors.green
            : BhasagoColors.yellow;
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
