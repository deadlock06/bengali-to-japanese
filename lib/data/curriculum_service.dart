// CurriculumService — T-120. Loads the machine ontology
// (assets/curriculum/curriculum.json — single source of truth, see
// docs/CURRICULUM_MAP.md + classroom/CURRICULUM.md §3/§10) and derives
// per-unit progress from lesson_completions.
// D-001: no locks — states are done/current/upcoming, never gated.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/models.dart' show Tri;

enum UnitProgress { done, current, upcoming }

class CurriculumUnit {
  const CurriculumUnit({
    required this.id,
    required this.level,
    required this.title,
    required this.canDo,
    required this.prerequisites,
    required this.lessonIds,
    required this.state,
    required this.pct,
  });

  final String id;
  final String level;

  /// Unit title / can-do goal, trilingual (D-041). Screens render
  /// `title.of(lang)` so they follow the chosen UI language.
  final Tri title;
  final Tri canDo;

  /// Back-compat convenience for Bengali-only call sites.
  String get titleBn => title.bn;
  String get canDoBn => canDo.bn;

  final List<String> prerequisites;
  final List<String> lessonIds;
  final UnitProgress state;
  final double pct;

  /// A kana unit is taught by the finger-draw/kana screen (02 Tier 0 —
  /// "kana + finger-drawing kana"), NOT the vocab classroom. Detected by the
  /// `kana_*` lesson id convention (see CODEBASE_MAP: kana_hiragana/katakana
  /// are SCREENS, not lesson JSONs). The Director routes these to WritingScreen.
  bool get isKana => lessonIds.any((id) => id.startsWith('kana_'));

  /// The kana lesson id this unit completes ('kana_hiragana' / 'kana_katakana'),
  /// or empty if this isn't a kana unit.
  String get kanaLessonId =>
      lessonIds.firstWhere((id) => id.startsWith('kana_'), orElse: () => '');
}

class CurriculumService {
  static const asset = 'assets/curriculum/curriculum.json';

  /// Pure derivation, unit-testable: ontology json + completed lesson ids →
  /// ordered units with states. done = every mapped lesson completed (units
  /// without lessons can't be done yet); current = first not-done unit whose
  /// prerequisites are all done (ladder order); everything else = upcoming.
  static List<CurriculumUnit> derive(
      Map<String, dynamic> root, Set<String> completed) {
    final levels = (root['levels'] as List).cast<Map<String, dynamic>>();
    final levelOrder = {
      for (final l in levels) l['id'] as String: (l['order'] as num).toInt()
    };
    final raw = (root['units'] as List).cast<Map<String, dynamic>>().toList()
      ..sort((a, b) {
        final la = levelOrder[a['level']] ?? 0;
        final lb = levelOrder[b['level']] ?? 0;
        if (la != lb) return la.compareTo(lb);
        return ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0);
      });

    List<String> lessonsOf(Map<String, dynamic> u) {
      final lid = u['lesson_id'];
      if (lid is! String || lid.isEmpty) return const [];
      return lid.split(',').map((s) => s.trim()).toList();
    }

    final doneById = <String, bool>{};
    for (final u in raw) {
      final ls = lessonsOf(u);
      doneById[u['id'] as String] =
          ls.isNotEmpty && ls.every(completed.contains);
    }

    var currentAssigned = false;
    final out = <CurriculumUnit>[];
    for (final u in raw) {
      final id = u['id'] as String;
      final ls = lessonsOf(u);
      final prereqs = ((u['prerequisites'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      final isDone = doneById[id] ?? false;
      final prereqsMet = prereqs.every((p) => doneById[p] ?? false);
      UnitProgress state;
      var pct = 0.0;
      if (isDone) {
        state = UnitProgress.done;
        pct = 1;
      } else if (!currentAssigned && prereqsMet) {
        state = UnitProgress.current;
        currentAssigned = true;
        if (ls.isNotEmpty) {
          pct = ls.where(completed.contains).length / ls.length;
        }
      } else {
        state = UnitProgress.upcoming;
      }
      out.add(CurriculumUnit(
        id: id,
        level: u['level'] as String,
        title: _tri(u['title']),
        canDo: _tri(u['can_do']),
        prerequisites: prereqs,
        lessonIds: ls,
        state: state,
        pct: pct,
      ));
    }
    return out;
  }

  /// Tolerant trilingual parse — falls back to Bengali when en/ja are missing
  /// so partially-authored units still render (never throws).
  static Tri _tri(Object? m) {
    final map = m is Map ? m : const {};
    final bn = (map['bn'] ?? '') as String;
    return Tri(
      en: (map['en'] ?? bn) as String,
      bn: bn,
      ja: (map['ja'] ?? bn) as String,
    );
  }

  static Future<List<CurriculumUnit>> load(Set<String> completed) async {
    final root =
        json.decode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    return derive(root, completed);
  }
}
