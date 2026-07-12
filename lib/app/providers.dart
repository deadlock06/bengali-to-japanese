// Shared Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../agents/agent_bus.dart';
import '../agents/agent_state.dart';
import '../data/book_repository.dart';
import '../data/content_repository.dart';
import '../data/lesson_batch.dart';
import '../data/srs_local.dart';
import '../data/curriculum_service.dart';
import '../domain/fsrs.dart';
import '../domain/models.dart';

/// Selected UI locale (persist via shared_preferences in the full app).
final localeProvider = StateProvider<Locale>((_) => const Locale('bn'));

/// Whether the first-run language screen was completed (v4 onboarding).
/// shared_preferences on purpose — locale is not a secret; Keystore stays
/// DB-key-only (00 §data autonomy / security posture).
final localeChosenProvider = FutureProvider<bool>((_) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('locale_chosen') != null;
});

/// Learner display name for the Home greeting/avatar (Home v4 design,
/// userName prop — design default 'রাফি' until a profile flow exists).
final userNameProvider = FutureProvider<String>((_) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('user_name') ?? 'রাফি';
});

/// Loads the verified content bundle once at startup.
final contentProvider = FutureProvider<ContentRepository>((_) async {
  final repo = ContentRepository();
  await repo.load();
  return repo;
});

/// The FSRS scheduler (pure, stateless) and the encrypted SRS store.
final fsrsProvider = Provider<Fsrs>((_) => const Fsrs());
final srsProvider = Provider<SrsLocal>((_) => SrsLocal());

/// Number of cards currently due for review (drives the Home review card).
final dueCountProvider = FutureProvider<int>((ref) async {
  return ref.read(srsProvider).dueCount();
});

/// The four-agent state bus (04). One per app; sessions restart via
/// [AgentBus.startSession]. UI reads the merged [AgentState] only.
final agentBusProvider =
    StateNotifierProvider<AgentBus, AgentState>((_) => AgentBus());

/// T-120 — curriculum ladder w/ per-unit progress (classroom/CURRICULUM.md §3).
/// Off-device (no DB / widget tests) the completed set is empty → first unit
/// current, everything else upcoming. Never errors.
final curriculumProvider = FutureProvider<List<CurriculumUnit>>((ref) async {
  Set<String> completed = const {};
  try {
    completed = await ref.read(srsProvider).completedLessonIds();
  } catch (_) {/* device-only DB may be absent off-device */}
  return CurriculumService.load(completed);
});

/// T-112 — the AI Classroom's next lesson as answer-key MC questions, selected
/// from the current curriculum unit (rev-3 rule). Deterministic; proof in
/// tools/batch_reference.mjs. null = every wired lesson completed. Off-device
/// (no DB) completed = empty → first lesson, matching curriculumProvider.
final classroomBatchProvider = FutureProvider<ClassroomBatch?>((ref) async {
  final content = await ref.watch(contentProvider.future);
  Set<String> completed = const {};
  try {
    completed = await ref.read(srsProvider).completedLessonIds();
  } catch (_) {/* device-only DB may be absent off-device */}

  final ordered = <Lesson>[];
  try {
    for (final u in await ref.watch(curriculumProvider.future)) {
      for (final id in u.lessonIds) {
        final l = content.lesson(id); // kana/mock ids resolve to null — skipped
        if (l != null && !ordered.contains(l)) ordered.add(l);
      }
    }
  } catch (_) {/* ontology unavailable → fall through to repo order */}
  for (final l in content.lessons) {
    if (!ordered.contains(l)) ordered.add(l);
  }
  return buildClassroomBatch(curriculumOrdered: ordered, completed: completed);
});

/// Bhasha Go book (assets/book/book.json) — T-121 slice.
final bookProvider = FutureProvider<BookRepository>((_) => BookRepository.load());

/// Last book chapter the learner marked read (app_meta). 0 = nothing yet.
final bookReadChapterProvider = FutureProvider<int>((ref) async {
  try {
    final v = await ref.read(srsProvider).getMeta('book_read_ch');
    return int.tryParse(v ?? '') ?? 0;
  } catch (_) {
    return 0; // DB unavailable off-device
  }
});
