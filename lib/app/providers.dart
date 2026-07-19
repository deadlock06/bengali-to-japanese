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

/// Concepts learned "perfectly" (D-031 / docs/14): words whose FSRS stability
/// is ≥ 7 days — i.e. the memory model says they'll stick for a week+ without
/// review. This is the REAL mastery signal that feeds the Progress screen;
/// never a guess, never LLM-judged. 0 off-device (DB absent).
final masteredCountProvider = FutureProvider<int>((ref) async {
  try {
    return await ref.read(srsProvider).retainedWordCount();
  } catch (_) {
    return 0;
  }
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

/// The learner's GOAL (D-015): 'ssw' | 'jlpt' | 'daily' | '' (unchosen).
/// Changes journey-map EMPHASIS/recommendation only — never content or locks.
final goalProvider = FutureProvider<String>((_) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('goal') ?? '';
});

Future<void> setGoal(String g) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('goal', g);
}

/// The learner's current curriculum level (L0/A1/A2/N4) — drives the sensei's
/// dynamic BN↔JP language balance (13_MASTER_VISION: beginner 80–90% Bengali →
/// advanced 80–90% Japanese). Derived from the current unit; L0 when unknown.
final learnerLevelProvider = FutureProvider<String>((ref) async {
  try {
    final units = await ref.watch(curriculumProvider.future);
    for (final u in units) {
      if (u.state == UnitProgress.current) return u.level;
    }
    // Everything done → the learner works at the top authored level.
    return units.isEmpty ? 'L0' : units.last.level;
  } catch (_) {
    return 'L0';
  }
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

  // The classroom teaches the CURRENT unit. A kana unit is taught right here —
  // sensei-led recognition ("এটি কোন ধ্বনি?") — NOT a separate tool. So a
  // beginner meets hiragana IN the classroom, then flows into vocab.
  try {
    final units = await ref.watch(curriculumProvider.future);
    for (final u in units) {
      if (u.state == UnitProgress.current) {
        if (u.isKana) {
          return buildKanaBatch(katakana: u.kanaLessonId.contains('katakana'));
        }
        break;
      }
    }
  } catch (_) {/* ontology unavailable → fall through to vocab */}

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

/// Free-practice batch for ONE specific lesson (D-036, vocab-bank অনুশীলন).
/// Same deterministic answer-key builder as the classroom; completion state is
/// ignored so any lesson can be practiced anytime (no locks, D-001).
final practiceBatchProvider =
    FutureProvider.family<ClassroomBatch?, String>((ref, lessonId) async {
  final content = await ref.watch(contentProvider.future);
  final ordered = <Lesson>[];
  try {
    for (final u in await ref.watch(curriculumProvider.future)) {
      for (final id in u.lessonIds) {
        final l = content.lesson(id);
        if (l != null && !ordered.contains(l)) ordered.add(l);
      }
    }
  } catch (_) {/* ontology unavailable → repo order below */}
  for (final l in content.lessons) {
    if (!ordered.contains(l)) ordered.add(l);
  }
  return buildClassroomBatch(
      curriculumOrdered: ordered, completed: const {}, forceLessonId: lessonId);
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
