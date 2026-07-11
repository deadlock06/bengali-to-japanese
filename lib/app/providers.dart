// Shared Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../agents/agent_bus.dart';
import '../agents/agent_state.dart';
import '../data/content_repository.dart';
import '../data/srs_local.dart';
import '../data/curriculum_service.dart';
import '../domain/fsrs.dart';

/// Selected UI locale (persist via shared_preferences in the full app).
final localeProvider = StateProvider<Locale>((_) => const Locale('bn'));

/// Whether the first-run language screen was completed (v4 onboarding).
/// shared_preferences on purpose — locale is not a secret; Keystore stays
/// DB-key-only (00 §data autonomy / security posture).
final localeChosenProvider = FutureProvider<bool>((_) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('locale_chosen') != null;
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
final curriculumProvider = FutureProvider<List<CurriculumUnit>>((ref) async {
  final completed = await ref.read(srsProvider).completedLessonIds();
  return CurriculumService.load(completed);
});
