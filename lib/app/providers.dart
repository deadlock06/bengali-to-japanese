// Shared Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_repository.dart';
import '../data/srs_local.dart';
import '../domain/fsrs.dart';

/// Selected UI locale (persist via shared_preferences in the full app).
final localeProvider = StateProvider<Locale>((_) => const Locale('bn'));

/// Loads the verified content bundle once at startup.
final contentProvider = FutureProvider<ContentRepository>((_) async {
  final repo = ContentRepository();
  await repo.load();
  return repo;
});

/// The FSRS scheduler (pure, stateless) and the encrypted SRS store.
final fsrsProvider = Provider<Fsrs>((_) => const Fsrs());
final srsProvider = Provider<SrsLocal>((_) => SrsLocal());
