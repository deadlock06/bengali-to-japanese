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
