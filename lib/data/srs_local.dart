// Local SRS persistence (SQLite via SQLCipher — encrypted at rest). Stores
// scheduled cards and review history offline. FSRS math lives in domain/fsrs.dart.
// Schema is owned by the numbered migrations in db/migrations/ (never inlined here).

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../db/db_key.dart';
import '../db/migrations/migration.dart';
import '../db/migrations/registry.dart';

class SrsLocal {
  SrsLocal({DbKey? dbKey}) : _dbKey = dbKey ?? DbKey();

  final DbKey _dbKey;
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final password = await _dbKey.obtain();
    _db = await openDatabase(
      p.join(dir, 'sensei.db'),
      password: password, // SQLCipher AES-256 — user data encrypted at rest (T-101)
      version: kSchemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => runMigrations(db, kMigrations, 0, version),
      onUpgrade: (db, oldV, newV) => runMigrations(db, kMigrations, oldV, newV),
    );
    return _db!;
  }

  /// Cards due for review at [now], highest-priority state first.
  Future<List<ScheduledCard>> dueCards({DateTime? now, int limit = 20}) async {
    final db = await _open();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query('srs_cards',
        where: 'due <= ?', whereArgs: [t], orderBy: 'due ASC', limit: limit);
    return rows.map(_fromRow).toList();
  }

  /// Due cards paired with the display fields the review UI needs.
  Future<List<({ScheduledCard card, String word, Tri meaning})>> dueForReview(
      {DateTime? now, int limit = 30}) async {
    final db = await _open();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query('srs_cards',
        where: 'due <= ?', whereArgs: [t], orderBy: 'due ASC', limit: limit);
    return rows
        .map((r) => (
              card: _fromRow(r),
              word: r['word'] as String,
              meaning: Tri(
                bn: (r['meaning_bn'] as String?) ?? '',
                en: (r['meaning_en'] as String?) ?? '',
                ja: r['word'] as String,
              ),
            ))
        .toList();
  }

  /// Seeds a new content card (idempotent) so a just-learned item can be
  /// scheduled. Safe to call repeatedly; ConflictAlgorithm.replace upserts.
  Future<void> seedCard({
    required String id,
    required String word,
    required String reading,
    required String meaningBn,
    required String meaningEn,
    String jlptLevel = 'N5',
  }) =>
      upsert(ScheduledCard(id: id, state: CardState.newCard),
          word: word,
          reading: reading,
          meaningBn: meaningBn,
          meaningEn: meaningEn,
          jlptLevel: jlptLevel);

  Future<void> upsert(ScheduledCard c,
      {required String word,
      required String reading,
      required String meaningBn,
      required String meaningEn,
      String jlptLevel = 'N5'}) async {
    final db = await _open();
    await db.insert(
      'srs_cards',
      {
        'id': c.id,
        'word': word,
        'reading': reading,
        'meaning_bn': meaningBn,
        'meaning_en': meaningEn,
        'jlpt_level': jlptLevel,
        'due': c.due.millisecondsSinceEpoch,
        'stability': c.stability,
        'difficulty': c.difficulty,
        'reps': c.reps,
        'lapses': c.lapses,
        'state': c.state.name,
        'last_review': c.lastReview?.millisecondsSinceEpoch,
        'elapsed_days': c.elapsedDays,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Applies a review with FSRS, persists the new schedule, and logs history.
  Future<ScheduledCard> applyReview(
      Fsrs fsrs, ScheduledCard card, Rating rating,
      {DateTime? now}) async {
    final updated = fsrs.review(card, rating, now: now);
    final db = await _open();
    await db.update(
      'srs_cards',
      {
        'due': updated.due.millisecondsSinceEpoch,
        'stability': updated.stability,
        'difficulty': updated.difficulty,
        'reps': updated.reps,
        'lapses': updated.lapses,
        'state': updated.state.name,
        'last_review': updated.lastReview?.millisecondsSinceEpoch,
        'elapsed_days': updated.elapsedDays,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
    await db.insert('review_history', {
      'card_id': card.id,
      'reviewed_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
      'rating': rating.g,
      'old_stability': card.stability,
      'new_stability': updated.stability,
      'old_difficulty': card.difficulty,
      'new_difficulty': updated.difficulty,
    });
    return updated;
  }

  // --- agents, dashboard, autonomy (m002) -----------------------------------

  /// Logs a finished lesson (Feedback agent's mastery counter — fixed-XP
  /// schedule is derived from this count, never stored).
  Future<void> recordLessonCompletion({
    required String lessonId,
    required int items,
    required int correct,
    int hints = 0,
    int skips = 0,
    DateTime? now,
  }) async {
    final db = await _open();
    await db.insert('lesson_completions', {
      'lesson_id': lessonId,
      'completed_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
      'items': items,
      'correct': correct,
      'hints': hints,
      'skips': skips,
    });
  }

  Future<int> lessonCompletionCount() async {
    final db = await _open();
    final r = await db.rawQuery('SELECT COUNT(*) c FROM lesson_completions');
    return (r.first['c'] as int?) ?? 0;
  }

  /// Words whose memory is considered retained (FSRS stability ≥
  /// [minStability] days). Drives levels and the exam-readiness marker.
  Future<int> retainedWordCount({double minStability = 7.0}) async {
    final db = await _open();
    final r = await db.rawQuery(
        'SELECT COUNT(*) c FROM srs_cards WHERE stability >= ?',
        [minStability]);
    return (r.first['c'] as int?) ?? 0;
  }

  /// The Director's SRS context: recent recall success, days away, due load.
  Future<({double retention, int daysSinceLastSession, int dueLoad})>
      srsContext({DateTime? now, int window = 20}) async {
    final db = await _open();
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final recent = await db.query('review_history',
        columns: ['rating', 'reviewed_at'],
        orderBy: 'reviewed_at DESC',
        limit: window);
    double retention = 1.0;
    var daysSince = 0;
    if (recent.isNotEmpty) {
      final ok = recent.where((r) => (r['rating'] as int) > 1).length;
      retention = ok / recent.length;
      final lastAt = recent.first['reviewed_at'] as int;
      daysSince = Duration(milliseconds: t - lastAt).inDays;
    }
    final due = await db
        .rawQuery('SELECT COUNT(*) c FROM srs_cards WHERE due <= ?', [t]);
    return (
      retention: retention,
      daysSinceLastSession: daysSince,
      dueLoad: (due.first['c'] as int?) ?? 0,
    );
  }

  /// Newest-first FSRS ratings from the recent history window (progress
  /// dashboard's retention input).
  Future<List<int>> recentRatings({int limit = 20}) async {
    final db = await _open();
    final rows = await db.query('review_history',
        columns: ['rating'], orderBy: 'reviewed_at DESC', limit: limit);
    return rows.map((r) => r['rating'] as int).toList();
  }

  /// Every card with its display fields — the progress dashboard's raw input.
  Future<List<({ScheduledCard card, String word, String meaningBn})>>
      allCards() async {
    final db = await _open();
    final rows = await db.query('srs_cards', orderBy: 'due ASC');
    return rows
        .map((r) => (
              card: _fromRow(r),
              word: r['word'] as String,
              meaningBn: (r['meaning_bn'] as String?) ?? '',
            ))
        .toList();
  }

  /// Distinct local days on which at least one review happened, newest first.
  /// Shown as NEUTRAL history — never as a streak to protect (D-001).
  Future<List<DateTime>> activityDays({int limit = 60}) async {
    final db = await _open();
    final rows = await db.query('review_history',
        columns: ['reviewed_at'], orderBy: 'reviewed_at DESC', limit: 2000);
    final days = <DateTime>{};
    for (final r in rows) {
      final d = DateTime.fromMillisecondsSinceEpoch(r['reviewed_at'] as int);
      days.add(DateTime(d.year, d.month, d.day));
      if (days.length >= limit) break;
    }
    return days.toList()..sort((a, b) => b.compareTo(a));
  }

  // --- app_meta KV + deletion grace (01 §Data autonomy) ---------------------

  static const _deletionKey = 'deletion_requested_at';

  Future<void> setMeta(String key, String value) async {
    final db = await _open();
    await db.insert('app_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMeta(String key) async {
    final db = await _open();
    final r =
        await db.query('app_meta', where: 'key = ?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  Future<void> deleteMeta(String key) async {
    final db = await _open();
    await db.delete('app_meta', where: 'key = ?', whereArgs: [key]);
  }

  /// Starts the 7-day deletion grace period. Reversible until it elapses.
  Future<void> requestDeletion({DateTime? now}) => setMeta(_deletionKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch.toString());

  Future<DateTime?> deletionRequestedAt() async {
    final v = await getMeta(_deletionKey);
    final ms = v == null ? null : int.tryParse(v);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> cancelDeletion() => deleteMeta(_deletionKey);

  /// Irreversibly removes ALL learner data by deleting the encrypted DB file.
  /// Called after the grace period elapses (or immediately if the user chose
  /// "delete now" and confirmed).
  Future<void> purgeAllData() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'sensei.db');
    await _db?.close();
    _db = null;
    await deleteDatabase(path);
  }

  /// Everything the learner owns, as JSON-ready maps (one-tap export — 01).
  Future<Map<String, Object?>> exportAll() async {
    final db = await _open();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'format_version': 1,
      'srs_cards': await db.query('srs_cards'),
      'review_history':
          await db.query('review_history', orderBy: 'reviewed_at ASC'),
      'lesson_completions':
          await db.query('lesson_completions', orderBy: 'completed_at ASC'),
      'app_meta': await db.query('app_meta'),
    };
  }

  ScheduledCard _fromRow(Map<String, Object?> r) => ScheduledCard(
        id: r['id'] as String,
        stability: (r['stability'] as num).toDouble(),
        difficulty: (r['difficulty'] as num).toDouble(),
        state: CardState.values.firstWhere((s) => s.name == r['state'],
            orElse: () => CardState.newCard),
        reps: r['reps'] as int,
        lapses: r['lapses'] as int,
        lastReview: r['last_review'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['last_review'] as int),
        due: DateTime.fromMillisecondsSinceEpoch(r['due'] as int),
        elapsedDays: (r['elapsed_days'] as num).toDouble(),
      );
}
